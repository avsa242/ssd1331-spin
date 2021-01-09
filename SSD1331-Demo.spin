{
    --------------------------------------------
    Filename: SSD1331-Demo.spin
    Description: Demo of the SSD1331 driver
    Author: Jesse Burt
    Copyright (c) 2021
    Started: Nov 3, 2019
    Updated: Jan 9, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    RES_PIN     = 4
    DC_PIN      = 3
    CS_PIN      = 2
    CLK_PIN     = 1
    DIN_PIN     = 0
' --

    WIDTH       = 96
    HEIGHT      = 64
    BPP         = 2
    BPL         = WIDTH * BPP
    BUFFSZ      = (WIDTH * HEIGHT) * 2  'in BYTEs - 12288
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

OBJ

    cfg         : "core.con.boardcfg.activityboard"
    ser         : "com.serial.terminal.ansi"
    time        : "time"
    oled        : "display.oled.ssd1331.spi.spin"
    int         : "string.integer"
    fnt         : "font.5x8"

VAR

    long _stack_timer[50]
    long _timer_set
    long _rndseed
    byte _framebuff[BUFFSZ]
    byte _timer_cog

PUB Main{} | time_ms, r

    setup{}
    oled.clearall{}

    oled.mirrorh(FALSE)
    oled.mirrorv(FALSE)

    demo_greet{}
    time.sleep(5)
    oled.clearall{}

    time_ms := 5_000

    ser.position(0, 3)

    demo_sinewave(time_ms)
    oled.clearall{}

    demo_triwave(time_ms)
    oled.clearall{}

    demo_memscroller(time_ms, $0000, $FFFF-BUFFSZ)
    oled.clearall{}

    demo_bitmap(time_ms, $8000)
    oled.clearall{}

    demo_box(time_ms)
    oled.clearall{}

    demo_boxfilled(time_ms)
    oled.clearall{}

    demo_linesweepx(time_ms)
    oled.clearall{}

    demo_linesweepy(time_ms)
    oled.clearall{}

    demo_line(time_ms)
    oled.clearall{}

    demo_plot(time_ms)
    oled.clearall{}

    demo_bouncingball(time_ms, 5)
    oled.clearall{}

    demo_circle(time_ms)
    oled.clearall{}

    demo_wander(time_ms)
    oled.clearall{}

    demo_seqtext(time_ms)
    oled.clearall{}

    demo_rndtext(time_ms)

    demo_contrast(2, 1)
    oled.clearall{}

    stop{}
    repeat

PUB Demo_Bitmap(testtime, ptr_bitmap) | iteration
' Continuously redraws bitmap at address ptr_bitmap
    ser.str(string("Demo_Bitmap - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        oled.bitmap(ptr_bitmap, BUFFSZ, 0)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_BouncingBall(testtime, radius) | iteration, bx, by, dx, dy
' Draws a simple ball bouncing off screen edges
    bx := (rnd(XMAX) // (WIDTH - radius * 4)) + radius * 2  'Pick a random screen location to
    by := (rnd(YMAX) // (HEIGHT - radius * 4)) + radius * 2 ' start from
    dx := rnd(4) // 2 * 2 - 1                               'Pick a random direction to
    dy := rnd(4) // 2 * 2 - 1                               ' start moving

    ser.str(string("Demo_BouncingBall - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1

        oled.circle(bx, by, radius, $FFFF)
        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)
    return iteration

PUB Demo_Box (testtime) | iteration, c
' Draws random lines
    ser.str(string("Demo_Box - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.box(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, FALSE)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_BoxFilled (testtime) | iteration, c, x1, y1, x2, y2
' Draws random lines
    ser.str(string("Demo_BoxFilled - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.box(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c, TRUE)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_Circle(testtime) | iteration, x, y, r, c
' Draws circles at random locations
    ser.str(string("Demo_Circle - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX/2)
        c := rnd(oled#MAX_COLOR)
        oled.circle(x, y, r, c)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_Contrast(reps, delay_ms) | contrast_level
' Fades out and in display contrast
    ser.str(string("Demo_Contrast - N/A"))

    repeat reps
        repeat contrast_level from 255 to 1
            oled.contrast(contrast_level)
            time.msleep(delay_ms)
        repeat contrast_level from 0 to 254
            oled.contrast(contrast_level)
            time.msleep(delay_ms)

    ser.newline{}

PUB Demo_Greet{}
' Display the banner/greeting on the OLED
    oled.fgcolor($FFFF)
    oled.bgcolor(0)
    oled.position(0, 0)
    oled.strln(string("SSD1331 on the"))
    oled.strln(string("Parallax"))
    oled.printf1(string("P8X32A @ %dMHz\n"), clkfreq/1_000_000)
    oled.printf2(string("%dx%d"), WIDTH, HEIGHT)
    oled.update{}

PUB Demo_Line(testtime) | iteration, c
' Draws random lines with color -1 (invert)
    ser.str(string("Demo_Line - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.line(rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), c)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_LineSweepX(testtime) | iteration, x
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    x := 0

    ser.str(string("Demo_LineSweepX - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        x++
        if x > XMAX
            x := 0
        oled.line(x, 0, XMAX-x, YMAX, x)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_LineSweepY(testtime) | iteration, y
' Draws lines top left to lower-right, sweeping across the screen, then
'  from the top-down
    y := 0

    ser.str(string("Demo_LineSweepY - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        y++
        if y > YMAX
            y := 0
        oled.line(XMAX, y, 0, YMAX-y, y)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_MEMScroller(testtime, start_addr, end_addr) | iteration, pos
' Dumps Propeller Hub RAM (and/or ROM) to the display buffer
    pos := start_addr

    ser.str(string("Demo_MEMScroller - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        pos += BPL
        if pos > end_addr
            pos := start_addr
        oled.bitmap(pos, BUFFSZ, 0)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_Plot(testtime) | iteration, x, y, c
' Draws random pixels to the screen, with color -1 (invert)
    ser.str(string("Demo_Plot - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        c := rnd(oled#MAX_COLOR)
        oled.plot(rnd(XMAX), rnd(YMAX), c)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_Sinewave(testtime) | iteration, x, y, modifier, offset, div
' Draws a sine wave the length of the screen, influenced by the system counter
    ser.str(string("Demo_Sinewave - "))

    div := 3072
    offset := YMAX/2                                    ' Offset for Y axis

    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            modifier := (||(cnt) / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.plot(x, y, $FFFF)

        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)
    return iteration

PUB Demo_SeqText(testtime) | iteration, ch
' Sequentially draws the whole font table to the screen, then random characters
    ser.str(string("Demo_SeqText - "))
    _timer_set := testtime
    iteration := 0
    oled.position(0, 0)
    oled.fgcolor(65535)
    oled.bgcolor(0)
    ch := 32
    repeat while _timer_set
        ch++
        if ch > 127
            ch := 32
        oled.char(ch)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_RndText(testtime) | iteration, ch

    oled.FGColor(1)
    oled.BGColor(0)

    ser.str(string("Demo_RndText - "))
    _timer_set := testtime
    iteration := 0
    oled.position(0, 0)
    ch := 32
    repeat while _timer_set
        oled.fgcolor(rnd(65535))
        oled.bgcolor(rnd(65535))
        oled.char(0 #> rnd(127))
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB Demo_TriWave(testtime) | iteration, x, y, ydir
' Draws a simple triangular wave
    ydir := 1
    y := 0

    ser.str(string("Demo_TriWave - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        repeat x from 0 to XMAX
            if y == YMAX
                ydir := -1
            if y == 0
                ydir := 1
            y := y + ydir
            oled.Plot (x, y, $FFFF)
        oled.update{}
        iteration++
        oled.clear{}

    report(testtime, iteration)
    return iteration

PUB Demo_Wander(testtime) | iteration, x, y, d, c
' Draws randomly wandering pixels
    _rndseed := cnt
    x := XMAX/2
    y := YMAX/2

    ser.str(string("Demo_Wander - "))
    _timer_set := testtime
    iteration := 0

    repeat while _timer_set
        case d := rnd(4)
            1:
                x += 2
                if x > XMAX
                    x := 0
            2:
                x -= 2
                if x < 0
                    x := XMAX
            3:
                y += 2
                if y > YMAX
                    y := 0
            4:
                y -= 2
                if y < 0
                    y := YMAX
        c := rnd(oled#MAX_COLOR)
        oled.plot(x, y, c)
        oled.update{}
        iteration++

    report(testtime, iteration)
    return iteration

PUB RND(max_val) | i
' Returns a random number between 0 and max_val
    return ||(?_rndseed) // max_val

PUB Sin(angle): sine
' Sin angle is 13-bit; Returns a 16-bit signed value
    sine := angle << 1 & $FFE
    if angle & $800
       sine := word[$F000 - sine]
    else
       sine := word[$E000 + sine]
    if angle & $1000
       -sine

PRI Report(testtime, iterations)

    ser.printf2(string("Total iterations: %d, iterations/sec: %d, ms/iteration: "),{
}   iterations, iterations / (testtime/1000))
    decimal((testtime * 1_000) / iterations, 1_000)
    ser.newline{}

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp
' Display a fixed-point scaled up number in decimal-dot notation - scale it back down by divisor
'   e.g., Decimal (314159, 100000) would display 3.14159 on the termainl
'   scaled: Fixed-point scaled up number
'   divisor: Divide scaled-up number by this amount
    whole := scaled / divisor
    tmp := divisor
    places := 0

    repeat
        tmp /= 10
        places++
    until tmp == 1
    part := int.deczeroed(||(scaled // divisor), places)

    ser.dec(whole)
    ser.char(".")
    ser.str(part)

PRI cog_Timer{} | time_left

    repeat
        repeat until _timer_set
        time_left := _timer_set

        repeat
            time_left--
            time.msleep(1)
        while time_left > 0
        _timer_set := 0

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if oled.start(CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN, @_framebuff)
        ser.strln(string("SSD1331 driver started"))
        oled.fontaddress(fnt.baseaddr{})
        oled.fontscale(1)
        oled.fontsize(6, 8)
        oled.defaultscommon{}
        oled.clearall{}
    else
        ser.strln(string("SSD1331 driver failed to start - halting"))
        stop{}

    _timer_cog := cognew(cog_timer{}, @_stack_timer)

PUB Stop{}

    oled.powered(FALSE)
    oled.stop{}
    cogstop(_timer_cog)

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
