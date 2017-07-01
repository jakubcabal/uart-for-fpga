# Simple UART for FPGA

Simple UART for FPGA is UART (Universal Asynchronous Receiver & Transmitter) controller for serial communication with an FPGA. The UART controller was implemented using VHDL 93 and is applicable to any FPGA.

**Simple UART for FPGA requires: 1 start bit, 8 data bits, 1 stop bit!**

The UART controller was simulated and tested in hardware.

# Inputs and outputs ports:

```
-- CLOCK AND RESET
CLK         : in  std_logic; -- system clock
RST         : in  std_logic; -- high active synchronous reset

-- UART INTERFACE
UART_TXD    : out std_logic; -- serial transmit data
UART_RXD    : in  std_logic; -- serial receive data

-- USER DATA INPUT INTERFACE
DIN         : in  std_logic_vector(7 downto 0); -- data to be transmitted over UART
DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, DIN is valid and will be accepted for transmiting
BUSY        : out std_logic; -- when BUSY = 1, transmitter is busy and DIN can not be accepted

-- USER DATA OUTPUT INTERFACE
DOUT        : out std_logic_vector(7 downto 0); -- data received via UART
DOUT_VLD    : out std_logic; -- when DOUT_VLD = 1, DOUT is valid (is assert only for one clock cycle)
FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
```

# Generics:

```
CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
BAUD_RATE     : integer := 115200; -- baud rate value
PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
```

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

# Simulation:

A basic simulation is prepared in the repository. You can use the prepared TCL script to run simulation in ModelSim.

```
vsim -do sim/sim.tcl
```

# License:

This UART controller is available under the MIT license (MIT). Please read [LICENSE file](LICENSE).
