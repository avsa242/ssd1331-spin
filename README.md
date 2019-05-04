# ssd1331-spin
---------------

This is a P8X32A/Propeller driver object for the Solomon Systech SSD1331 OLED display controller.

## Salient Features

* HLL methods for most functionality, normally seen as a cryptic stream of hexadecimal bytes in other drivers
* Most accelerated graphics primitives implemented, as well as a 'soft' Pixel primitive
* Supports horizontal and vertical mirroring
* Supports interlaced and non-interlaced display
* Supports normal and inverted display
* Uses 20MHz PASM SPI driver, by way of the counters 


## Requirements

* 1 extra core/cog for the PASM SPI driver

## Limitations

* Very early development - may malfunction or outright fail to build
* Some hardware abstraction methods still need some better/more intuitive parameters
 
## TODO

* Documentation
* Bitmap transfer
* Investigate speeding up SPI driver even more
* Text primitive
* Circle primitive
* Scrolling
* Size optimization
