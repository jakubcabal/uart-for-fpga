-- The MIT License (MIT)
--
-- Copyright (c) 2015 Jakub Cabal
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
-- Website: https://github.com/jakubcabal/uart_for_fpga    
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART is
    Generic (
        BAUD_RATE   : integer := 115200; -- baud rate value
        DATA_BITS   : integer := 8;      -- legal values: 5,6,7,8
        PARITY_BIT  : string  := "none"; -- legal values: "none", "even", "odd", "mark", "space"
        --STOP_BITS   : integer;         -- TODO, now must be 1 stop bit
        CLK_FREQ    : integer := 50e6;   -- set system clock frequency in Hz
        INPUT_FIFO  : boolean := False;  -- enable input data FIFO
        FIFO_DEPTH  : integer := 256     -- set depth of input data FIFO
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- UART RS232 INTERFACE
        TX_UART     : out std_logic;
        RX_UART     : in  std_logic;
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    : out std_logic_vector(DATA_BITS-1 downto 0);
        DATA_VLD    : out std_logic; -- when DATA_VLD = 1, data on DATA_OUT are valid
        FRAME_ERROR : out std_logic; -- when FRAME_ERROR = 1, stop bit was invalid, current and next data may be invalid
        -- USER DATA INPUT INTERFACE
        DATA_IN     : in  std_logic_vector(DATA_BITS-1 downto 0);
        DATA_SEND   : in  std_logic; -- when DATA_SEND = 1, data on DATA_IN will be transmit, DATA_SEND can set to 1 only when BUSY = 0
        BUSY        : out std_logic  -- when BUSY = 1 transiever is busy, you must not set DATA_SEND to 1
    );
end UART;

architecture FULL of UART is

    constant divider_value      : integer := CLK_FREQ/(16*BAUD_RATE);

    signal tx_clk_en            : std_logic;
    signal tx_ticks             : integer range 0 to 15;
    signal tx_data              : std_logic_vector(DATA_BITS-1 downto 0);
    signal tx_bit_count         : integer range 0 to DATA_BITS-1;
    signal tx_bit_count_en      : std_logic;
    signal tx_bit_count_rst     : std_logic;
    signal tx_busy              : std_logic;
    signal tx_data_in           : std_logic_vector(DATA_BITS-1 downto 0);
    signal tx_data_send         : std_logic;
    signal tx_parity_bit        : std_logic;

    signal uart_ticks           : integer range 0 to divider_value-1;
    signal uart_clk_en          : std_logic;

    signal fifo_in_rd           : std_logic;
    signal fifo_in_empty        : std_logic;

    signal rx_clk_en            : std_logic;
    signal rx_ticks             : integer range 0 to 15;
    signal rx_clk_divider_en    : std_logic;
    signal rx_data              : std_logic_vector(DATA_BITS-1 downto 0);
    signal rx_bit_count         : integer range 0 to DATA_BITS-1;
    signal rx_bit_count_en      : std_logic;
    signal rx_bit_count_rst     : std_logic;
    signal rx_data_shreg_en     : std_logic;
    signal rx_parity_bit        : std_logic;
    signal rx_parity_error      : std_logic := '0';
    signal rx_parity_check_en   : std_logic;

    type state is (idle, txsync, startbit, databits, paritybit, stopbit);
    signal tx_pstate : state;
    signal tx_nstate : state;
    signal rx_pstate : state;
    signal rx_nstate : state;

