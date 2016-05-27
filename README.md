# Simple UART for FPGA

Simple UART (Universal Asynchronous Receiver & Transmitter) module for serial communication with an FPGA. The UART module was implemented using VHDL.

**Simple UART for FPGA requires: 1 start bit, 8 data bits, 1 stop bit!**

The UART module was simulated and tested in hardware.

**Synthesis resource usage summary:**

Parity | LE (LUT) | FF | BRAM
--- | --- | --- | ---
none | 80 | 55 | 0
even/odd | 91 | 58 | 0
mark/space | 84 | 58 | 0

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 for FPGA Altera Cyclone II with these settings: 115200 baud rate and 50 MHz system clock .*
