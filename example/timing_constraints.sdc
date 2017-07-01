#-------------------------------------------------------------------------------
# PROJECT: SIMPLE UART FOR FPGA
#-------------------------------------------------------------------------------
# MODULE:  TIMING CONSTRAINTS
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License (MIT), please read LICENSE file
# WEBSITE: https://github.com/jakubcabal/uart-for-fpga
#-------------------------------------------------------------------------------

create_clock -name CLK50 -period 20.000 [get_ports {CLK}]
