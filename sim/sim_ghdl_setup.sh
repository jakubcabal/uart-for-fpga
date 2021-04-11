#!/bin/bash
#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

# Analyse sources
ghdl -a ../rtl/comp/uart_clk_div.vhd
ghdl -a ../rtl/comp/uart_debouncer.vhd
ghdl -a ../rtl/comp/uart_parity.vhd
ghdl -a ../rtl/comp/uart_tx.vhd
ghdl -a ../rtl/comp/uart_rx.vhd
ghdl -a ../rtl/uart.vhd
ghdl -a ./uart_tb.vhd

# Elaborate the top-level
ghdl -e UART_TB

# Run the simulation
# The following command is allocated to a separate script due to CI purposes.
#ghdl -r UART_TB
