#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# MODULE:  SIMULATION TCL SCRIPT FOR MODELSIM
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License (MIT), please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

# Compile VHDL files
vcom ../rtl/comp/uart_parity.vhd
vcom ../rtl/comp/uart_tx.vhd
vcom ../rtl/comp/uart_rx.vhd
vcom ../rtl/uart.vhd
vcom ./uart_tb.vhd

# Load testbench
vsim work.uart_tb

# Setup and start simulation
add wave *
#add wave sim:/uart_tb/utt/*
run 10 us