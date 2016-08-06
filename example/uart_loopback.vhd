--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART LOOPBACK EXAMPLE TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- UART FOR FPGA REQUIRES: 1 START BIT, 8 DATA BITS, 1 STOP BIT!!!
-- OTHER PARAMETERS CAN BE SET USING GENERICS.

entity UART_LOOPBACK is
    Generic (
        CLK_FREQ   : integer := 50e6;   -- set system clock frequency in Hz
        BAUD_RATE  : integer := 115200; -- baud rate value
        PARITY_BIT : string  := "none"  -- legal values: "none", "even", "odd", "mark", "space"
    );
    Port (
        CLK        : in  std_logic; -- system clock
        RST_N      : in  std_logic; -- low active synchronous reset
        -- UART INTERFACE
        UART_TXD   : out std_logic;
        UART_RXD   : in  std_logic;
        -- DEBUG INTERFACE
        BUSY       : out std_logic;
        FRAME_ERR  : out std_logic
    );
end UART_LOOPBACK;

architecture FULL of UART_LOOPBACK is

    signal data    : std_logic_vector(7 downto 0);
    signal valid   : std_logic;
    signal reset   : std_logic;

begin

	reset <= not RST_N;

	uart_i: entity work.UART
    generic map (
        CLK_FREQ    => CLK_FREQ,
        BAUD_RATE   => BAUD_RATE,
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => reset,
        -- UART INTERFACE
        UART_TXD    => UART_TXD,
        UART_RXD    => UART_RXD,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    => data,
        DATA_VLD    => valid,
        FRAME_ERROR => FRAME_ERR,
        -- USER DATA INPUT INTERFACE
        DATA_IN     => data,
        DATA_SEND   => valid,
        BUSY        => BUSY
    );

end FULL;
