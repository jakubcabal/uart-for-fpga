# Simple UART for FPGA

Simple UART for FPGA is UART (Universal Asynchronous Receiver & Transmitter) controller for serial communication with an FPGA. The UART controller was implemented using VHDL 93 and is applicable to any FPGA.

**Simple UART for FPGA requires: 1 start bit, 8 data bits, 1 stop bit!**

The UART controller was simulated and tested in hardware.

## Inputs and outputs ports:

```
-- CLOCK AND RESET
CLK         : in  std_logic; -- system clock
RST         : in  std_logic; -- high active synchronous reset
-- UART INTERFACE
UART_TXD    : out std_logic; -- serial transmit data
UART_RXD    : in  std_logic; -- serial receive data
-- USER DATA INPUT INTERFACE
DIN         : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
DIN_RDY     : out std_logic  -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
-- USER DATA OUTPUT INTERFACE
DOUT        : out std_logic_vector(7 downto 0); -- output data received via UART
DOUT_VLD    : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
```

## Generics:

```
CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
BAUD_RATE     : integer := 115200; -- baud rate value
PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
```

## Table of resource usage summary:

Use debouncer | Parity type | LE (LUT+FF) | LUT | FF | BRAM | Fmax
:---:|:---:|:---:|:---:|:---:|:---:|:---:
True | none | 74 | 59 | 53 | 0 | 220.0 MHz
True | even/odd | 81 | 70 | 56 | 0 | 193.3 MHz
True | mark/space | 78 | 63 | 56 | 0 | 210.2 MHz
False | none | 70 | 57 | 49 | 0 | 182.3 MHz
False | even/odd | 78 | 68 | 52 | 0 | 183.5 MHz
False | mark/space | 74 | 61 | 52 | 0 | 186.2 MHz

*Implementation was performed using Quartus Prime Lite Edition 17.0.0 for FPGA Altera Cyclone IV E EP4CE6E22C8. Setting of some generics: BAUD_RATE = 115200, CLK_FREQ = 50e6.*

## Simulation:

A basic simulation is prepared in the repository. You can use the prepared TCL script to run simulation in ModelSim.

```
vsim -do sim/sim.tcl
```

## UART loopback example:

The UART loopback example design is for testing data transfer between FPGA and PC.
I use it on my cheap FPGA board ([EP4CE6 Starter Board](http://www.ebay.com/itm/111975895262) with Altera FPGA Cyclone IV EP4CE6E22C8) together with external USB to UART Bridge.

## License:

This UART controller is available under the MIT license (MIT). Please read [LICENSE file](LICENSE).
