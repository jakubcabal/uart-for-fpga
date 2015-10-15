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
 
entity UART_LOOPBACK is
    Generic (
        BAUD_RATE  : integer := 115200;
        DATA_BITS  : integer := 8;
        CLK_FREQ   : integer := 50e6;
        INPUT_FIFO : boolean := True;
        FIFO_DEPTH : integer := 256
    );
    Port (
        CLK        : in  std_logic; -- system clock
        RST_N      : in  std_logic; -- low active synchronous reset
        -- UART INTERFACE
        TX_UART    : out std_logic;
        RX_UART    : in  std_logic;
        -- DEBUG INTERFACE
        BUSY       : out std_logic;
        FRAME_ERR  : out std_logic;
        DATA_VLD   : out std_logic
    );
end UART_LOOPBACK;

architecture FULL of UART_LOOPBACK is

    signal data        : std_logic_vector(DATA_BITS-1 downto 0);
    signal valid       : std_logic;
    signal reset       : std_logic;
    signal frame_error : std_logic;
    signal send        : std_logic;

begin

	reset <= not RST_N;
	send <= valid WHEN (frame_error = '0') ELSE '0';
 
	uart_i: entity work.UART
    generic map (
        BAUD_RATE   => BAUD_RATE,
        DATA_BITS   => DATA_BITS,
        CLK_FREQ    => CLK_FREQ,
        INPUT_FIFO  => INPUT_FIFO,
        FIFO_DEPTH  => FIFO_DEPTH
    )
    port map (
        CLK         => CLK,
        RST         => reset,
        -- UART INTERFACE
        TX_UART     => TX_UART,
        RX_UART     => RX_UART,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    => data,
        DATA_VLD    => valid,
        FRAME_ERROR => frame_error,
        -- USER DATA INPUT INTERFACE
        DATA_IN     => data,
        DATA_SEND   => send,
        BUSY        => BUSY
    );

    frame_err_gen : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (reset = '1') then
                FRAME_ERR <= '0';
            elsif (valid = '1') then
            	FRAME_ERR <= frame_error;
            end if;
        end if;
    end process;

    DATA_VLD <= valid;

end FULL;