# Simple UART for FPGA

Simple UART for FPGA is UART (Universal Asynchronous Receiver & Transmitter) controller for serial communication with an FPGA. The UART controller was implemented using VHDL 93 and is applicable to any FPGA.

**Simple UART for FPGA requires: 1 start bit, 8 data bits, 1 stop bit!**

The UART controller was simulated and tested in hardware.

# Table of inputs and outputs ports:

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
FRAME_ERROR | OUT | 1b | Stop bit is invalid, data may be corrupted.

# Table of generics:

Generic name | Type | Default value | Generic description
---|:---:|:---:|:---
CLK_FREQ | integer | 50e6 | System clock.
BAUD_RATE | integer | 115200 | Baud rate value.
PARITY_BIT | string | "none" | Type of parity: "none", "even", "odd", "mark", "space".
USE_DEBOUNCER | boolean | True | Use debounce?

# Table of resource usage summary:

Use debouncer | Parity type | LE (LUT+FF) | LUT | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:|:---:|:---:
True | none | 77 | 64 | 55 | 0 | 202.2 MHz
True | even/odd | 82 | 75 | 58 | 0 | 162.5 MHz
True | mark/space | 80 | 68 | 58 | 0 | 184.5 MHz
False | none | 72 | 59 | 50 | 0 | 182.7 MHz
False | even/odd | 77 | 70 | 53 | 0 | 155.6 MHz
False | mark/space | 75 | 62 | 53 | 0 | 200.8 MHz

*Synthesis was performed using Quartus II 64-Bit Version 13.0.1 for FPGA Altera Cyclone II with enable force use of synchronous clear. Setting of some generics: BAUD_RATE = 115200, CLK_FREQ = 50e6.*

# License:

This UART controller is available under the MIT license (MIT). Please read [LICENSE file](LICENSE).
