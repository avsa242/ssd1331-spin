{
    --------------------------------------------
    Filename: display.oled.ssd1331.spi.spin
    Author: Jesse Burt
    Description: Driver for Solomon Systech SSD1331 RGB OLED displays
    Copyright (c) 2021
    Started: Apr 28, 2019
    Updated: Jan 9, 2021
    See end of file for terms of use.
    --------------------------------------------
}
#define SSD1331
#include "lib.gfx.bitmap.spin"

CON

    _DISP_WIDTH = 96
    _DISP_HEIGHT= 64
    _DISP_XMAX  = _DISP_WIDTH-1
    _DISP_YMAX  = _DISP_HEIGHT-1
    _BUFF_SZ    = _DISP_WIDTH * _DISP_HEIGHT * 2
    BYTESPERPX  = 2
    BYTESPERLN  = _DISP_WIDTH * BYTESPERPX
    MAX_COLOR   = 65535

' Transaction type selection
    TRANS_CMD   = 0
    TRANS_DATA  = 1

' Display power modes
    OFF         = 0
    ON          = 1
    DIM         = 2

' Display visibility modes
    NORMAL      = 0
    ALL_ON      = 1
    ALL_OFF     = 2
    INVERTED    = 3

' Color depth formats
    COLOR_256   = %00
    COLOR_65K   = %01
    COLOR_65K2  = %10

' Address increment mode
    HORIZ       = 0
    VERT        = 1

' Subpixel order
    RGB         = 0
    BGR         = 1

OBJ

    core    : "core.con.ssd1331"
    time    : "time"
    spi     : "com.spi.fast"
    io      : "io"

VAR

    long _DC, _RES, _MOSI, _SCK, _CS
    long _ptr_drawbuffer
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG[3], _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_PWRSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL, _sh_FILL

PUB Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN, drawbuffer_address): okay

    if lookdown(CS_PIN: 0..31) and lookdown(DC_PIN: 0..31) and lookdown(DIN_PIN: 0..31) and lookdown(CLK_PIN: 0..31) and lookdown(RES_PIN: 0..31)
        if okay := spi.start (CS_PIN, CLK_PIN, DIN_PIN, -1)
            _DC := DC_PIN
            _RES := RES_PIN
            _MOSI := DIN_PIN
            _SCK := CLK_PIN
            _CS := CS_PIN
            io.high(_DC)
            io.output(_DC)
            io.high(_RES)
            io.output(_RES)
            reset{}
            address(drawbuffer_address)
            return okay
    return FALSE                                ' something above failed

PUB Stop{}

    displayvisibility(ALL_OFF)
    powered(FALSE)

PUB Defaults{}
' Factory default settings
    colordepth(COLOR_65K)
    mirrorh(FALSE)
    powered(FALSE)
    displayvisibility(ALL_OFF)
    displaystartline(0)
    displayoffset(0)
    displayinverted(FALSE)
    displaylines(64)
    extsupply{}
    powersaving(TRUE)
    phase1period(7)
    phase2period(4)
    clockfreq(956)
    clockdiv(1)
    prechargespeed(127, 127, 127)
    prechargelevel(500)
    comhighlogiclevel(830)
    currentlimit(16)
    contrasta(127)
    contrastb(127)
    contrastc(127)
    powered(TRUE)
    displaybounds(0, 0, 95, 63)
    clearaccel{}
    displayvisibility(NORMAL)

PUB DefaultsCommon{}
' Like Defaults, but with clock speed maxed out
    defaults{}
    clockfreq(980)
    addrmode(HORIZ)
    subpixelorder(RGB)
    vertaltscan(FALSE)
    mirrorv(FALSE)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    fillaccelenabled(TRUE)

PUB Address(addr)
' Set framebuffer/display buffer address
    _ptr_drawbuffer := addr

