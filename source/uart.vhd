--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- UART FOR FPGA REQUIRES: 1 START BIT, 8 DATA BITS, 1 STOP BIT!!!
-- OTHER PARAMETERS CAN BE SET USING GENERICS.

entity UART is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD    : out std_logic; -- serial transmit data
        UART_RXD    : in  std_logic; -- serial receive data
        -- USER DATA INPUT INTERFACE
        DATA_IN     : in  std_logic_vector(7 downto 0); -- input data
        DATA_SEND   : in  std_logic; -- when DATA_SEND = 1, input data are valid and will be transmit
        BUSY        : out std_logic; -- when BUSY = 1, transmitter is busy and you must not set DATA_SEND to 1
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    : out std_logic_vector(7 downto 0); -- output data
        DATA_VLD    : out std_logic; -- when DATA_VLD = 1, output data are valid
        FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid
    );
end UART;

architecture FULL of UART is

    constant DIVIDER_VALUE    : integer := CLK_FREQ/(16*BAUD_RATE);
    constant CLK_CNT_WIDTH    : integer := integer(ceil(log2(real(DIVIDER_VALUE))));
    constant CLK_CNT_MAX      : unsigned := to_unsigned(DIVIDER_VALUE-1, CLK_CNT_WIDTH);

    signal uart_clk_cnt       : unsigned(CLK_CNT_WIDTH-1 downto 0);
    signal uart_clk_en        : std_logic;
    signal uart_rxd_shreg     : std_logic_vector(3 downto 0);
    signal uart_rxd_debounced : std_logic;

begin

    -- -------------------------------------------------------------------------
    -- UART CLOCK COUNTER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------

    uart_clk_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_clk_cnt <= (others => '0');
            else
                if (uart_clk_cnt = CLK_CNT_MAX) then
                    uart_clk_cnt <= (others => '0');
                else
                    uart_clk_cnt <= uart_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    uart_clk_en_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_clk_en <= '0';
            elsif (uart_clk_cnt = CLK_CNT_MAX) then
                uart_clk_en <= '1';
            else
                uart_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RXD SHIFT REGISTER AND DEBAUNCER
    -- -------------------------------------------------------------------------

    use_debouncer_g : if (USE_DEBOUNCER = True) generate
        uart_rxd_shreg_p : process (CLK)
        begin
            if (rising_edge(CLK)) then
                if (RST = '1') then
                    uart_rxd_shreg <= (others => '1');
                else
                    uart_rxd_shreg <= UART_RXD & uart_rxd_shreg(3 downto 1);
                end if;
            end if;
        end process;

        uart_rxd_debounced_reg_p : process (CLK)
        begin
            if (rising_edge(CLK)) then
                if (RST = '1') then
                    uart_rxd_debounced <= '1';
                else
                    uart_rxd_debounced <= uart_rxd_shreg(0) OR
                                          uart_rxd_shreg(1) OR
                                          uart_rxd_shreg(2) OR
                                          uart_rxd_shreg(3);
                end if;
            end if;
        end process;
    end generate;

    not_use_debouncer_g : if (USE_DEBOUNCER = False) generate
        uart_rxd_debounced <= UART_RXD;
    end generate;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER
    -- -------------------------------------------------------------------------

    uart_tx_i: entity work.UART_TX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_CLK_EN => uart_clk_en,
        UART_TXD    => UART_TXD,
        -- USER DATA INPUT INTERFACE
        DATA_IN     => DATA_IN,
        DATA_SEND   => DATA_SEND,
        BUSY        => BUSY
    );

    -- -------------------------------------------------------------------------
    -- UART RECEIVER
    -- -------------------------------------------------------------------------

    uart_rx_i: entity work.UART_RX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_CLK_EN => uart_clk_en,
        UART_RXD    => uart_rxd_debounced,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    => DATA_OUT,
        DATA_VLD    => DATA_VLD,
        FRAME_ERROR => FRAME_ERROR
    );

end FULL;
