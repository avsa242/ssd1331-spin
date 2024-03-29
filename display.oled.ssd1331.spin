{
---------------------------------------------------------------------------------------------------
    Filename:       display.oled.ssd1331.spin
    Description:    Driver for Solomon Systech SSD1331 RGB OLED displays
    Author:         Jesse Burt
    Started:        Apr 28, 2019
    Updated:        Feb 2, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}
#define MEMMV_NATIVE wordmove
#include "graphics.common.spinh"

CON

    { /// default I/O settings; these can be overridden in the parent object }
    { display dimensions }
    WIDTH       = 96
    HEIGHT      = 64
    { SPI }
    CS          = 0
    SCK         = 1
    MOSI        = 2
    DC          = 3
    RST         = 4
    SPI_FREQ    = 6_666_666
    BPP         = 16                            ' bits per pixel/color depth of the display
    { /// }


    BYTESPERPX  = 1 #> (BPP/8)                  ' limit to minimum of 1
    BPPDIV      = 1 #> (8 / BPP)                ' limit to range 1 .. (8/BPP)
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2
    BUFF_SZ     = (WIDTH * HEIGHT) / BPPDIV
    MAX_COLOR   = (1 << BPP)-1


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


OBJ

    core:   "core.con.ssd1331"                  ' HW-specific constants
    time:   "time"                              ' timekeeping methods
    spi:    "com.spi.20mhz"                     ' SPI engine

VAR

    { I/O pins }
    long _CS, _DC, _RES

#ifndef GFX_DIRECT
    word _framebuffer[BUFF_SZ]
#endif

    { shadow registers }
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG[3], _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_PWRSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL, _sh_FILL

PUB null()
' This is not a top-level object

PUB start(): status
' Start the driver using default I/O settings
#ifdef GFX_DIRECT
    return startx(CS, SCK, MOSI, DC, RST, WIDTH, HEIGHT, 0)
#else
    return startx(CS, SCK, MOSI, DC, RST, WIDTH, HEIGHT, @_framebuffer)
#endif


PUB startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, DISP_W, DISP_H, ptr_drawbuff): status
' Start using custom I/O settings
'   RES_PIN optional, but recommended (pin # only validated in reset())
    if ( lookdown(CS_PIN: 0..31) and lookdown(DC_PIN: 0..31) and lookdown(DIN_PIN: 0..31) and ...
        lookdown(CLK_PIN: 0..31) )
        if ( status := spi.init(CLK_PIN, DIN_PIN, -1, core.SPI_MODE) )
            _CS := CS_PIN
            _DC := DC_PIN
            _RES := RES_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 1
            dira[_DC] := 1
            reset()
            set_dims(DISP_W, DISP_H)
            set_address(ptr_drawbuff)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop()
' Turn off display, stop SPI engine, clear out variable space
    visibility(ALL_OFF)
    powered(FALSE)
    spi.deinit()
    dira[_CS] := 0
    dira[_DC] := 0
    if ( lookdown(_RES: 0..31) )
        dira[_RES] := 0

    longfill(@_CS, 0, 3)
    longfill(@_ptr_drawbuffer, 0, 14)           ' graphics.common.spinh
    wordfill(@_charpx_xmax, 0, 4)               ' graphics.common.spinh
    bytefill(@_charcell_w, 0, 6)                ' graphics.common.spinh
    bytefill(@_sh_SETCOLUMN, 0, 26)

PUB defaults()
' Factory default settings
#ifdef HAS_RESET
    reset()
#else
    visibility(ALL_OFF)
    disp_start_line(0)
    disp_lines(64)
    ext_supply_ena()
    clk_freq(956)
    clk_div(1)
    contrast(127)
    powered(TRUE)
    draw_area(0, 0, 95, 63)
    clear()
    visibility(NORMAL)
#endif

PUB preset_96x64()
' Preset: 96px wide, setup for 64px height
    visibility(ALL_OFF)
    color_depth(COLOR_65K)
    powered(FALSE)
    disp_lines(64)
    ext_supply_ena()
    clk_freq(956)
    clk_div(1)
    contrast(127)
    interlace_ena(false)
    powered(TRUE)
    draw_area(0, 0, 95, 63)
    clear()
    visibility(NORMAL)

PUB preset_96x64_hi_perf()
' Preset: 96px wide, setup for 64px height, display osc. set to max clock
    visibility(ALL_OFF)
    color_depth(COLOR_65K)
    powered(FALSE)
    disp_lines(64)
    ext_supply_ena()
    clk_freq(980)
    clk_div(1)
    contrast(127)
    interlace_ena(false)
    powered(TRUE)
    draw_area(0, 0, 95, 63)
    clear()
    visibility(NORMAL)

PUB preset_96x()
' Preset: 96px wide, determine settings for height at runtime
    visibility(ALL_OFF)
    color_depth(COLOR_65K)
    powered(FALSE)
    disp_lines(_disp_height)
    ext_supply_ena()
    clk_freq(956)
    clk_div(1)
    contrast(127)
    interlace_ena(false)
    powered(TRUE)
    draw_area(0, 0, _disp_width, _disp_height)
    clear()
    visibility(NORMAL)

PUB addr_mode(mode): curr_mode
' Set display internal addressing mode
'   Valid values:
'       HORIZ (0): Horizontal addressing mode
'       VERT (1): Vertical addressing mode
    curr_mode := _sh_REMAPCOLOR
    case mode
        HORIZ, VERT:
        other:
            return ((curr_mode >> core.ADDRINC) & 1)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.SEGREMAP_MASK) | mode)
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

