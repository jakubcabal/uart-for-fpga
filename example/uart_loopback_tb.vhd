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
 
entity UART_LOOPBACK_TB is
end UART_LOOPBACK_TB;
 
architecture FULL of UART_LOOPBACK_TB is 

	signal CLK         : std_logic := '0';
	signal RST_N       : std_logic := '0';
	signal tx_uart     : std_logic;
	signal rx_uart     : std_logic := '1';
	signal data_vld    : std_logic;
	signal frame_error : std_logic;
	signal busy        : std_logic;

   	constant clk_period  : time := 20 ns;
	constant uart_period : time := 8696 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
	constant data_value2 : std_logic_vector(7 downto 0) := "00110110";
 
begin
 
	utt: entity work.UART_LOOPBACK
    generic map (
        BAUD_RATE   => 115200,
        DATA_BITS   => 8,
        PARITY_BIT  => "none",
        CLK_FREQ    => 50e6,
        INPUT_FIFO  => True,
        FIFO_DEPTH  => 256
    )
    port map (
        CLK         => CLK,
        RST_N       => RST_N,
        -- UART RS232 INTERFACE
        TX_UART     => tx_uart,
        RX_UART     => rx_uart,
        -- DEBUG INTERFACE
        BUSY        => busy,
        FRAME_ERR   => frame_error,
        DATA_VLD    => data_vld
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
		RST_N <= '0';
		wait for 100 ns;
      	RST_N <= '1';

		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to 7 loop
			rx_uart <= data_value(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to 7 loop
			rx_uart <= data_value2(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to 7 loop
			rx_uart <= data_value(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to 7 loop
			rx_uart <= data_value2(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		wait;

	end process;

end FULL;