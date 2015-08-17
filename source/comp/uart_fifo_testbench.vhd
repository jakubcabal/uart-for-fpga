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
 
entity UART_FIFO_TESTBENCH is
end UART_FIFO_TESTBENCH;
 
architecture FULL of UART_FIFO_TESTBENCH is 

	signal CLK       : std_logic := '0';
	signal RST       : std_logic := '0';
	signal data_in   : std_logic_vector(7 downto 0);
	signal wr_en     : std_logic;
	signal data_out  : std_logic_vector(7 downto 0);
	signal data_vld  : std_logic;
	signal rd_en     : std_logic;	
	signal full      : std_logic;
	signal empty     : std_logic;

   	constant clk_period  : time := 20 ns;
 
begin
 
	utt: entity work.UART_FIFO
    generic map (
        DATA_WIDTH => 8,
        FIFO_DEPTH => 32
    )
    port map (
        CLK       => CLK,
        RST       => RST,
        -- FIFO WRITE INTERFACE
        DATA_IN   => data_in,
        WR_EN     => wr_en,
        FULL      => full,
        -- FIFO READ INTERFACE
        DATA_OUT  => data_out,
        DATA_VLD  => data_vld,
        RD_EN     => rd_en,
        EMPTY     => empty
    );

	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;

	rst_process : process
	begin
		RST <= '1';
		wait for 40 ns;
		RST <= '0';
		wait;
	end process;

	read_test : process
   	begin
      	rd_en <= '0';

      	wait until (rising_edge(CLK) and RST='0' and empty='0');
      	for i in 1 to 20 loop
         	rd_en <= '1';
         	wait until (rising_edge(CLK) and RST='0' and empty='0');
      	end loop;
      	rd_en <= '0';

      	wait for 800 ns;

      	wait until (rising_edge(CLK) and RST='0' and empty='0');
      	for i in 21 to 70 loop
         	rd_en <= '1';
         	wait until (rising_edge(CLK) and RST='0' and empty='0');
      	end loop;
      	rd_en <= '0';

      	wait;
   	end process;

	write_test : process
	begin
      	data_in <= (others => '0');
      	wr_en <= '0';

      	wait until (rising_edge(CLK) and RST='0' and full='0');
      	wr_en <= '1';
      	for i in 1 to 11 loop
         	data_in <= std_logic_vector(to_unsigned(i, data_in'length));
         	wait until (rising_edge(CLK) and RST='0' and full='0');
      	end loop;
      	wr_en <= '0';

      	wait for 200 ns;

      	wait until (rising_edge(CLK) and RST='0' and full='0');
      	wr_en <= '1';
      	for i in 12 to 70 loop
         	data_in <= std_logic_vector(to_unsigned(i, data_in'length));
         	wait until (rising_edge(CLK) and RST='0' and full='0');
      	end loop;
      	wr_en <= '0';

      	wait;
   	end process;

end FULL;