#ifdef GFX_DIRECT
PUB bitmap(ptr_bmap, xs, ys, bm_wid, bm_lns) | offs, nr_pix
' Display bitmap
'   ptr_bmap: pointer to bitmap data
'   (xs, ys): upper-left corner of bitmap
'   bm_wid: width of bitmap, in pixels
'   bm_lns: number of lines in bitmap
    draw_area(xs, ys, xs+(bm_wid-1), ys+(bm_lns-1))
    outa[_CS] := 0
    ' calc total number of pixels to write, based on dims and color depth
    ' clamp to a minimum of 1 to avoid odd behavior
    nr_pix := 1 #> ((xs + bm_wid-1) * (ys + bm_lns-1) * BYTESPERPX)

    outa[_DC] := core.DATA
    spi.wrblock_lsbf(ptr_bmap, nr_pix)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB box(sx, sy, ex, ey, color, filled) | tmp[3]
' Draw a box
'   sx, sy: Start coordinates
'   ex, ey: End coordinates
'   color:  Box color
'   filled: Flag to set whether to fill the box or not
    sx := 0 #> sx <# _disp_xmax
    sy := 0 #> sy <# _disp_ymax
    ex := sx #> ex <# _disp_xmax
    ey := sy #> ey <# _disp_ymax

    if ( ||(filled) <> (_sh_FILL & 1) )         ' only call this if the filled
        if (filled)                             '  param is different than the
            fill_accel_ena(TRUE)                '  current filled setting
        else                                    '  to avoid having to sending
            fill_accel_ena(FALSE)               '  it to the display every time

    { start, end coords }
    tmp.byte[0] := sx
    tmp.byte[1] := sy
    tmp.byte[2] := ex
    tmp.byte[3] := ey

    { fg color - left-justified }
    tmp.byte[4] := ((color & $f800) >> 11) << 1 ' R LSB is don't care
    tmp.byte[5] := (color & $07e0) >> 5
    tmp.byte[6] := (color & $1f) << 1           ' B LSB is don't care

    { bg color - left-justified }
    tmp.byte[7] := ((color & $f800) >> 11) << 1 ' R LSB is don't care
    tmp.byte[8] := (color & $07e0) >> 5
    tmp.byte[9] := (color & $1f) << 1           ' B LSB is don't care
    writereg(core.DRAWRECT, 10, @tmp)
#endif

#ifdef GFX_DIRECT
PUB clear() | tmp
' Clear the display
    tmp.byte[0] := 0
    tmp.byte[1] := 0
    tmp.byte[2] := _disp_xmax
    tmp.byte[3] := _disp_ymax
    writereg(core.CLEAR, 4, @tmp)

