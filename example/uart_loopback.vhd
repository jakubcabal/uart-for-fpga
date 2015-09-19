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
        BAUD_RATE  : integer := 9600;
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
        RX_UART    : in  std_logic
    );
end UART_LOOPBACK;

architecture FULL of UART_LOOPBACK is

    -- signals
    signal data  : std_logic_vector(DATA_BITS-1 downto 0);
    signal valid : std_logic;
    signal reset : std_logic;

begin

	reset <= not RST_N;
 
	uart_i: entity work.UART
    generic map (
        BAUD_RATE  => BAUD_RATE,  -- baud rate value, default is 9600
        DATA_BITS  => DATA_BITS,  -- legal values: 5,6,7,8, default is 8 dat bits
        CLK_FREQ   => CLK_FREQ,   -- set system clock frequency in Hz, default is 50 MHz
        INPUT_FIFO => INPUT_FIFO, -- enable input data FIFO, default is disable
        FIFO_DEPTH => FIFO_DEPTH  -- set depth of input data FIFO, default is 256 items
    )
    port map (
        CLK       => CLK,   -- system clock
        RST       => reset, -- high active synchronous reset
        -- UART INTERFACE
        TX_UART   => TX_UART,
        RX_UART   => RX_UART,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT  => data,
        DATA_VLD  => valid, -- when DATA_VLD = 1, data on DATA_OUT are valid
        -- USER DATA INPUT INTERFACE
        DATA_IN   => data,
        DATA_SEND => valid, -- when DATA_SEND = 1, data on DATA_IN will be transmit
        BUSY      => open   -- when BUSY = 1, you must not set DATA_SEND to 1
    );

end FULL;