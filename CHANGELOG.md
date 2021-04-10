# Changelog of Simple UART for FPGA

**Version 1.3 - released on 10 April 2021**
- Added better simulation with automatic checking of transactions.
- Little code cleaning and code optimization.
- Added UART2WB bridge example (access to WB registers via UART).
- Added Parity Error output.

**Version 1.2 - released on 23 December 2019**
- Added double FF for safe CDC.
- Fixed fake received transaction after FPGA boot without reset.
- Added more precisely clock dividers, dividing with rounding.
- UART loopback example is for CYC1000 board now.

**Version 1.1 - released on 20 December 2018**
- Added better debouncer.
- Added simulation script and Quartus project file.
- Removed unnecessary resets.
- Signal BUSY replaced by DIN_RDY.
- Many other optimizations and changes.

**Version 1.0 - released on 27 May 2016**
- Initial release.