#else

PUB clear()
' Clear the display buffer
    wordfill(_ptr_drawbuffer, _bgcolor, _buff_sz/2)
#endif

PUB clk_div(divider): curr_div
' Set clock frequency divider used by the display controller
'   Valid values: 1..16
'   Any other value returns the current setting
    curr_div := _sh_CLK
    case divider
        1..16:
            divider -= 1
        other:
            return ((curr_div & core.CLKDIV_BITS) + 1)

    _sh_CLK := ((_sh_CLK & core.CLKDIV_MASK) | divider)
    writereg(core.CLKDIV_FRQ, 1, @_sh_CLK)

PUB clk_freq(freq): curr_freq
' Set display internal oscillator frequency, in kHz
'   Valid values: 800..980, in steps of 12
'   Any other value returns the current setting
    curr_freq := _sh_CLK
    case freq
        800..980:
            freq := ((freq-800) / 12) << core.FOSCFREQ
        other:
            curr_freq := (curr_freq >> core.FOSCFREQ) & core.FOSCFREQ_BITS
            return (curr_freq * 12) + 800

    _sh_CLK := ((_sh_CLK & core.FOSCFREQ_MASK) | freq)
    writereg(core.CLKDIV_FRQ, 1, @_sh_CLK)

PUB color_depth(format): curr_fmt
' Set expected color format of pixel data
'   Valid values:
'       COLOR_256 (0): 8-bit/256 color
'       COLOR_65K (1): 16-bit/65536 color format 1
'       COLOR_65K2 (2): 16-bit/65536 color format 2
'   Any other value returns the current setting
    curr_fmt := _sh_REMAPCOLOR
    case format
        COLOR_256, COLOR_65K, COLOR_65K2:
            format <<= core.COLORFMT
        other:
            return curr_fmt >> core.COLORFMT

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.COLORFMT_MASK) | format)
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB contrast(level)
' Set display contrast/brightness
'   Valid values: 0..255
'   Any other value returns the current setting
    contrast_a(level)
    contrast_b(level)
    contrast_c(level)

PUB contrast_a(level): curr_lvl
' Set contrast/brightness level of subpixel A
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_A := level
            writereg(core.CONTRASTA, 1, @_sh_SETCONTRAST_A)
        other:
            return _sh_SETCONTRAST_A

PUB contrast_b(level): curr_lvl
' Set contrast/brightness level of subpixel B
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_B := level
            writereg(core.CONTRASTB, 1, @_sh_SETCONTRAST_B)
        other:
            return _sh_SETCONTRAST_B

PUB contrast_c(level): curr_lvl
' Set contrast/brightness level of subpixel C
'   Valid values: 0..255
'   Any other value returns the current setting
    case level
        0..255:
            _sh_SETCONTRAST_C := level
            writereg(core.CONTRASTC, 1, @_sh_SETCONTRAST_C)
        other:
            return _sh_SETCONTRAST_C

#ifdef GFX_DIRECT
PUB copy(sx, sy, ex, ey, dx, dy) | tmp[2]
' Use the display's accelerated Copy Region function
'   Valid values:
'       sx, ex, dx: 0..95 (clamped to range)
'       sy, ey, dy: 0..63 (clamped to range)
    tmp.byte[0] := 0 #> sx <# 95
    tmp.byte[1] := 0 #> sy <# 63
    tmp.byte[2] := 0 #> ex <# 95
    tmp.byte[3] := 0 #> ey <# 63
    tmp.byte[4] := 0 #> dx <# 95
    tmp.byte[5] := 0 #> dy <# 63
    writereg(core.COPY, 6, @tmp)
#endif

PUB copy_invert_ena(state): curr_state
' Enable inverted colors, when using copy()
'   NOTE: This only affects the accelerated/direct-draw variant of copy()
    curr_state := _sh_FILL
    case ||(state)
        0, 1:
            state := ||(state) << core.REVCOPY
        other:
            return (((curr_state >> core.REVCOPY) & 1) == 1)

    _sh_FILL := ((_sh_FILL & core.REVCOPY_MASK) | state)
    writereg(core.FILLCPY, 1, @_sh_FILL)

