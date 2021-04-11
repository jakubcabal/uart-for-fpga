--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity UART_TB is
    Generic (
        CLK_FREQ      : natural := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : natural := 115200; -- baud rate value
        TRANS_COUNT   : natural := 1e4     -- number of test transaction
    );
end entity;

architecture SIM of UART_TB is

    signal CLK : std_logic;
    signal RST : std_logic;

    signal driver_rxd_din  : std_logic_vector(7 downto 0);
    signal driver_rxd      : std_logic := '1';
    signal driver_rxd_done : std_logic := '0';

    signal monitor_dout_expected : std_logic_vector(7 downto 0);
    signal monitor_dout          : std_logic_vector(7 downto 0);
    signal monitor_dout_vld      : std_logic;
    signal monitor_dout_done     : std_logic := '0';

    signal driver_din      : std_logic_vector(7 downto 0);
    signal driver_din_vld  : std_logic := '0';
    signal driver_din_rdy  : std_logic;
    signal driver_din_done : std_logic := '0';

    signal monitor_txd_dout_expected : std_logic_vector(7 downto 0);
    signal monitor_txd_dout          : std_logic_vector(7 downto 0);
    signal monitor_txd               : std_logic := '1';
    signal monitor_txd_done          : std_logic := '0';
    signal monitor_txd_start_bit     : std_logic := '0';
    signal monitor_txd_stop_bit      : std_logic := '0';

    signal frame_error  : std_logic;
    signal parity_error : std_logic;

    signal sim_done : std_logic := '0';
    signal rand_int : integer := 0;
    signal count_rx : integer;
    signal count_tx : integer;

    constant CLK_PERIOD    : time := 1 ns * integer(real(1e9)/real(CLK_FREQ));
    constant UART_PERIOD_I : natural := integer(real(1e9)/real(BAUD_RATE));
    constant UART_PERIOD   : time := 1 ns * UART_PERIOD_I;

    procedure UART_DRIVER (
        constant UART_PER : time;
        signal   UART_DIN : in  std_logic_vector(7 downto 0);
        signal   UART_TXD : out std_logic
    ) is
        variable rnd_delay : natural;
    begin
        -- start bit
        UART_TXD <= '0';
        wait for UART_PER;
         -- data bits
        for i in 0 to (UART_DIN'LENGTH-1) loop
            UART_TXD <= UART_DIN(i);
            wait for UART_PER;
        end loop;
         -- stop bit
        UART_TXD <= '1';
        wait for UART_PER;
    end procedure;
    
    procedure UART_MONITOR (
        constant UART_PER       : time;
        signal   UART_RXD       : in  std_logic;
        signal   UART_DOUT      : out std_logic_vector(7 downto 0);
        signal   UART_START_BIT : out std_logic;
        signal   UART_STOP_BIT  : out std_logic
    ) is begin
        if (UART_RXD = '1') then
            wait until UART_RXD = '0';
        end if;
        UART_START_BIT <= '1';
        -- start bit
        wait for UART_PER;
        UART_START_BIT <= '0';
        -- data bits
        wait for UART_PER/2; -- move to middle data bit 
        for i in 0 to (UART_DOUT'LENGTH-2) loop
            UART_DOUT(i) <= UART_RXD;
            wait for UART_PER;
        end loop;
        -- last data bit
        UART_DOUT(UART_DOUT'LENGTH-1) <= UART_RXD;
        wait for UART_PER/2;
        -- stop bit
        UART_STOP_BIT <= '1';
        -- move to middle of stop bit
        wait for UART_PER/2;
        if (UART_RXD = '0') then
            report "======== INVALID STOP BIT IN UART_MONITOR! ========" severity failure;
        end if;
        UART_STOP_BIT <= '0';
        -- in middle of stop bit move to resync (wait for start bit)
    end procedure;

begin

    rand_int_p : process
        variable seed1, seed2: positive;
        variable rand : real;
    begin
        uniform(seed1, seed2, rand);
        rand_int <= integer(rand*real(20));
        --report "Random number X: " & integer'image(rand_int);
        wait for CLK_PERIOD;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    utt : entity work.UART
    generic map (
        CLK_FREQ    => CLK_FREQ,
        BAUD_RATE   => BAUD_RATE,
        PARITY_BIT  => "none" -- parity bit is not supported in this simulation
    )
    port map (
        CLK          => CLK,
        RST          => RST,
        -- UART INTERFACE
        UART_TXD     => monitor_txd,
        UART_RXD     => driver_rxd,
        -- USER DATA INPUT INTERFACE
        DIN          => driver_din,
        DIN_VLD      => driver_din_vld,
        DIN_RDY      => driver_din_rdy,
        -- USER DATA OUTPUT INTERFACE
        DOUT         => monitor_dout,
        DOUT_VLD     => monitor_dout_vld,
        FRAME_ERROR  => frame_error,
        PARITY_ERROR => parity_error
    );

    clk_gen_p : process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    rst_gen_p : process
    begin
        report "======== SIMULATION START! ========";
        report "Total transactions for RX direction: " & integer'image(TRANS_COUNT);
        report "Total transactions for TX direction: " & integer'image(TRANS_COUNT);
        RST <= '1';
        wait for CLK_PERIOD*3;
          RST <= '0';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  UART MODULE RECEIVING TEST
    -- -------------------------------------------------------------------------

    driver_rxd_p : process
    begin
        driver_rxd <= '1';
        wait until RST = '0';
        wait for 33 ns;
        for i in 0 to TRANS_COUNT-1 loop
            driver_rxd_din <= std_logic_vector(to_unsigned((i mod 2**8),driver_rxd_din'LENGTH));
            UART_DRIVER(UART_PERIOD, driver_rxd_din, driver_rxd);
            wait for (rand_int/2) * UART_PERIOD;
        end loop;
        driver_rxd_done <= '1';
        wait;
    end process;

    monitor_dout_p : process
    begin
        count_rx <= 1;
        for i in 0 to TRANS_COUNT-1 loop
            monitor_dout_expected <= std_logic_vector(to_unsigned((i mod 2**8),monitor_dout_expected'LENGTH));
            wait until monitor_dout_vld = '1';
            if (monitor_dout = monitor_dout_expected) then
                --report "Transaction on DOUT port is OK." severity note;
                if ((count_rx mod (TRANS_COUNT/10)) = 0) then
                    report "Transactions received at RX monitor: " & integer'image(count_rx);
                end if;
            else
                report "======== UNEXPECTED TRANSACTION ON DOUT PORT! ========" severity failure;
            end if;
            count_rx <= count_rx + 1;
            wait for CLK_PERIOD;
        end loop;
        monitor_dout_done <= '1';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  UART MODULE TRANSMISSION TEST
    -- -------------------------------------------------------------------------

    driver_din_p : process
    begin
        wait until RST = '0';
        wait until rising_edge(CLK);
        wait for CLK_PERIOD/2;
        for i in 0 to TRANS_COUNT-1 loop
            driver_din <= std_logic_vector(to_unsigned((i mod 2**8),driver_din'LENGTH));
            driver_din_vld <= '1';
            if (driver_din_rdy = '0') then	
                wait until driver_din_rdy = '1';
                wait for CLK_PERIOD/2;
            end if;
            wait for CLK_PERIOD;
            driver_din_vld <= '0';
            wait for rand_int*(UART_PERIOD_I/16)*CLK_PERIOD;
        end loop;
        driver_din_done <= '1';
        wait;
    end process;

    monitor_txd_p : process
    begin
        count_tx <= 1;
        for i in 0 to TRANS_COUNT-1 loop
            monitor_txd_dout_expected <= std_logic_vector(to_unsigned((i mod 2**8),monitor_txd_dout_expected'LENGTH));
            UART_MONITOR(UART_PERIOD, monitor_txd, monitor_txd_dout, monitor_txd_start_bit, monitor_txd_stop_bit);
            if (monitor_txd_dout = monitor_txd_dout_expected) then
                --report "Transaction on UART_TXD port is OK." severity note;
                if ((count_tx mod (TRANS_COUNT/10)) = 0) then
                    report "Transactions received at TX monitor: " & integer'image(count_tx);
                end if;
            else
                report "======== UNEXPECTED TRANSACTION ON UART_TXD PORT! ========" severity failure;
            end if;
            count_tx <= count_tx + 1;
        end loop;
        monitor_txd_done <= '1';
        wait;
    end process;

    -- -------------------------------------------------------------------------
    --  TEST DONE CHECK
    -- -------------------------------------------------------------------------

    test_done_p : process
        variable v_test_done : std_logic;
    begin
        v_test_done := driver_rxd_done and monitor_dout_done and driver_din_done and monitor_txd_done;
        if (v_test_done = '1') then
            wait for 100*CLK_PERIOD;
            sim_done <= '1';
            report "======== SIMULATION SUCCESSFULLY COMPLETED! ========";
            wait;
        end if;
        wait for CLK_PERIOD;
    end process;

end architecture;
