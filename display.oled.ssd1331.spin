{
    --------------------------------------------
    Filename: display.oled.ssd1331.spin
    Author: Jesse Burt
    Description: Driver for Solomon Systech SSD1331 RGB OLED displays
    Copyright (c) 2022
    Started: Apr 28, 2019
    Updated: Jan 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define MEMMV_NATIVE wordmove
#include "lib.gfx.bitmap.spin"

CON

    BYTESPERPX  = 2
    MAX_COLOR   = 65535

' Transaction type selection
    CMD         = 0
    DATA        = 1

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

' Character attributes
    DRAWBG      = 1 << 0

OBJ

    core    : "core.con.ssd1331"                ' HW-specific constants
    time    : "time"                            ' timekeeping methods
    spi     : "com.spi.fast"                    ' Counter-based SPI (20MHzW/10R)

VAR

    long _CS, _SCK, _MOSI, _DC, _RES

    ' shadow registers used since the display registers can't be read from
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG[3], _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_PWRSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL, _sh_FILL

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, ptr_drawbuff): status
' Start using custom I/O settings
'   RES_PIN optional, but recommended (pin # only validated in Reset())
    if lookdown(CS_PIN: 0..31) and lookdown(DC_PIN: 0..31) and {
}   lookdown(DIN_PIN: 0..31) and lookdown(CLK_PIN: 0..31)
        if (status := spi.init(CS_PIN, CLK_PIN, DIN_PIN, -1, core#SPI_MODE))
            longmove(@_CS, @CS_PIN, 5)
            outa[_DC] := 1
            dira[_DC] := 1
            reset{}
            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            _buff_sz := (_disp_width * _disp_height) * BYTESPERPX
            _bytesperln := _disp_width * BYTESPERPX
            address(ptr_drawbuff)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}
' Turn off display, stop SPI engine, clear out variable space
    displayvisibility(ALL_OFF)
    powered(FALSE)
    spi.deinit{}
    longfill(@_CS, 0, 6)
    wordfill(@_buff_sz, 0, 2)
    bytefill(@_disp_width, 0, 30)

PUB Defaults{}
' Factory default settings
    displayvisibility(ALL_OFF)
    displaystartline(0)
    displaylines(64)
    extsupply{}
    clockfreq(956)
    clockdiv(1)
    contrast(127)
    powered(TRUE)
    displaybounds(0, 0, 95, 63)
    clear{}
    displayvisibility(NORMAL)

PUB Preset_96x64{}
' Preset: 96px wide, setup for 64px height
    displayvisibility(ALL_OFF)
    colordepth(COLOR_65K)
    powered(FALSE)
    displaylines(64)
    extsupply{}
    clockfreq(956)
    clockdiv(1)
    contrast(127)
    interlaced(false)
    powered(TRUE)
    displaybounds(0, 0, 95, 63)
    clear{}
    displayvisibility(NORMAL)

PUB Preset_96x64_HiPerf{}
' Preset: 96px wide, setup for 64px height, display osc. set to max clock
    displayvisibility(ALL_OFF)
    colordepth(COLOR_65K)
    powered(FALSE)
    displaylines(64)
    extsupply{}
    clockfreq(980)
    clockdiv(1)
    contrast(127)
    interlaced(false)
    powered(TRUE)
    displaybounds(0, 0, 95, 63)
    clear{}
    displayvisibility(NORMAL)

PUB Preset_96x{}
' Preset: 96px wide, determine settings for height at runtime
    displayvisibility(ALL_OFF)
    colordepth(COLOR_65K)
    powered(FALSE)
    displaylines(_disp_height)
    extsupply{}
    clockfreq(956)
    clockdiv(1)
    contrast(127)
    interlaced(false)
    powered(TRUE)
    displaybounds(0, 0, _disp_width, _disp_height)
    clear{}
    displayvisibility(NORMAL)

PUB Address(addr): curr_addr
' Set framebuffer/display buffer address
    case addr
        $0004..$7FFF-addr:
            _ptr_drawbuffer := addr
        other:
            return _ptr_drawbuffer

PUB AddrMode(mode): curr_mode
' Set display internal addressing mode
'   Valid values:
'       HORIZ (0): Horizontal addressing mode
'       VERT (1): Vertical addressing mode
    curr_mode := _sh_REMAPCOLOR
    case mode
        HORIZ, VERT:
        other:
            return ((curr_mode >> core#ADDRINC) & 1)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#SEGREMAP_MASK) | mode)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

#ifdef GFX_DIRECT
PUB Bitmap(ptr_bmap, xs, ys, bm_wid, bm_lns) | offs, nr_pix
' Display bitmap
'   ptr_bmap: pointer to bitmap data
'   (xs, ys): upper-left corner of bitmap
'   bm_wid: width of bitmap, in pixels
'   bm_lns: number of lines in bitmap
    displaybounds(xs, ys, xs+(bm_wid-1), ys+(bm_lns-1))
    outa[_CS] := 0
    ' calc total number of pixels to write, based on dims and color depth
    ' clamp to a minimum of 1 to avoid odd behavior
    nr_pix := 1 #> ((xs + bm_wid-1) * (ys + bm_lns-1) * BYTESPERPX)

    outa[_DC] := core#DATA
    spi.wrblock_lsbf(ptr_bmap, nr_pix)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB Box(sx, sy, ex, ey, color, filled) | tmp[3]
' Draw a box
'   sx, sy: Start coordinates x0, y0
'   ex, ey: End coordinates
'   color:  Box color
'   filled: Flag to set whether to fill the box or not
    sx := 0 #> sx <# _disp_xmax
    sy := 0 #> sy <# _disp_ymax
    ex := sx #> ex <# _disp_xmax
    ey := sy #> ey <# _disp_ymax
    if filled
        filled := color
        fillaccelenabled(true)
    else
        filled := _bgcolor
        fillaccelenabled(false)
    tmp.byte[0] := sx
    tmp.byte[1] := sy
    tmp.byte[2] := ex
    tmp.byte[3] := ey
    tmp.byte[4] := rgb565_r8(color) << 1        ' R LSB is don't care
    tmp.byte[5] := rgb565_g8(color)
    tmp.byte[6] := rgb565_b8(color) << 1        ' B LSB is don't care
    tmp.byte[7] := rgb565_r8(color) << 1
    tmp.byte[8] := rgb565_g8(color)
    tmp.byte[9] := rgb565_b8(color) << 1
    writereg(core#DRAWRECT, 10, @tmp)
#endif

#ifdef GFX_DIRECT
PUB Char(ch) | gl_c, gl_r, lastgl_c, lastgl_r
' Draw character from currently loaded font
    lastgl_c := _font_width-1
    lastgl_r := _font_height-1
    case ch
        CR:
            _charpx_x := 0
        LF:
            _charpx_y += _charcell_h
            if _charpx_y > _charpx_xmax
                _charpx_y := 0
        0..127:                                 ' validate ASCII code
            ' walk through font glyph data
            repeat gl_c from 0 to lastgl_c      ' column
                repeat gl_r from 0 to lastgl_r  ' row
                    ' if the current offset in the glyph is a set bit, draw it
                    if byte[_font_addr][(ch << 3) + gl_c] & (|< gl_r)
                        plot((_charpx_x + gl_c), (_charpx_y + gl_r), _fgcolor)
                    else
                    ' otherwise, draw the background color, if enabled
                        if _char_attrs & DRAWBG
                            plot((_charpx_x + gl_c), (_charpx_y + gl_r), _bgcolor)
            ' move the cursor to the next column, wrapping around to the left,
            ' and wrap around to the top of the display if the bottom is reached
            _charpx_x += _charcell_w
            if _charpx_x > _charpx_xmax
                _charpx_x := 0
                _charpx_y += _charcell_h
            if _charpx_y > _charpx_ymax
                _charpx_y := 0
        other:
            return
#endif

PUB CharAttrs(attrs)
' Set character attributes
    _char_attrs := attrs

#ifdef GFX_DIRECT
PUB Clear{} | tmp
' Clear the display
    tmp.byte[0] := 0
    tmp.byte[1] := 0
    tmp.byte[2] := _disp_xmax
    tmp.byte[3] := _disp_ymax
    writereg(core#CLEAR, 4, @tmp)

#else

PUB Clear{}
' Clear the display buffer
    wordfill(_ptr_drawbuffer, _bgcolor, _buff_sz/2)
#endif

PUB ClockDiv(divider): curr_div
' Set clock frequency divider used by the display controller
'   Valid values: 1..16
'   Any other value returns the current setting
    curr_div := _sh_CLK
    case divider
        1..16:
            divider -= 1
        other:
            return ((curr_div & core#CLKDIV_BITS) + 1)

    _sh_CLK := ((_sh_CLK & core#CLKDIV_MASK) | divider)
    writereg(core#CLKDIV_FRQ, 1, @_sh_CLK)

PUB ClockFreq(freq): curr_freq
' Set display internal oscillator frequency, in kHz
'   Valid values: 800..980, in steps of 12
'   Any other value returns the current setting
    curr_freq := _sh_CLK
    case freq
        800..980:
            freq := ((freq-800) / 12) << core#FOSCFREQ
        other:
            curr_freq := (curr_freq >> core#FOSCFREQ) & core#FOSCFREQ_BITS
            return (curr_freq * 12) + 800

    _sh_CLK := ((_sh_CLK & core#FOSCFREQ_MASK) | freq)
    writereg(core#CLKDIV_FRQ, 1, @_sh_CLK)

PUB ColorDepth(format): curr_fmt
' Set expected color format of pixel data
'   Valid values:
'       COLOR_256 (0): 8-bit/256 color
'       COLOR_65K (1): 16-bit/65536 color format 1
'       COLOR_65K2 (2): 16-bit/65536 color format 2
'   Any other value returns the current setting
    curr_fmt := _sh_REMAPCOLOR
    case format
        COLOR_256, COLOR_65K, COLOR_65K2:
            format <<= core#COLORFMT
        other:
            return curr_fmt >> core#COLORFMT

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#COLORFMT_MASK) | format)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB COMHighLogicLevel(level): curr_lvl
' Set logic high level threshold of COM pins relative to Vcc, in millivolts
'   Valid values: 440, 520, 610, 710, 830
'   Any other value returns the current setting
    case level
        440, 520, 610, 710, 830:
            level := lookdown(level: 440, 520, 610, 710, 830)
            _sh_VCOMH := lookup(level: $00, $10, $20, $30, $3E)
            writereg(core#VCOMH, 1, @_sh_VCOMH)
        other:
            curr_lvl := lookdown(_sh_VCOMH: $00, $10, $20, $30, $3E)
            return lookup(curr_lvl: 440, 520, 610, 710, 830)

PUB Contrast(level)
' Set display contrast/brightness
'   Valid values: 0..255
'   Any other value returns the current setting
    contrasta(level)
    contrastb(level)
    contrastc(level)

PUB ContrastA(level): curr_lvl
' Set contrast/brightness level of subpixel A
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_A := level
            writereg(core#CONTRASTA, 1, @_sh_SETCONTRAST_A)
        other:
            return _sh_SETCONTRAST_A

PUB ContrastB(level): curr_lvl
' Set contrast/brightness level of subpixel B
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_B := level
            writereg(core#CONTRASTB, 1, @_sh_SETCONTRAST_B)
        other:
            return _sh_SETCONTRAST_B

PUB ContrastC(level): curr_lvl
' Set contrast/brightness level of subpixel C
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_C := level
            writereg(core#CONTRASTC, 1, @_sh_SETCONTRAST_C)
        other:
            return _sh_SETCONTRAST_C

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

    tmp.byte[0] := sx
    tmp.byte[1] := sy
    tmp.byte[2] := ex
    tmp.byte[3] := ey
    tmp.byte[4] := dx
    tmp.byte[5] := dy
    writereg(core#COPY, 6, @tmp)

PUB CopyAccelInverted(state): curr_state
' Enable inverted colors, when using CopyAccel()
    curr_state := _sh_FILL
    case ||(state)
        0, 1:
            state := ||(state) << core#REVCOPY
        other:
            return (((curr_state >> core#REVCOPY) & 1) == 1)

    _sh_FILL := ((_sh_FILL & core#REVCOPY_MASK) | state)
    writereg(core#FILLCPY, 1, @_sh_FILL)

PUB CurrentLimit(divisor): curr_div
' Set master current limit divisor
    case divisor
        1..16:
            _sh_MASTERCCTRL := divisor - 1
            writereg(core#MASTERCURRENT, 1, @_sh_MASTERCCTRL)
        other:
            curr_div := _sh_MASTERCCTRL
            return curr_div + 1

PUB DisplayBounds(sx, sy, ex, ey) | tmp
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..95
'       sy, ey: 0..63
'   Any other value will be ignored
    ifnot lookup(sx: 0..95) or lookup(sy: 0..63) or lookup(ex: 0..95) or{
}   lookup(ey: 0..63)
        return

    tmp.byte[0] := sx
    tmp.byte[1] := ex

    writereg(core#SETCOLUMN, 2, @tmp)

    tmp.byte[0] := sy
    tmp.byte[1] := ey

    writereg(core#SETROW, 2, @tmp)

PUB DisplayInverted(state) | tmp
' Invert display colors
    case ||(state)
        0:
            displayvisibility(NORMAL)
        1:
            displayvisibility(INVERTED)
        other:
            return

PUB DisplayLines(lines): curr_lines
' Set maximum number of display lines
'   Valid values: 16..64
'   Any other value returns the current setting
    curr_lines := _sh_MULTIPLEX
    case lines
        16..64:
            _sh_MULTIPLEX := lines - 1
            writereg(core#SETMULTIPLEX, 1, @_sh_MULTIPLEX)
        other:
            curr_lines := _sh_MULTIPLEX
            return curr_lines + 1

PUB DisplayOffset(lines): curr_lines
' Set display offset/vertical shift
    case lines
        0..63:
            _sh_DISPOFFSET := lines
            writereg(core#DISPLAYOFFSET, 1, @_sh_DISPOFFSET)
        other:
            curr_lines := _sh_DISPOFFSET
            return curr_lines

PUB DisplayStartLine(st_line): curr_line
' Set display start line
    case st_line
        0..63:
            _sh_DISPSTARTLINE := st_line
            writereg(core#STARTLINE, 1, @_sh_DISPSTARTLINE)
        other:
            curr_line := _sh_DISPSTARTLINE
            return curr_line

PUB DisplayVisibility(mode): curr_mode
' Set display visibility
    case mode
        NORMAL, ALL_ON, ALL_OFF, INVERTED:
            _sh_DISPMODE := mode + core#NORMALDISPLAY
            writereg(_sh_DISPMODE, 0, 0)
        other:
            curr_mode := _sh_DISPMODE
            return (_sh_DISPMODE - core#NORMALDISPLAY)

PUB ExtSupply{} | tmp

    tmp := core#MASTERCFG_EXT_VCC
    writereg(core#SETMASTER, 1, @tmp)

PUB FillAccelEnabled(state): curr_state
' Enable the display's native/accelerated fill function, when using Box()
    curr_state := _sh_FILL
    case ||(state)
        0, 1:
            state := ||(state)
        other:
            return ((curr_state & 1) == 1)

    _sh_FILL := ((_sh_FILL & core#FILL_MASK) | state)
    writereg(core#FILLCPY, 1, @_sh_FILL)

PUB Interlaced(state): curr_state
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#COMSPLIT
        other:
            return not (((curr_state >> core#COMSPLIT) & 1) == 1)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#COMSPLIT_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

#ifdef GFX_DIRECT
PUB Line(sx, sy, ex, ey, color) | tmp[2]
' Draw line from sx, sy to ex, ey, in color
    sx := 0 #> sx <# _disp_xmax
    sy := 0 #> sy <# _disp_ymax
    ex := 0 #> ex <# _disp_xmax
    ey := 0 #> ey <# _disp_ymax

    tmp.byte[0] := sx
    tmp.byte[1] := sy
    tmp.byte[2] := ex
    tmp.byte[3] := ey
    tmp.byte[4] := rgb565_r8(color) << 1        ' R LSB is don't care
    tmp.byte[5] := rgb565_g8(color)
    tmp.byte[6] := rgb565_b8(color) << 1        ' B LSB is don't care
    writereg(core#DRAWLINE, 7, @tmp)
#endif

PUB MirrorH(state): curr_state
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := ||(state) << core#SEGREMAP
        other:
            return ((curr_state >> core#SEGREMAP) & 1) == 1

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#SEGREMAP_MASK | state))
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB MirrorV(state): curr_state
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := ||(state) << core#COMREMAP
        other:
            return ((curr_state >> core#COMREMAP) & 1) == 1

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#COMREMAP_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Phase1Period(clks): curr_clks
' Set discharge/phase 1 period, in display clocks
    curr_clks := _sh_PHASE12PER
    case clks
        1..15:
        other:
            return curr_clks & core#PHASE1

    _sh_PHASE12PER := ((_sh_PHASE12PER & core#PHASE1_MASK) | clks)
    writereg(core#PRECHG, 1, @_sh_PHASE12PER)

PUB Phase2Period(clks): curr_clks
' Set charge/phase 2 period, in display clocks
    curr_clks := _sh_PHASE12PER
    case clks
        1..15:
            clks <<= core#PHASE2
        other:
            return (curr_clks >> core#PHASE2) & core#PHASE2

    _sh_PHASE12PER := ((_sh_PHASE12PER & core#PHASE2_MASK) | clks)
    writereg(core#PRECHG, 1, @_sh_PHASE12PER)

#ifdef GFX_DIRECT
PUB Plot(x, y, color) | tmp
' Draw a pixel, using the display's native/accelerated plot/pixel function
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    tmp.byte[0] := x
    tmp.byte[1] := _disp_xmax
    tmp.byte[2] := y
    tmp.byte[3] := _disp_ymax
    
    writereg(core#SETCOLUMN, 2, @tmp)
    writereg(core#SETROW, 2, @tmp.byte[2])
    color &= $FFFF

    outa[_DC] := DATA
    spi.deselectafter(false)
    spi.wr_byte(color.byte[1])
    spi.deselectafter(true)
    spi.wr_byte(color.byte[0])

#else

PUB Plot(x, y, color)
' Plot pixel at (x, y) in color (buffered)
    word[_ptr_drawbuffer][x + (y * _disp_width)] := ((color >> 8) & $FF) | ((color << 8) & $FF00)
#endif

#ifndef GFX_DIRECT
PUB Point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return word[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB Powered(state): curr_state
' Enable display power
    case ||(state)
        OFF, ON, DIM:
            state := lookupz(||(state): core#DISPLAYOFF, core#DISPLAYON,{
}           core#DISPLAYONDIM)
            _sh_DISPONOFF := state
            writereg(_sh_DISPONOFF, 0, 0)
        other:
            return lookdownz(_sh_DISPONOFF: core#DISPLAYOFF, core#DISPLAYON,{
}           core#DISPLAYONDIM)

PUB PowerSaving(state): curr_state
' Enable display power saving mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    case ||(state)
        0, 1:
            state := lookupz(||(state): core#PWRSAVE_DIS, core#PWRSAVE_ENA)
            _sh_PWRSAVE := state
            writereg(core#PWRMODE, 1, @_sh_PWRSAVE)
        other:
            curr_state := _sh_PWRSAVE
            return (lookdownz(curr_state: core#PWRSAVE_DIS, core#PWRSAVE_ENA) & 1) == 1

PUB PrechargeLevel(level): curr_lvl
' Set first pre-charge voltage level (phase 2) of segment pins, in millivolts
    case level
        100..500:
            level := ((level * 10) - 100_0) / 12_9
            _sh_PRECHGLEV := level << core#PRECHG_LVL
            writereg(core#PRECHGLVL, 1, @_sh_PRECHGLEV)
        other:
            curr_lvl := _sh_PRECHGLEV >> 1
            return ((curr_lvl * 12_9) + 100_0) / 10

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

    tmp.byte[0] := seg_a
    tmp.byte[1] := core#PRECHGB
    tmp.byte[2] := seg_b
    tmp.byte[3] := core#PRECHGC
    tmp.byte[4] := seg_c
    writereg(core#PRECHGA, 5, @tmp)

PUB Reset{}
' Reset the display controller
    if lookdown(_RES: 0..31)
        dira[_RES] := 1
        outa[_RES] := 1
        time.msleep(1)
        outa[_RES] := 0
        time.msleep(10)
        outa[_RES] := 1

PUB SubpixelOrder(order): curr_ord
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    curr_ord := _sh_REMAPCOLOR
    case order
        RGB, BGR:
            order <<= core#SUBPIX_ORDER
        other:
            return (curr_ord >> core#SUBPIX_ORDER) & 1

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#SUBPIX_ORDER_MASK) | order)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Update{}
' Write the current display buffer to the display
    outa[_DC] := DATA
    spi.deselectafter(true)
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)

PUB VertAltScan(state): curr_state
' Alternate Left-Right, Right-Left scanning, every other display line
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := ||(state) << core#COMLR_SWAP
        other:
            return (((curr_state >> core#COMLR_SWAP) & 1) == 1)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#COMLR_SWAP_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB WriteBuffer(ptr_buff, buff_sz)
' Write alternate buffer to display
    outa[_DC] := DATA
    spi.deselectafter(true)
    spi.wrblock_lsbf(ptr_buff, buff_sz)

PRI NoOp{}
' No-operation
    writereg(core#NOP3, 0, 0)

#ifndef GFX_DIRECT
PRI memFill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    wordfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), ((val >> 8) & $FF) | ((val << 8) & $FF00), count)
#endif

PRI writeReg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes from ptr_buff to device
    case reg_nr
        ' commands w/parameters
        $15, $21..$27, $75, $81..$83, $87, $8A..$8C, $A0..$A2, $A8, {
}       $AD, $B0, $B1, $B3, $BB, $E3:
            outa[_DC] := CMD
            spi.deselectafter(false)
            spi.wr_byte(reg_nr)
            spi.deselectafter(true)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            return

        ' commands w/o parameters
        $2E, $2F, $A4..$A7, $AC, $AE, $AF, $BC, $BD, $E3:
            outa[_DC] := CMD
            spi.deselectafter(true)
            spi.wr_byte(reg_nr)
            return

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