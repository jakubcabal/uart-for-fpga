# Simple UART for FPGA

Simple UART for FPGA is UART (Universal Asynchronous Receiver & Transmitter) controller for serial communication with an FPGA. The UART controller was implemented using VHDL 93 and is applicable to any FPGA.

**Simple UART for FPGA requires: 1 start bit, 8 data bits, 1 stop bit!**

The UART controller was simulated and tested in hardware.

# Inputs and outputs ports:

Port name | IN/OUT | Width | Port description
---|:---:|:---:|---
CLK | IN | 1b | System clock.
RST | IN | 1b | High active synchronous reset.
UART_TXD | OUT | 1b | Serial transmit data.
UART_RXD | IN | 1b | Serial receive data.
DATA_IN | IN | 8b | Data byte for transmit.
DATA_SEND | IN | 1b | Send data byte for transmit.
BUSY | OUT | 1b | Transmitter is busy, can not send next data.
DATA_OUT | OUT | 8b | Received data byte.
DATA_VLD | OUT | 1b | Received data byte is valid.
FRAME_ERROR | OUT | 1b | Stop bit is invalid, current and next data may be corrupted.

# Synthesis resource usage summary:

Parity | LE (LUT) | FF | BRAM
:---:|:---:|:---:|:---:
none | 80 | 55 | 0
even/odd | 91 | 58 | 0
mark/space | 84 | 58 | 0

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 for FPGA Altera Cyclone II with these settings: 115200 baud rate and 50 MHz system clock .*
