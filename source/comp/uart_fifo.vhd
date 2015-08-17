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
use IEEE.MATH_REAL.ALL;

entity UART_FIFO is
    Generic (
        DATA_WIDTH : integer := 8;
        FIFO_DEPTH : integer := 256
    );
    Port (
        CLK        : in  std_logic; -- system clock
        RST        : in  std_logic; -- high active synchronous reset
        -- FIFO WRITE INTERFACE
        DATA_IN    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        WR_EN      : in  std_logic;
        FULL       : out std_logic;
        -- FIFO READ INTERFACE
        DATA_OUT   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        DATA_VLD   : out std_logic;
        RD_EN      : in  std_logic;
        EMPTY      : out std_logic
    );
end UART_FIFO;

architecture FULL of UART_FIFO is

    constant addr_width         : integer := integer(ceil(log2(real(FIFO_DEPTH))));

	signal wr_addr              : unsigned(addr_width-1 downto 0);
	signal wr_ready             : std_logic;
    signal rd_addr              : unsigned(addr_width-1 downto 0);
    signal rd_ready             : std_logic;
    signal full_sig             : std_logic;
    signal empty_sig            : std_logic;

    type bram_type is array(FIFO_DEPTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bram : bram_type := (others => (others => '0'));

begin

	wr_ready <= WR_EN AND NOT full_sig AND NOT RST;
	rd_ready <= RD_EN AND NOT empty_sig AND NOT RST;

	FULL <= full_sig;
	EMPTY <= empty_sig;

    -- -------------------------------------------------------------------------
    --                        BRAM AND DATA VALID FLAG GENERATOR
    -- -------------------------------------------------------------------------

	bram_mem : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (wr_ready = '1') then
				bram(to_integer(wr_addr)) <= DATA_IN;
			end if;
			DATA_OUT <= bram(to_integer(rd_addr));
		end if;
	end process;

	data_vld_flag_gen : process (CLK)
	begin
		if (rising_edge(CLK)) then
			DATA_VLD <= rd_ready;
		end if;
	end process;

    -- -------------------------------------------------------------------------
    --                        FIFO WRITE ADDRESS COUNTER
    -- -------------------------------------------------------------------------

    wr_addr_cnt : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                wr_addr <= (others => '0');
            elsif (wr_ready = '1') then
                wr_addr <= wr_addr + 1;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        FIFO READ ADDRESS COUNTER
    -- -------------------------------------------------------------------------

    rd_addr_cnt : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rd_addr <= (others => '0');
            elsif (rd_ready = '1') then
                rd_addr <= rd_addr + 1;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        FULL FLAG GENERATOR
    -- -------------------------------------------------------------------------

    full_flag_gen : process (rd_addr, wr_addr)
    begin
        if (rd_addr = (wr_addr+1)) then
            full_sig <= '1';
        else
        	full_sig <= '0';
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --                        EMPTY FLAG GENERATOR
    -- -------------------------------------------------------------------------

    empty_flag_gen : process (rd_addr, wr_addr)
    begin
        if (rd_addr = wr_addr) then
            empty_sig <= '1';
        else
        	empty_sig <= '0';
        end if;
    end process;

end FULL;