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
 
entity UART_TESTBENCH is
end UART_TESTBENCH;
 
architecture FULL of UART_TESTBENCH is 

	signal CLK      : std_logic := '0';
	signal RST      : std_logic := '0';
	signal tx_uart  : std_logic;
	signal rx_uart  : std_logic := '1';
	signal tx_valid : std_logic;
	signal tx_data  : std_logic_vector(7 downto 0);
	signal rx_valid : std_logic;
	signal rx_ready : std_logic;
	signal rx_data  : std_logic_vector(7 downto 0);

   	constant clk_period  : time := 20 ns;
	constant uart_period : time := 8696 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
 
begin
 
	utt: entity work.UART
    generic map (
        BAUD_RATE => 115200, -- baud rate value, default is 115200
        DATA_BITS => 8,      -- legal values: 5,6,7,8, default is 8 dat bits
        CLK_FREQ  => 50e6    -- set system clock frequency in Hz, default is 50 MHz
    )
    port map (
        CLK       => CLK, -- system clock
        RST       => RST, -- high active synchronous reset
        -- UART INTERFACE
        TX_UART   => tx_uart,
        RX_UART   => rx_uart,
        -- USER TX INTERFACE
        TX_DATA   => tx_data,
        TX_VALID  => tx_valid, -- when TX_VALID = 1, data on TX_DATA are valid
        -- USER RX INTERFACE
        RX_DATA   => rx_data,
        RX_VALID  => rx_valid, -- when RX_VALID = 1, data on RX_DATA are valid
        RX_READY  => rx_ready  -- when RX_READY = 1, you can set RX_VALID to 1
    );

	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;

	test_rx_uart : process
	begin
		rx_uart <= '1';
		RST <= '1';
		wait for 100 ns;
      	RST <= '0';

		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to 7 loop
			rx_uart <= data_value(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		wait;

	end process;

	test_tx_uart : process
	begin
		rx_valid <= '0';
		RST <= '1';
		wait for 100 ns;
      	RST <= '0';

		wait until rising_edge(CLK);

		rx_valid <= '1';
		rx_data <= data_value;

		wait until rising_edge(CLK);

		rx_valid <= '0';

		wait until rising_edge(CLK);

		wait;

	end process;

end FULL;