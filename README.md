# ssd1331-spin
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Solomon Systech SSD1331 OLED display controller.

## Salient Features

* P1: SPI connection at up to 20MHz
* P2: SPI connection at up to 6.5MHz
* Most accelerated graphics primitives implemented, as well as a 'soft' pixel primitive
* Integrates a generic bitmap graphics library for more flexibility (though slower)
* Supports horizontal and vertical mirroring
* Supports interlaced and non-interlaced display
* Supports normal and inverted display

## Requirements

* P1: 1 extra core/cog for the PASM SPI driver
* P2: No additional resources

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
