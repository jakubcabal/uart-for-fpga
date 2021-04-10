#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

create_clock -name CLK12M -period 12MHz [get_ports {CLK_12M}]
