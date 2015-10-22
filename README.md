# Simple UART for FPGA

Simple UART (Universal Asynchronous Receiver & Transmitter) module for serial communication with an FPGA. The UART module was implemented using VHDL.

**The default settings are 115200 baud rate, 8 data bits, 1 stop bit, no parity, disable input data FIFO, 50 MHz system clock.**

The UART module was tested in hardware. In the near future it will be implemented generic support settings of stop bits. Stay tuned!

**Synthesis resource usage summary:**

Parity | Input FIFO | LE (LUT) | FF | BRAM
--- | --- | --- | --- | ---
none | disable | 72 | 46 | 0
none | enable | 110 | 63 | 1
even/odd | disable | 82 | 49 | 0
even/odd | enable | 121 | 66 | 1
mark/space | disable | 77 | 49 | 0
mark/space | enable | 115 | 66 | 1

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 with default settings for FPGA Altera Cyclone II.*