PUB AddrMode(mode) | tmp
' Set display internal addressing mode
'   Valid values:
'       HORIZ (0): Horizontal addressing mode
'       VERT (1): Vertical addressing mode
    tmp := _sh_REMAPCOLOR
    case mode
        HORIZ, VERT:
        other:
            return (tmp >> core#ADDRINC) & 1

    _sh_REMAPCOLOR &= core#SEGREMAP_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | mode) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB BoxAccel(sx, sy, ex, ey, boxcolor, fillcolor) | tmp[3]
' Draw a box, using the display's native/accelerated box function
    sx := 0 #> sx <# _disp_width-1
    sy := 0 #> sy <# _disp_height-1
    ex := sx #> ex <# _disp_width-1
    ey := sy #> ey <# _disp_height-1

    tmp.byte[0] := core#DRAWRECT
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := RGB565_R8 (boxcolor)
    tmp.byte[6] := RGB565_G8 (boxcolor)
    tmp.byte[7] := RGB565_B8 (boxcolor)
    tmp.byte[8] := RGB565_R8 (fillcolor)
    tmp.byte[9] := RGB565_G8 (fillcolor)
    tmp.byte[10] := RGB565_B8 (fillcolor)
    writereg(TRANS_CMD, 11, @tmp)

PUB ClearAccel | tmp[2]
' Clears the display directly, using the display's native/accelerated clear function
    tmp.byte[0] := core#NOP3
    tmp.byte[1] := core#CLEAR
    tmp.byte[2] := 0
    tmp.byte[3] := 0
    tmp.byte[4] := 95
    tmp.byte[5] := 63
    writereg(TRANS_CMD, 6, @tmp)

PUB ClockDiv(divider) | tmp
' Set clock frequency divider used by the display controller
'   Valid values: 1..16
'   Any other value returns the current setting
    tmp := _sh_CLK
    case divider
        1..16:
            divider -= 1
        other:
            return (tmp & core#CLKDIV_BITS) + 1

    _sh_CLK &= core#CLKDIV_MASK
    _sh_CLK := _sh_CLK | divider
    tmp.byte[0] := core#CLKDIV_FRQ
    tmp.byte[1] := divider
    writereg(TRANS_CMD, 2, @tmp)

PUB ClockFreq(freq) | tmp
' Set display internal oscillator frequency, in kHz
'   Valid values: 800..980, in steps of 12
'   Any other value returns the current setting
    tmp := _sh_CLK
    case freq
        800, 812, 824, 836, 848, 860, 872, 884, 896, 908, 920, 932, 944, 956,{
}       968, 980:
            freq := lookdownz(freq: 800, 812, 824, 836, 848, 860, 872, 884,{
}           896, 908, 920, 932, 944, 956, 968, 980) << core#FOSCFREQ
        other:
            tmp := (tmp >> core#FOSCFREQ) & core#FOSCFREQ_BITS
            result := lookupz (tmp: 800, 812, 824, 836, 848, 860, 872, 884,{
}           896, 908, 920, 932, 944, 956, 968, 980)
            return

    _sh_CLK &= core#FOSCFREQ_MASK
    _sh_CLK := _sh_CLK | freq
    tmp.byte[0] := core#CLKDIV_FRQ
    tmp.byte[1] := freq
    writereg(TRANS_CMD, 2, @tmp)

PUB ColorDepth(format) | tmp
' Set expected color format of pixel data
'   Valid values:
'       COLOR_256 (0): 8-bit/256 color
'       COLOR_65K (1): 16-bit/65536 color format 1
'       COLOR_65K2 (2): 16-bit/65536 color format 2
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case format
        COLOR_256, COLOR_65K, COLOR_65K2:
            format <<= core#COLORFMT
        other:
            return tmp >> core#COLORFMT

    _sh_REMAPCOLOR &= core#COLORFMT_MASK
    _sh_REMAPCOLOR := _sh_REMAPCOLOR | format

    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR

    writereg(TRANS_CMD, 2, @tmp)

PUB COMHighLogicLevel(level) | tmp
' Set logic high level threshold of COM pins relative to Vcc, in millivolts
'   Valid values: 440, 520, 610, 710, 830
'   Any other value returns the current setting
    tmp := _sh_VCOMH
    case level := lookdown(level: 440, 520, 610, 710, 830)
        1..5:
            level := lookup(level: $00, $10, $20, $30, $3E)
        other:
            result := lookdown(tmp: $00, $10, $20, $30, $3E)
            return lookup(result: 440, 520, 610, 710, 830)

    _sh_VCOMH := level
    tmp.byte[0] := core#VCOMH
    tmp.byte[1] := level
    writereg(TRANS_CMD, 2, @tmp)

PUB Contrast(level)
' Set display contrast/brightness
'   Valid values: 0..255
'   Any other value returns the current setting
    contrasta(level)
    contrastb(level)
    contrastc(level)

PUB ContrastA(level) | tmp
' Set contrast/brightness level of subpixel a
'   Valid values: 0..255
'   Any other value returns the current setting
    tmp := _sh_SETCONTRAST_A
    case level
        0..255:
        other:
            return tmp

    _sh_SETCONTRAST_A := level
    tmp.byte[0] := core#CONTRASTA
    tmp.byte[1] := level
    writereg(TRANS_CMD, 2, @tmp)

PUB ContrastB(level) | tmp
' Set contrast/brightness level of subpixel b
'   Valid values: 0..255
'   Any other value returns the current setting
    tmp := _sh_SETCONTRAST_B
    case level
        0..255:
        other:
            return tmp

    _sh_SETCONTRAST_B := level
    tmp.byte[0] := core#CONTRASTB
    tmp.byte[1] := level
    writereg(TRANS_CMD, 2, @tmp)

PUB ContrastC(level) | tmp
' Set contrast/brightness level of subpixel c
'   Valid values: 0..255
'   Any other value returns the current setting
    tmp := _sh_SETCONTRAST_C
    case level
        0..255:
        other:
            return tmp

    _sh_SETCONTRAST_C := level
    tmp.byte[0] := core#CONTRASTC
    tmp.byte[1] := level
    writereg(TRANS_CMD, 2, @tmp)

PUB CopyAccel(sx, sy, ex, ey, dx, dy) | tmp[2]
' Use the display's accelerated Copy Region function
'   Valid values:
'       sx, ex, dx: 0..95
'       sy, ey, dy: 0..63
'   Any other value will be ignored
    case sx
        0..95:
        other:
            return

    case sy
        0..63:
        other:
            return

    case ex
        0..95:
        other:
            return

    case ey
        0..63:
        other:
            return

    case dx
        0..95:
        other:
            return

    case dy
        0..63:
        other:
            return

    tmp.byte[0] := core#COPY
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := dx
    tmp.byte[6] := dy
    writereg(TRANS_CMD, 7, @tmp)

PUB CopyAccelInverted(enabled) | tmp
' Enable inverted colors, when using CopyAccel()
    tmp := _sh_FILL
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#REVCOPY
        other:
            return ((tmp >> core#REVCOPY) & 1) == 1

    _sh_FILL &= core#REVCOPY_MASK
    _sh_FILL := (_sh_FILL | enabled) & core#FILLCPY_MASK
    tmp.byte[0] := core#FILLCPY
    tmp.byte[1] := _sh_FILL
    writereg(TRANS_CMD, 2, @tmp)

PUB CurrentLimit(divisor) | tmp
' Set master current limit divisor
    tmp := _sh_MASTERCCTRL
    case divisor
        1..16:
            divisor -= 1
        other:
            return tmp + 1

    _sh_MASTERCCTRL := divisor
    tmp.byte[0] := core#MASTERCURRENT
    tmp.byte[1] := divisor
    writereg(TRANS_CMD, 2, @tmp)

PUB DisplayBounds(sx, sy, ex, ey) | tmp[2]
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..95
'       sy, ey: 0..63
'   Any other value will be ignored
    ifnot lookup(sx: 0..95) or lookup(sy: 0..63) or lookup(ex: 0..95) or{
}   lookup(ey: 0..63)
        return

    tmp.byte[0] := core#SETCOLUMN
    tmp.byte[1] := sx
    tmp.byte[2] := ex

    writereg(TRANS_CMD, 3, @tmp)

    tmp.byte[0] := core#SETROW
    tmp.byte[1] := sy
    tmp.byte[2] := ey

    writereg(TRANS_CMD, 3, @tmp)

PUB DisplayInverted(enabled) | tmp
' Invert display colors
    case ||(enabled)
        0:
            displayvisibility(NORMAL)
        1:
            displayvisibility(INVERTED)
        other:
            return

PUB DisplayLines(lines) | tmp
' Set maximum number of display lines
'   Valid values: 16..64
'   Any other value returns the current setting
    tmp := _sh_MULTIPLEX
    case lines
        16..64:
            lines -= 1
        other:
            return tmp + 1

    _sh_MULTIPLEX := lines
    tmp.byte[0] := core#SETMULTIPLEX
    tmp.byte[1] := lines
    writereg(TRANS_CMD, 2, @tmp)

PUB DisplayOffset(lines) | tmp
' Set display offset/vertical shift
    tmp := _sh_DISPOFFSET
    case lines
        0..63:
        other:
            return tmp

    _sh_DISPOFFSET := lines
    tmp.byte[0] := core#DISPLAYOFFSET
    tmp.byte[1] := lines
    writereg(TRANS_CMD, 2, @tmp)

PUB DisplayStartLine(disp_line) | tmp
' Set display start line
    tmp := _sh_DISPSTARTLINE
    case disp_line
        0..63:
        other:
            return tmp

    _sh_DISPSTARTLINE := disp_line
    tmp.byte[0] := core#STARTLINE
    tmp.byte[1] := disp_line
    writereg(TRANS_CMD, 2, @tmp)

PUB DisplayVisibility(mode) | tmp
' Set display visibility
    tmp := _sh_DISPMODE
    case mode
        NORMAL, ALL_ON, ALL_OFF, INVERTED:
            mode := mode + core#NORMALDISPLAY
        other:
            return (_sh_DISPMODE - core#NORMALDISPLAY)

    _sh_DISPMODE := mode
    writereg(TRANS_CMD, 1, @mode)

PUB ExtSupply{} | tmp

    tmp.byte[0] := core#SETMASTER
    tmp.byte[1] := core#MASTERCFG_EXT_VCC
    writereg(TRANS_CMD, 2, @tmp)

PUB FillAccelEnabled(enabled) | tmp
' Enable the display's native/accelerated fill function, when using BoxAccel()
    tmp := _sh_FILL
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) & 1
        other:
            return (tmp & 1) == 1

    _sh_FILL &= core#FILL_MASK
    _sh_FILL := (_sh_FILL | enabled) & core#FILLCPY_MASK
    tmp.byte[0] := core#FILL
    tmp.byte[1] := _sh_FILL
    writereg(TRANS_CMD, 2, @tmp)

PUB Interlaced(enabled) | tmp
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||(enabled)
        0, 1:
            enabled := (||(enabled) ^ 1) << core#COMSPLIT
        other:
            return not (((tmp >> core#COMSPLIT) & 1) == 1)

    _sh_REMAPCOLOR &= core#COMSPLIT_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB LineAccel(sx, sy, ex, ey, color) | tmp[2]
' Draw a line, using the display's native/accelerated line function
    sx := 0 #> sx <# _disp_width-1
    sy := 0 #> sy <# _disp_height-1
    ex := 0 #> ex <# _disp_width-1
    ey := 0 #> ey <# _disp_height-1

    tmp.byte[0] := core#DRAWLINE
    tmp.byte[1] := sx
    tmp.byte[2] := sy
    tmp.byte[3] := ex
    tmp.byte[4] := ey
    tmp.byte[5] := RGB565_R8 (color)
    tmp.byte[6] := RGB565_G8 (color)
    tmp.byte[7] := RGB565_B8 (color)
    writereg(TRANS_CMD, 8, @tmp)

PUB MirrorH(enabled) | tmp
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||(enabled)
        0, 1:
            enabled := (||(enabled)) << core#SEGREMAP
        other:
            return ((tmp >> core#SEGREMAP) & 1) == 1

    _sh_REMAPCOLOR &= core#SEGREMAP_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB MirrorV(enabled) | tmp
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#COMREMAP
        other:
            return ((tmp >> core#COMREMAP) & 1) == 1

    _sh_REMAPCOLOR &= core#COMREMAP_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB NoOp{} | tmp
' No-operation
    tmp := core#NOP3
    writereg(TRANS_CMD, 1, @tmp)

PUB Phase1Period(clks) | tmp
' Set discharge/phase 1 period, in display clocks
    tmp := _sh_PHASE12PER
    case clks
        1..15:
        other:
            return tmp & core#PHASE1

    _sh_PHASE12PER &= core#PHASE1_MASK
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#PRECHG
    tmp.byte[1] := _sh_PHASE12PER
    writereg(TRANS_CMD, 2, @tmp)

PUB Phase2Period(clks) | tmp
' Set charge/phase 2 period, in display clocks
    tmp := _sh_PHASE12PER
    case clks
        1..15:
            clks <<= core#PHASE2
        other:
            return (tmp >> core#PHASE2) & core#PHASE2

    _sh_PHASE12PER &= core#PHASE2_MASK
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#PRECHG
    tmp.byte[1] := _sh_PHASE12PER
    writereg(TRANS_CMD, 2, @tmp)

PUB PlotAccel(x, y, color) | tmp[2]
' Draw a pixel, using the display's native/accelerated plot/pixel function
    x := 0 #> x <# _disp_width-1
    y := 0 #> y <# _disp_height-1
    tmp.byte[0] := core#SETCOLUMN
    tmp.byte[1] := x
    tmp.byte[2] := 95
    tmp.byte[3] := core#SETROW
    tmp.byte[4] := y
    tmp.byte[5] := 63
    
    writereg(TRANS_CMD, 6, @tmp)

    time.usleep(3)

    writereg(TRANS_DATA, 2, @color)

PUB Powered(enabled) | tmp
' Enable display power
    tmp := _sh_DISPONOFF
    case ||(enabled)
        OFF, ON, DIM:
            enabled := lookupz(||(enabled): core#DISPLAYOFF, core#DISPLAYON,{
}           core#DISPLAYONDIM)
        other:
            return lookdownz(tmp: core#DISPLAYOFF, core#DISPLAYON,{
}           core#DISPLAYONDIM)

    _sh_DISPONOFF := enabled
    writereg(TRANS_CMD, 1, @_sh_DISPONOFF)

PUB PowerSaving(enabled) | tmp
' Enable display power saving mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_PWRSAVE
    case ||(enabled)
        0, 1:
            enabled := lookupz(||(enabled): core#PWRSAVE_DIS, core#PWRSAVE_ENA)
        other:
            return (lookdownz(_sh_PWRSAVE: core#PWRSAVE_DIS, core#PWRSAVE_ENA) & 1) == 1

    _sh_PWRSAVE := enabled
    tmp.byte[0] := core#PWRMODE
    tmp.byte[1] := enabled
    writereg(TRANS_CMD, 2, @tmp)

PUB PrechargeLevel(level) | tmp
' Set first pre-charge voltage level (phase 2) of segment pins, in millivolts
    tmp := _sh_PRECHGLEV
    case level := lookdown(level: 100, 110, 130, 140, 150, 170, 180, 190,{
}   200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360, 370,{
}   390, 400, 410, 430, 440, 450, 460, 480, 490, 500)
        1..32:
            level := (level - 1) << 1
        other:
            result := (tmp >> 1)
            return lookupz(result: 100, 110, 130, 140, 150, 170, 180, 190,{
}           200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360,{
}           370, 390, 400, 410, 430, 440, 450, 460, 480, 490, 500)

    _sh_PRECHGLEV := level
    tmp.byte[0] := core#PRECHGLVL
    tmp.byte[1] := level
    writereg(TRANS_CMD, 2, @tmp)

PUB PrechargeSpeed(seg_a, seg_b, seg_c) | tmp[2]

    case seg_a
        $00..$FF:
        other:
            return _sh_SECPRECHG.byte[0]
    case seg_b
        $00..$FF:
        other:
            return _sh_SECPRECHG.byte[1]
    case seg_c
        $00..$FF:
        other:
            return _sh_SECPRECHG.byte[2]

    _sh_SECPRECHG[0] := seg_a
    _sh_SECPRECHG[1] := seg_b
    _sh_SECPRECHG[2] := seg_c

    tmp.byte[0] := core#PRECHGA
    tmp.byte[1] := seg_a
    tmp.byte[2] := core#PRECHGB
    tmp.byte[3] := seg_b
    tmp.byte[4] := core#PRECHGC
    tmp.byte[5] := seg_c
    writereg(TRANS_CMD, 6, @tmp)

PUB Reset{}
' Reset the display controller
    io.high(_RES)
    time.msleep(1)
    io.low(_RES)
    time.msleep(10)
    io.high(_RES)

PUB SubpixelOrder(order) | tmp
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case order
        RGB, BGR:
            order <<= core#SUBPIX_ORDER
        other:
            return (tmp >> core#SUBPIX_ORDER) & 1

    _sh_REMAPCOLOR &= core#SUBPIX_ORDER_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | order) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB Update{}
' Write the current display buffer to the display
    writereg(TRANS_DATA, _buff_sz, _ptr_drawbuffer)

PUB VertAltScan(enabled) | tmp
' Alternate Left-Right, Right-Left scanning, every other display line
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||(enabled)
        0, 1:
            enabled := ||(enabled) << core#COMLR_SWAP
        other:
            return ((tmp >> core#COMLR_SWAP) & 1) == 1

    _sh_REMAPCOLOR &= core#COMLR_SWAP_MASK
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    tmp.byte[0] := core#SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writereg(TRANS_CMD, 2, @tmp)

PUB WriteBuffer(ptr_buff, buff_sz)
' Write alternate buffer to display
    writereg(TRANS_DATA, buff_sz, ptr_buff)

PRI writeReg(trans_type, nr_bytes, ptr_buff)
' Write nr_bytes from ptr_buff to device
    case trans_type
        TRANS_DATA:
            io.high(_DC)
        TRANS_CMD:
            io.low(_DC)
        other:
            return

    ' write with blocking enabled, and raise CS afterwards
    spi.write(TRUE, ptr_buff, nr_bytes, TRUE)

{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