PUB current_limit(divisor)
' Set master current limit divisor
    _sh_MASTERCCTRL := ((1 #> divisor <# 16) - 1)
    writereg(core.MASTERCURRENT, 1, @_sh_MASTERCCTRL)

PUB disp_lines(lines)
' Set maximum number of display lines
'   Valid values: 16..64 (clamped to range)
    _sh_MULTIPLEX := ((16 #> lines <# 64) - 1)
    writereg(core.SETMULTIPLEX, 1, @_sh_MULTIPLEX)

PUB disp_offset(lines)
' Set display offset/vertical shift
    _sh_DISPOFFSET := (0 #> lines <# 63)
    writereg(core.DISPLAYOFFSET, 1, @_sh_DISPOFFSET)

PUB disp_start_line(line)
' Set display start line
    _sh_DISPSTARTLINE := (0 #> line <# 63)
    writereg(core.STARTLINE, 1, @_sh_DISPSTARTLINE)

PUB draw_area(sx, sy, ex, ey) | tmp
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..95
'       sy, ey: 0..63
'   Any other value will be ignored
    ifnot (lookup(sx: 0..95) or lookup(sy: 0..63) or lookup(ex: 0..95) or lookup(ey: 0..63))
        return

    tmp.byte[0] := sx
    tmp.byte[1] := ex

    writereg(core.SETCOLUMN, 2, @tmp)

    tmp.byte[0] := sy
    tmp.byte[1] := ey

    writereg(core.SETROW, 2, @tmp)

PUB ext_supply_ena() | tmp

    tmp := core.MASTERCFG_EXT_VCC
    writereg(core.SETMASTER, 1, @tmp)

PUB fill_accel_ena(state)
' Enable the display's native/accelerated fill function, when using box()
    _sh_FILL := ((_sh_FILL & core.FILL_MASK) | ((state <> 0) & 1))
    writereg(core.FILLCPY, 1, @_sh_FILL)

PUB interlace_ena(state)
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (non-zero), FALSE (0)
    { invert logic for COMSPLIT bit }
    state := ((((state <> 0) & 1) ^ 1) << core.COMSPLIT)
    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.COMSPLIT_MASK) | state)
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB invert_colors(state) | tmp
' Invert display colors
    if (state)
        visibility(INVERTED)
    else
        visibility(NORMAL)

#ifdef GFX_DIRECT
PUB line(sx, sy, ex, ey, color) | tmp[2]
' Draw line from sx, sy to ex, ey, in color
    sx := 0 #> sx <# _disp_xmax
    sy := 0 #> sy <# _disp_ymax
    ex := 0 #> ex <# _disp_xmax
    ey := 0 #> ey <# _disp_ymax

    tmp.byte[0] := sx
    tmp.byte[1] := sy
    tmp.byte[2] := ex
    tmp.byte[3] := ey
    tmp.byte[4] := ((color & $f800) >> 11) << 1 ' R LSB is don't care
    tmp.byte[5] := (color & $07e0) >> 5
    tmp.byte[6] := (color & $1f) << 1           ' B LSB is don't care
    writereg(core.DRAWLINE, 7, @tmp)
#endif

PUB mirror_h(state): curr_state
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := ||(state) << core.SEGREMAP
        other:
            return ((curr_state >> core.SEGREMAP) & 1) == 1

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.SEGREMAP_MASK | state))
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB mirror_v(state): curr_state
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := ||(state) << core.COMREMAP
        other:
            return ((curr_state >> core.COMREMAP) & 1) == 1

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.COMREMAP_MASK) | state)
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB phase1_period(clks)
' Set discharge/phase 1 period, in display clocks
'   Valid values: 1..15 (clamped to range)
    _sh_PHASE12PER := ((_sh_PHASE12PER & core.PHASE1_MASK) | (1 #> clks <# 15))
    writereg(core.PRECHG, 1, @_sh_PHASE12PER)

PUB phase2_period(clks)
' Set charge/phase 2 period, in display clocks
'   Valid values: 1..15 (clamped to range)
    _sh_PHASE12PER := ((_sh_PHASE12PER & core.PHASE2_MASK) | ((1 #> clks <# 15) << core.PHASE2))
    writereg(core.PRECHG, 1, @_sh_PHASE12PER)

PUB plot(x, y, color) | tmpx, tmpy
' Plot pixel at (x, y) in color
    if (x < 0 or x > _disp_xmax) or (y < 0 or y > _disp_ymax)
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
    tmpx.byte[0] := x
    tmpx.byte[1] := x
    tmpy.byte[0] := y
    tmpy.byte[1] := y

    writereg(core.SETCOLUMN, 2, @tmpx)
    writereg(core.SETROW, 2, @tmpy)

    outa[_DC] := DATA
    outa[_CS] := 0
    { color_depth(COLOR_65K) }
    spi.wr_byte(color.byte[1])
    spi.wr_byte(color.byte[0])

    { color_depth(COLOR_65K2) }
'    spi.wr_byte(rgb565_r5(color) << 1)
'    spi.wr_byte(rgb565_g5(color))
'    spi.wr_byte(rgb565_b5(color) << 1)
    outa[_CS] := 1
#else
' buffered display
    word[_ptr_drawbuffer][x + (y * _disp_width)] := color
#endif

#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return word[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB power_saving_ena(state)
' Enable display power saving mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    state := lookupz(((state <> 0) & 1): core.PWRSAVE_DIS, core.PWRSAVE_ENA)
    _sh_PWRSAVE := state
    writereg(core.PWRMODE, 1, @_sh_PWRSAVE)

PUB powered(state)
' Enable display power
    case ||(state)
        OFF, ON, DIM:
            state := lookupz(||(state): core.DISPLAYOFF, ...
                                        core.DISPLAYON, ...
                                        core.DISPLAYONDIM )
            _sh_DISPONOFF := state
            command(_sh_DISPONOFF)
        other:
            return

PUB precharge_lvl(level)
' Set first pre-charge voltage level (phase 2) of segment pins, in millivolts
'   Valid values: 100..500 (clamped to range)
    level := (((100 #> level <# 500) * 10) - 100_0) / 12_9
    _sh_PRECHGLEV := level << core.PRECHG_LVL
    writereg(core.PRECHGLVL, 1, @_sh_PRECHGLEV)

PUB precharge_speed(seg_a, seg_b, seg_c) | tmp[2]

    _sh_SECPRECHG[0] := 0 #> seg_a <# 255
    _sh_SECPRECHG[1] := 0 #> seg_b <# 255
    _sh_SECPRECHG[2] := 0 #> seg_c <# 255

    tmp.byte[0] := seg_a
    tmp.byte[1] := core.PRECHGB
    tmp.byte[2] := seg_b
    tmp.byte[3] := core.PRECHGC
    tmp.byte[4] := seg_c
    writereg(core.PRECHGA, 5, @tmp)

PUB reset()
' Reset the display controller
    if lookdown(_RES: 0..31)
        dira[_RES] := 1
        outa[_RES] := 1
        outa[_RES] := 0
        time.usleep(core.T_RES)
        outa[_RES] := 1
        time.usleep(core.T_RES_COMPLT)

PUB scroll_fwid_right_cont(sy, ey, xstep, dly) | byte cmd_pkt[5]
' Scroll a full-width vertical region of the display right, continuously
'   (sy, ey): vertical region to scroll (sy: 0..95, ey: 0..63)
'   xstep: number of columns/pixels to scroll horizontally in each step
'   ystep: number of rows/pixels to scroll vertically in each step
'   dly: inter-scroll step delay, in frames (6, 10, 100, 200)
'   NOTE: ey must be greater than or equal to sy
'   NOTE: scrolling is continuous, until stopped by calling scroll_stop()
    scroll_stop()
    cmd_pkt[0] := xstep
    cmd_pkt[1] := sy
    cmd_pkt[2] := ( (sy #> ey) - sy) + 1
    cmd_pkt[3] := 0
    cmd_pkt[4] := lookdownz(dly: 6, 10, 100, 200)
    writereg(core.SCROLLSETUP, 5, @cmd_pkt)
    command(core.SCROLLSTART)

PUB scroll_fwid_right_up_cont(sy, ey, xstep, ystep, dly) | byte cmd_pkt[5]
' Scroll a full-width vertical region of the display up and right, continuously
'   (sy, ey): vertical region to scroll (sy: 0..95, ey: 0..63)
'   xstep: number of rows/pixels to horizontally scroll vertical region in each step
'   ystep: number of rows/pixels to scroll vertically in each step
'   dly: inter-scroll step delay, in frames (6, 10, 100, 200)
'   NOTE: ey must be greater than or equal to sy
'   NOTE: scrolling is continuous, until stopped by calling scroll_stop()
    scroll_stop()
    cmd_pkt[0] := xstep
    cmd_pkt[1] := sy
    cmd_pkt[2] := ( (sy #> ey) - sy) + 1
    cmd_pkt[3] := ystep
    cmd_pkt[4] := lookdownz(dly: 6, 10, 100, 200)
    writereg(core.SCROLLSETUP, 5, @cmd_pkt)
    command(core.SCROLLSTART)

PUB scroll_stop()
' Stop a running scroll command
    command(core.SCROLLSTOP)

PUB show()
' Write the current display buffer to the display
#ifndef GFX_DIRECT
    { buffered displays only }
    outa[_DC] := DATA
    outa[_CS] := 0
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)
    outa[_CS] := 1
#endif

PUB subpix_order(order)
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
    order := ((RGB #> order <# BGR) << core.SUBPIX_ORDER)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core.SUBPIX_ORDER_MASK) | order)
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB vcomh_voltage(level): curr_lvl
' Set COM output voltage, in millivolts
'   Valid values: 440, 520, 610, 710, 830
'   Any other value returns the current setting
    case level
        440, 520, 610, 710, 830:
            level := lookdown(level: 440, 520, 610, 710, 830)
            _sh_VCOMH := lookup(level: $00, $10, $20, $30, $3E)
            writereg(core.VCOMH, 1, @_sh_VCOMH)
        other:
            curr_lvl := lookdown(_sh_VCOMH: $00, $10, $20, $30, $3E)
            return lookup(curr_lvl: 440, 520, 610, 710, 830)

PUB vert_alt_scan(state)
' Alternate Left-Right, Right-Left scanning, every other display line
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    state := ||(state) << core.COMLR_SWAP
    _sh_REMAPCOLOR := ( (_sh_REMAPCOLOR & core.COMLR_SWAP_MASK) | ...
                        (((state <> 0) & 1) << core.COMLR_SWAP) )
    writereg(core.SETREMAP, 1, @_sh_REMAPCOLOR)

PUB visibility(mode): curr_mode
' Set display visibility
    case mode
        NORMAL, ALL_ON, ALL_OFF, INVERTED:
            _sh_DISPMODE := mode + core.NORMALDISPLAY
            command(_sh_DISPMODE)
        other:
            curr_mode := _sh_DISPMODE
            return (_sh_DISPMODE - core.NORMALDISPLAY)

PUB wr_buffer(ptr_buff, len)
' Write alternate buffer to display
    outa[_DC] := DATA
    outa[_CS] := 0
    spi.wrblock_lsbf(ptr_buff, len)
    outa[_CS] := 1

PRI command(c)
' Issue a command with no parameters to the display
    outa[_DC] := CMD
    outa[_CS] := 0
    spi.wr_byte(c)
    outa[_CS] := 1

#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    wordfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), val, count)
#endif

PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes from ptr_buff to device
    case reg_nr
        { commands with parameters }
        $15, $21..$27, $75, $81..$83, $87, $8A..$8C, $A0..$A2, $A8, {
}       $AD, $B0, $B1, $B3, $BB, $E3:
            outa[_DC] := CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return
        other:
            return

DAT
{
Copyright 2024 Jesse Burt

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

