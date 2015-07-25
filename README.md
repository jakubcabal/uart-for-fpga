# Simple UART for FPGA

Simple UART (Universal Asynchronous Receiver & Transmitter) module for serial communication with an FPGA. The UART module was implemented using VHDL.

**The default settings are 115200 Baud rate, 8 Data bits, 1 Stop bit, No parity.**

The UART module passed simulations. In the near future it will be implemented generic support for parity bit and set the number of stop bits. Stay tuned!

**Synthesis resource usage summary:**
- Logic element (LUT): 85
- Registers (FF): 50

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 with default settings.*
