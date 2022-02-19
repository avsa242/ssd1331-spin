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
* Integration with the generic bitmap graphics library

## Requirements

* Presence of bitmap graphics library (lib.gfx.bitmap)

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.9-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.9-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.9-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.9-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* No hardware-accelerated scrolling support