begin

    -- -------------------------------------------------------------------------
    --                        UART INPUT DATA FIFO
    -- -------------------------------------------------------------------------

    data_in_fifo_g : if (INPUT_FIFO = True) generate

        data_in_fifo_i: entity work.UART_FIFO
        generic map (
            DATA_WIDTH => DATA_BITS,
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            CLK       => CLK,
            RST       => RST,
            -- FIFO WRITE INTERFACE
            DATA_IN   => DATA_IN,
            WR_EN     => DATA_SEND,
            FULL      => BUSY,
            -- FIFO READ INTERFACE
            DATA_OUT  => tx_data_in,
            DATA_VLD  => tx_data_send,
            RD_EN     => fifo_in_rd,
            EMPTY     => fifo_in_empty
        );

        fifo_in_rd <= fifo_in_empty NOR tx_busy;

    end generate;

    no_data_in_fifo_g : if (INPUT_FIFO = False) generate

        tx_data_in <= DATA_IN;
        tx_data_send <= DATA_SEND;
        BUSY <= tx_busy;

    end generate;

    -- -------------------------------------------------------------------------
    --                        UART CLOCK DIVIDER
    -- -------------------------------------------------------------------------

    uart_clk_divider : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_ticks <= 0;
                uart_clk_en <= '0';
            elsif (uart_ticks = divider_value-1) then
                uart_ticks <= 0;
                uart_clk_en <= '1';
            else
                uart_ticks <= uart_ticks + 1;
                uart_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART TRANSMITTER CLOCK DIVIDER
    -- -------------------------------------------------------------------------

    tx_clk_divider : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_ticks <= 0;
                tx_clk_en <= '0';
            elsif (uart_clk_en = '1') then
                if (tx_ticks = 15) then
                    tx_ticks <= 0;
                    tx_clk_en <= '1';
                else
                    tx_ticks <= tx_ticks + 1;
                    tx_clk_en <= '0';
                end if;
            else
                tx_ticks <= tx_ticks;
                tx_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART TRANSMITTER INPUT DATA REGISTER
    -- -------------------------------------------------------------------------

    input_reg : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_data <= (others => '0');
            elsif (tx_data_send = '1' AND tx_busy = '0') then
                tx_data <= tx_data_in;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART TRANSMITTER BIT COUNTER
    -- -------------------------------------------------------------------------

    tx_bit_counter : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (tx_bit_count_rst = '1') then
                tx_bit_count <= 0;
            elsif (tx_bit_count_en = '1' AND tx_clk_en = '1') then
                if (tx_bit_count = DATA_BITS-1) then
                    tx_bit_count <= 0;
                else
                    tx_bit_count <= tx_bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART TRANSMITTER PARITY GENERATOR
    -- -------------------------------------------------------------------------

    tx_parity_g : if (PARITY_BIT /= "none") generate

        tx_parity_gen_i: entity work.UART_PARITY
        generic map (
            DATA_WIDTH  => DATA_BITS,
            PARITY_TYPE => PARITY_BIT
        )
        port map (
            DATA_IN     => tx_data,
            PARITY_OUT  => tx_parity_bit
        );

    end generate;

    -- -------------------------------------------------------------------------
    --                        UART TRANSMITTER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    tx_pstate_reg : process (CLK) 
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_pstate <= idle;
            else
                tx_pstate <= tx_nstate;
            end if;
        end if;   
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (tx_pstate, tx_data_send, tx_clk_en, tx_data, tx_bit_count, tx_parity_bit)
    begin

        case tx_pstate is
     
            when idle =>
                tx_busy <= '0';
                TX_UART <= '1';
                tx_bit_count_rst <= '1';
                tx_bit_count_en <= '0';

                if (tx_data_send = '1') then
                    tx_nstate <= txsync;
                else
                    tx_nstate <= idle;
                end if;

            when txsync =>
                tx_busy <= '1';
                TX_UART <= '1';
                tx_bit_count_rst <= '1';
                tx_bit_count_en <= '0';

                if (tx_clk_en = '1') then
                    tx_nstate <= startbit;
                else
                    tx_nstate <= txsync;
                end if;

            when startbit =>
                tx_busy <= '1';
                TX_UART <= '0';
                tx_bit_count_rst <= '0';
                tx_bit_count_en <= '0';

                if (tx_clk_en = '1') then
                    tx_nstate <= databits;
                else
                    tx_nstate <= startbit;
                end if;

            when databits =>
                tx_busy <= '1';
                TX_UART <= tx_data(tx_bit_count);
                tx_bit_count_rst <= '0';
                tx_bit_count_en <= '1';

                if ((tx_clk_en = '1') AND (tx_bit_count = DATA_BITS-1)) then
                    if (PARITY_BIT = "none") then
                        tx_nstate <= idle;
                    else
                        tx_nstate <= paritybit;
                    end if ;
                else
                    tx_nstate <= databits;
                end if;

            when paritybit =>
                tx_busy <= '1';
                TX_UART <= tx_parity_bit;
                tx_bit_count_rst <= '1';
                tx_bit_count_en <= '0';

                if (tx_clk_en = '1') then
                    tx_nstate <= idle;
                else
                    tx_nstate <= paritybit;
                end if;

            when others => 
                tx_busy <= '1';
                TX_UART <= '1';
                tx_bit_count_rst <= '1';
                tx_bit_count_en <= '0';
                tx_nstate <= idle;
         
        end case;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART RECEIVER CLOCK DIVIDER
    -- -------------------------------------------------------------------------

    rx_clk_divider : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_clk_divider_en = '1') then
                if (uart_clk_en = '1') then
                    if (rx_ticks = 15) then
                        rx_ticks <= 0;
                        rx_clk_en <= '0';
                    elsif (rx_ticks = 7) then
                        rx_ticks <= rx_ticks + 1;
                        rx_clk_en <= '1';
                    else
                        rx_ticks <= rx_ticks + 1;
                        rx_clk_en <= '0';
                    end if;
                else
                    rx_ticks <= rx_ticks;
                    rx_clk_en <= '0';
                end if;
            else
                rx_ticks <= 0;
                rx_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART RECEIVER BIT COUNTER
    -- -------------------------------------------------------------------------

    rx_bit_counter : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_bit_count_rst = '1') then
                rx_bit_count <= 0;
            elsif (rx_bit_count_en = '1' AND rx_clk_en = '1') then
                if (rx_bit_count = DATA_BITS-1) then
                    rx_bit_count <= 0;
                else
                    rx_bit_count <= rx_bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        UART RECEIVER DATA SHIFT REGISTER
    -- -------------------------------------------------------------------------

    rx_data_shift_reg : process (CLK) 
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_data <= (others => '0');
            elsif (rx_clk_en = '1' AND rx_data_shreg_en = '1') then
                rx_data <= RX_UART & rx_data(7 downto 1);
            end if;
        end if;
    end process;

    DATA_OUT <= rx_data;

    -- -------------------------------------------------------------------------
    --                        UART RECEIVER PARITY GENERATOR AND CHECK
    -- -------------------------------------------------------------------------

    rx_parity_g : if (PARITY_BIT /= "none") generate

        rx_parity_gen_i: entity work.UART_PARITY
        generic map (
            DATA_WIDTH  => DATA_BITS,
            PARITY_TYPE => PARITY_BIT
        )
        port map (
            DATA_IN     => rx_data,
            PARITY_OUT  => rx_parity_bit
        );

        rx_parity_check_reg : process (CLK) 
        begin
            if (rising_edge(CLK)) then
                if (RST = '1') then
                    rx_parity_error <= '0';
                elsif (rx_parity_check_en = '1') then
                    rx_parity_error <= rx_parity_bit XOR RX_UART;
                end if;
            end if;
        end process;

    end generate;

    -- -------------------------------------------------------------------------
    --                        UART RECEIVER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    process (CLK) 
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_pstate <= idle;
            else
                rx_pstate <= rx_nstate;
            end if;
        end if;   
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (rx_pstate, RX_UART, rx_clk_en, rx_bit_count, rx_parity_error)
    begin
        case rx_pstate is
     
            when idle =>
                DATA_VLD <= '0';
                FRAME_ERROR <= '0';
                rx_bit_count_rst <= '1';
                rx_bit_count_en <= '0';
                rx_data_shreg_en <= '0';
                rx_clk_divider_en <= '0';
                rx_parity_check_en <= '0';

                if (RX_UART = '0') then
                    rx_nstate <= startbit;
                else
                    rx_nstate <= idle;              
                end if;

            when startbit =>
                DATA_VLD <= '0';
                FRAME_ERROR <= '0';
                rx_bit_count_rst <= '0';
                rx_bit_count_en <= '0';
                rx_data_shreg_en <= '0';
                rx_clk_divider_en <= '1';
                rx_parity_check_en <= '0';

                if (rx_clk_en = '1') then
                    rx_nstate <= databits;
                else
                    rx_nstate <= startbit;
                end if;

            when databits =>
                DATA_VLD <= '0';
                FRAME_ERROR <= '0';
                rx_bit_count_rst <= '0';
                rx_bit_count_en <= '1';
                rx_data_shreg_en <= '1';
                rx_clk_divider_en <= '1';
                rx_parity_check_en <= '0';

                if ((rx_clk_en = '1') AND (rx_bit_count = DATA_BITS-1)) then
                    if (PARITY_BIT = "none") then
                        rx_nstate <= stopbit;
                    else
                        rx_nstate <= paritybit;
                    end if ;
                else
                    rx_nstate <= databits;
                end if;

            when paritybit =>
                DATA_VLD <= '0';
                FRAME_ERROR <= '0';
                rx_bit_count_rst <= '1';
                rx_bit_count_en <= '0';
                rx_data_shreg_en <= '0';
                rx_clk_divider_en <= '1';

                if (rx_clk_en = '1') then
                    rx_nstate <= stopbit;
                    rx_parity_check_en <= '1';
                else
                    rx_nstate <= paritybit;
                    rx_parity_check_en <= '0';
                end if;

            when stopbit =>
                rx_bit_count_rst <= '1';
                rx_bit_count_en <= '0';
                rx_data_shreg_en <= '0';
                rx_clk_divider_en <= '1';
                rx_parity_check_en <= '0';

                if (rx_clk_en = '1') then
                    rx_nstate <= idle;
                    DATA_VLD <= NOT rx_parity_error;
                    FRAME_ERROR <= NOT RX_UART;
                else
                    rx_nstate <= stopbit;
                    DATA_VLD <= '0';
                    FRAME_ERROR <= '0';
                end if;

            when others =>
                DATA_VLD <= '0';
                FRAME_ERROR <= '0';
                rx_bit_count_rst <= '1';
                rx_bit_count_en <= '0';
                rx_data_shreg_en <= '0';
                rx_clk_divider_en <= '0';
                rx_parity_check_en <= '0';
                rx_nstate <= idle;
         
        end case;
    end process;

end FULL;