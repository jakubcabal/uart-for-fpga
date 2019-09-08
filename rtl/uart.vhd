--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- SIMPLE UART FOR FPGA
-- ====================
-- UART FOR FPGA REQUIRES: 1 START BIT, 8 DATA BITS, 1 STOP BIT!!!
-- OTHER PARAMETERS CAN BE SET USING GENERICS.

-- DESCRIPTION OF RELEASED VERSIONS:
-- =================================
-- Version 1.0 - released on 27 May 2016
    -- Initial release.
-- Version 1.1 - released on 20 December 2018
    -- Added better debouncer.
    -- Added simulation script and Quartus project file.
    -- Removed unnecessary resets.
    -- Signal BUSY replaced by DIN_RDY.
    -- Many other optimizations and changes.
-- Version 1.2 -
    -- Added double FF for safe CDC.
    -- Fixed fake received transaction after FPGA boot without reset.

entity UART is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        -- CLOCK AND RESET
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD    : out std_logic; -- serial transmit data
        UART_RXD    : in  std_logic; -- serial receive data
        -- USER DATA INPUT INTERFACE
        DIN         : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
        DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
        DIN_RDY     : out std_logic; -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
        -- USER DATA OUTPUT INTERFACE
        DOUT        : out std_logic_vector(7 downto 0); -- output data received via UART
        DOUT_VLD    : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
        FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
    );
end entity;

architecture RTL of UART is

    constant DIVIDER_VALUE : integer  := CLK_FREQ/(16*BAUD_RATE);
    constant CLK_CNT_WIDTH : integer  := integer(ceil(log2(real(DIVIDER_VALUE))));
    constant CLK_CNT_MAX   : unsigned := to_unsigned(DIVIDER_VALUE-1, CLK_CNT_WIDTH);

    signal oversampling_clk_cnt : unsigned(CLK_CNT_WIDTH-1 downto 0);
    signal oversampling_clk_en  : std_logic;
    signal uart_rxd_meta_n      : std_logic;
    signal uart_rxd_synced_n    : std_logic;
    signal uart_rxd_debounced_n : std_logic;
    signal uart_rxd_debounced   : std_logic;

begin

    -- -------------------------------------------------------------------------
    --  UART OVERSAMPLING (16X) CLOCK COUNTER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------

    oversampling_clk_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                oversampling_clk_cnt <= (others => '0');
            else
                if (oversampling_clk_en = '1') then
                    oversampling_clk_cnt <= (others => '0');
                else
                    oversampling_clk_cnt <= oversampling_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    oversampling_clk_en <= '1' when (oversampling_clk_cnt = CLK_CNT_MAX) else '0';

    -- -------------------------------------------------------------------------
    --  UART RXD CROSS DOMAIN CROSSING
    -- -------------------------------------------------------------------------
    
    uart_rxd_cdc_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            uart_rxd_meta_n   <= not UART_RXD;
            uart_rxd_synced_n <= uart_rxd_meta_n;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    --  UART RXD DEBAUNCER
    -- -------------------------------------------------------------------------

    use_debouncer_g : if (USE_DEBOUNCER = True) generate
        debouncer_i : entity work.UART_DEBOUNCER
        generic map(
            LATENCY => 4
        )
        port map (
            CLK     => CLK,
            DEB_IN  => uart_rxd_synced_n,
            DEB_OUT => uart_rxd_debounced_n
        );
    end generate;

    not_use_debouncer_g : if (USE_DEBOUNCER = False) generate
        uart_rxd_debounced_n <= uart_rxd_synced_n;
    end generate;

    uart_rxd_debounced <= not uart_rxd_debounced_n;

    -- -------------------------------------------------------------------------
    --  UART RECEIVER
    -- -------------------------------------------------------------------------

    uart_rx_i: entity work.UART_RX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK          => CLK,
        RST          => RST,
        -- UART INTERFACE
        UART_CLK_EN  => oversampling_clk_en,
        UART_RXD     => uart_rxd_debounced,
        -- USER DATA OUTPUT INTERFACE
        DOUT         => DOUT,
        DOUT_VLD     => DOUT_VLD,
        FRAME_ERROR  => FRAME_ERROR,
        PARITY_ERROR => open
    );

    -- -------------------------------------------------------------------------
    --  UART TRANSMITTER
    -- -------------------------------------------------------------------------

    uart_tx_i: entity work.UART_TX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_CLK_EN => oversampling_clk_en,
        UART_TXD    => UART_TXD,
        -- USER DATA INPUT INTERFACE
        DIN         => DIN,
        DIN_VLD     => DIN_VLD,
        DIN_RDY     => DIN_RDY
    );

end architecture;
