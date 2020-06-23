# ssd1331-spin
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Solomon Systech SSD1331 OLED display controller.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* P1: SPI connection at up to 20MHz
* P2: SPI connection at up to 20MHz+ (max spec is 6MHz, but this isn't enforced. YMMV)
* Most accelerated graphics primitives implemented, as well as a 'soft' pixel primitive
* Supports horizontal and vertical mirroring
* Supports interlaced and non-interlaced display
* Supports normal and inverted display

## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM SPI driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.2.3-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early development - may malfunction or outright fail to build
* Some hardware abstraction methods still need some better/more intuitive parameters
* Bitmap transfer is currently fixed to full frame transfer, starting at coords 0, 0
* No scrolling support

## TODO

- [ ] Documentation
- [x] Bitmap transfer
- [ ] Scrolling
- [ ] Size optimization
- [ ] Re-write the demo such that each routine runs for a set time period, and implement benchmarking for that period of time
