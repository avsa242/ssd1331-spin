# ssd1331-spin
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Solomon Systech SSD1331 OLED display controller.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* SPI connection at 20MHz (P1), up to 20MHz (P2)
* Most accelerated graphics primitives implemented
* Supports horizontal and vertical mirroring
* Supports interlaced and non-interlaced display
* Supports normal and inverted display
* Supports hardware-accelerated scrolling (horizontal right, or diagonal right/up)
* Integration with the generic bitmap graphics library


## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM SPI engine
* graphics.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.2.1)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.2.1)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.2.1)       | NuCode       | FTBFS                 |
| P2        | SPIN2    | FlexSpin (6.2.1)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* TBD

