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
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART is
    Generic (
        BAUD_RATE  : integer := 9600; -- baud rate value, default is 9600
        DATA_BITS  : integer := 8;    -- legal values: 5,6,7,8
        --STOP_BITS  : integer;       -- TODO, now is default 1 stop bit
        --PARITY_BIT : integer;       -- TODO, now is default none parity bit
        CLK_FREQ   : integer := 50e6  -- set system clock frequency in Hz, default is 50 MHz
    );
    Port (
        CLK        : in  std_logic; -- system clock
        RST        : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        TX_UART    : out std_logic;
        RX_UART    : in  std_logic;
        -- USER TX INTERFACE
        TX_DATA    : out std_logic_vector(DATA_BITS-1 downto 0);
        TX_VALID   : out std_logic; -- when TX_VALID = 1, data on TX_DATA are valid
        -- USER RX INTERFACE
        RX_DATA    : in  std_logic_vector(DATA_BITS-1 downto 0);
        RX_VALID   : in  std_logic  -- when RX_VALID = 1, data on RX_DATA are valid
    );
end UART;

architecture FULL of UART is

    -- constants
    constant divider_value        : integer := CLK_FREQ / BAUD_RATE;
    -- signals
    signal rx_data_reg            : std_logic_vector(DATA_BITS-1 downto 0);
    signal rx_data_reg_next       : std_logic_vector(DATA_BITS-1 downto 0);
    signal rx_data_vld            : std_logic;
    signal rx_data_vld_next       : std_logic;
    signal uart_clk_en            : std_logic;

    signal ticks                  : integer range 0 to divider_value;
    signal rx_data_bit_count      : integer range 0 to DATA_BITS-1;
    signal rx_data_bit_count_next : integer range 0 to DATA_BITS-1;

    type state is (idle, receive_data, receive_stop_bit);
    signal rx_present_st : state;
    signal rx_next_st    : state;

begin

    -- -------------------------------------------------------------------------
    --                        UART CLOCK DIVIDER
    -- -------------------------------------------------------------------------

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                uart_clk_en <= '0';
            elsif (ticks = divider_value) then
                ticks  <= 0;
                uart_clk_en <= '1';
            else
                ticks <= ticks + 1;
                uart_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        INPUT REGISTER
    -- -------------------------------------------------------------------------

    -- TODO

    -- -------------------------------------------------------------------------
    --                        OUTPUT REGISTER
    -- -------------------------------------------------------------------------

    TX_VALID <= rx_data_vld;

    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                TX_DATA <= (others => '0');
            elsif (rx_data_vld = '1') then
                TX_DATA <= rx_data_reg;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        TX UART FSM
    -- -------------------------------------------------------------------------

    -- TODO

    -- -------------------------------------------------------------------------
    --                        RX UART FSM
    -- -------------------------------------------------------------------------

    process (CLK) 
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_present_st     <= idle;
                rx_data_bit_count <= 0;
                rx_data_reg       <= (others => '0');
                rx_data_vld       <= '0';
            else
                rx_present_st     <= rx_next_st;
                rx_data_bit_count <= rx_data_bit_count_next;
                rx_data_reg       <= rx_data_reg_next;
                rx_data_vld       <= rx_data_vld_next;
            end if;
        end if;   
    end process;

    process (rx_present_st, uart_clk_en, RX_UART, rx_data_bit_count, rx_data_reg, rx_data_vld)
    begin

        rx_data_bit_count_next <= rx_data_bit_count;
        rx_data_reg_next       <= rx_data_reg;
        rx_data_vld_next       <= rx_data_vld;
        rx_next_st             <= rx_present_st;

        case rx_present_st is
     
            when idle =>
                if (uart_clk_en = '1' AND RX_UART = '0') then
                    rx_next_st <= receive_data;
                else
                    rx_next_st <= idle;
                end if;

            when receive_data =>
                if (uart_clk_en = '1') then
                    if (rx_data_bit_count = DATA_BITS-1) then
                        rx_data_bit_count_next <= 0;
                        rx_data_reg_next(DATA_BITS-1) <= RX_UART;
                        rx_data_reg_next(DATA_BITS-2 downto 0) <= rx_data_reg(DATA_BITS-1 downto 1);
                        rx_next_st <= receive_stop_bit;
                    else
                        rx_data_bit_count_next <= rx_data_bit_count + 1;
                        rx_data_reg_next(DATA_BITS-1) <= RX_UART;
                        rx_data_reg_next(DATA_BITS-2 downto 0) <= rx_data_reg(DATA_BITS-1 downto 1);
                        rx_next_st <= receive_data;
                    end if;
                end if;

            when receive_stop_bit =>
                if (uart_clk_en = '1' AND RX_UART = '1') then
                    rx_data_vld_next <= '1';
                    rx_next_st <= idle;
                else
                    rx_data_vld_next <= '0';
                    rx_next_st <= receive_stop_bit;
                end if;

            when others =>
                rx_data_bit_count_next <= 0;
                rx_data_reg_next <= (others => '0');
                rx_data_vld_next <= '0';
                rx_next_st <= idle;
         
        end case;
    end process;

end FULL;