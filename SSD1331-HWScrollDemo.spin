{
    --------------------------------------------
    Filename: SSD1331-HWScrollDemo.spin
    Description: SSD1331 Hardware-accelerated scrolling demo
    Author: Jesse Burt
    Copyright (c) 2023
    Started: Mar 12, 2023
    Updated: Jul 31, 2023
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200
' --

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    fnt:    "font.5x8"
    disp:   "display.oled.ssd1331" | WIDTH=96, HEIGHT=64, CS=0, SCK=1, MOSI=2, DC=3, RST=4

PUB main{} | y

    setup()

    disp.strln(@"SSD1331 on the")
    disp.strln(@"Parallax P8X32A")
    disp.strln(@"HW-accelerated")
    disp.str(@"scrolling demo")
    disp.show{}

    time.msleep(2_000)

    { NOTE: scrolling a partial horizontal region isn't possible in hardware - only the full width
        may be scrolled }

    { full-width horizontal scrolling }
    disp.scroll_fwid_right_cont(0, 63, 1, 6)        ' sy, ey, xstep, scroll step delay (frames)
    time.msleep(2_000)

    { full-width vertical/horizontal scrolling }
    disp.scroll_fwid_right_up_cont(0, 63, 1, 1, 6)  ' sy, ey, xstep, ystep, delay
    time.msleep(2_000)

    { scroll invidual horizontal pages (groups of 8 rows) }
    repeat y from 0 to 24 step 8
        disp.scroll_fwid_right_up_cont(y, y+7, 1, 0, 6)
        time.msleep(2_000)

    disp.scroll_stop{}
    repeat

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if ( disp.start() )
        ser.strln(string("SSD1331 driver started"))
        disp.set_font(fnt.ptr(), fnt.setup())
        disp.preset_96x64_hi_perf{}
        disp.char_attrs(disp.TERMINAL)
    else
        ser.strln(string("SSD1331 driver failed to start - halting"))
        repeat

    disp.mirror_h(false)
    disp.mirror_v(false)
    disp.clear{}
    disp.fgcolor(disp#MAX_COLOR)

DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

