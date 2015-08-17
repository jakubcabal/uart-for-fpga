# Simple UART for FPGA

Simple UART (Universal Asynchronous Receiver & Transmitter) module for serial communication with an FPGA. The UART module was implemented using VHDL.

**The default settings are 115200 Baud rate, 8 Data bits, 1 Stop bit, No parity, disable input data FIFO.**

The UART module was tested in hardware. In the near future it will be implemented generic support for parity bit and set the number of stop bits. Stay tuned!

**Synthesis resource usage summary:**

Input data FIFO | Logic element (LUT) | Registers (FF) | Block RAM (BRAM)
--- | --- | --- | ---
disable | 77 | 51 | 0
enable | 116 | 68 | 1

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 with default settings for Cyclone II.*
