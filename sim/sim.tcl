#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License (MIT), please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

# Create work library
vlib work

# Compile VHDL files
vcom -93 ../rtl/comp/uart_clk_div.vhd
vcom -93 ../rtl/comp/uart_debouncer.vhd
vcom -93 ../rtl/comp/uart_parity.vhd
vcom -93 ../rtl/comp/uart_tx.vhd
vcom -93 ../rtl/comp/uart_rx.vhd
vcom -93 ../rtl/uart.vhd
vcom -93 ./uart_tb.vhd

# Load testbench
vsim work.uart_tb

# Setup and start simulation
#add wave *
add wave sim:/uart_tb/utt/*
run 200 us