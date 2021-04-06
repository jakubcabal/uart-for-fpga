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

Use debouncer | Parity type | LE (LUT+FF) | LUT | FF | M9k | Fmax
:---:|:---:|:---:|:---:|:---:|:---:|:---:
True  | none       | 76 | 62 | 56 | 0 | 304.8 MHz
True  | even/odd   | 86 | 73 | 59 | 0 | 277.3 MHz
True  | mark/space | 80 | 66 | 59 | 0 | 292.3 MHz
False | none       | 73 | 60 | 52 | 0 | 308.7 MHz
False | even/odd   | 79 | 71 | 55 | 0 | 278.7 MHz
False | mark/space | 77 | 64 | 55 | 0 | 338.0 MHz

*Implementation was performed using Quartus Prime Lite Edition 18.1.0 for Intel Cyclone 10 FPGA (10CL025YU256C8G). Setting of some generics: BAUD_RATE = 115200, CLK_FREQ = 50e6.*

## Simulation:

A basic simulation is prepared in the repository. You can use the prepared TCL script to run simulation in ModelSim.

```
vsim -do sim/sim.tcl
```

## Examples:

The repository also includes several UART example designs. I use it on my FPGA board [CYC1000](https://shop.trenz-electronic.de/en/TEI0003-02-CYC1000-with-Cyclone-10-FPGA-8-MByte-SDRAM) with Intel Cyclone 10 FPGA (10CL025YU256C8G) and FTDI USB to UART Bridge. Here you can find [the documentation of the CYC1000 board](https://www.trenz-electronic.de/fileadmin/docs/Trenz_Electronic/Modules_and_Module_Carriers/2.5x6.15/TEI0003/REV02/Documents/CYC1000%20User%20Guide.pdf).

### UART loopback:

The UART loopback example design is for testing data transfer between FPGA and PC. Data that you send from the PC to the FPGA via UART will be automatically sent back to the PC.

![Block diagram of UART loopback example design](docs/uart_loopback.svg)

### UART2WB bridge:

The UART2WB bridge example design is for testing access to Wishbone registers via the UART bridge. The example uses a simple script written in Python that allows you to read or write to 32-bit user registers connected to the Wishbone bus.

![Block diagram of UART2WB bridge example design](docs/uart2wb.svg)

## License:

This UART controller is available under the MIT license. Please read [LICENSE file](LICENSE).
