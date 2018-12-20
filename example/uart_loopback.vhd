--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART LOOPBACK EXAMPLE TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- UART FOR FPGA REQUIRES: 1 START BIT, 8 DATA BITS, 1 STOP BIT!!!
-- OTHER PARAMETERS CAN BE SET USING GENERICS.

entity UART_LOOPBACK is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- set system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- legal values: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        CLK      : in  std_logic; -- system clock
        RST      : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD : out std_logic;
        UART_RXD : in  std_logic
    );
end UART_LOOPBACK;

architecture FULL of UART_LOOPBACK is

    signal data  : std_logic_vector(7 downto 0);
    signal valid : std_logic;

begin

	uart_i: entity work.UART
    generic map (
        CLK_FREQ      => CLK_FREQ,
        BAUD_RATE     => BAUD_RATE,
        PARITY_BIT    => PARITY_BIT,
        USE_DEBOUNCER => USE_DEBOUNCER
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_TXD    => UART_TXD,
        UART_RXD    => UART_RXD,
        -- USER DATA OUTPUT INTERFACE
        DOUT        => data,
        DOUT_VLD    => valid,
        FRAME_ERROR => open,
        -- USER DATA INPUT INTERFACE
        DIN         => data,
        DIN_VLD     => valid,
        DIN_RDY     => open
    );

end FULL;
