{
    --------------------------------------------
    Filename: SSD1331-Demo.spin
    Author: Jesse Burt
    Description: Simple demo for the SSD1331 driver
    Copyright (c) 2019
    Started Nov 3, 2019
    Updated Dec 7, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    RES_PIN     = 4
    DC_PIN      = 3
    CS_PIN      = 2
    CLK_PIN     = 1
    DIN_PIN     = 0

    WIDTH       = 96
    HEIGHT      = 64
    BPP         = 16
    BPL         = WIDTH * (BPP/8)
    BUFFSZ      = (WIDTH * HEIGHT) * 2  'in BYTEs - 12288
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

    BT_FRAME    = 0
    BT_UNIT     = 1

OBJ

    cfg     : "core.con.boardcfg.activityboard"
    ser     : "com.serial.terminal"
    time    : "time"
    io      : "io"
    oled    : "display.oled.ssd1331.spi.spin"
    int     : "string.integer"

VAR

    long _rndseed
    long _a_min, _a_max, _a_range
    long _b_min, _b_max, _b_range
    long _c_min, _c_max, _c_range
    long _d_min, _d_max, _d_range
    long _bench_iter, _bench_iter_stack[50]
    word _framebuff[BUFFSZ/2]
    byte _ser_cog, _oled_cog, _bench_cog
    byte _bench_type

PUB Main

    Setup
    oled.ClockDiv(1)
    oled.ClockFreq(15)
    oled.AddrIncMode (oled#ADDR_HORIZ)
    oled.MirrorH (FALSE)
    oled.SubpixelOrder (oled#SUBPIX_RGB)
    oled.VertAltScan (FALSE)
    oled.MirrorV (FALSE)
    oled.Interlaced (FALSE)
    oled.ColorDepth (oled#COLOR_65K)
    oled.ClearAll
    oled.Fill(TRUE)

    oled.AllPixelsOff
    oled.Bitmap(@splash, 12224, 0)
    oled.Update
    oled.Contrast (0)
    oled.DispInverted (FALSE)
    Demo_FadeIn (1, 10)
    time.Sleep (3)
    Demo_FadeOut (1, 10)
    oled.ClearAll
    oled.Contrast (127)

    ser.Str(string("Demo_MEMScroller"))
    Demo_MEMScroller ($0000, $FFFF)
    time.Sleep(2)
    oled.ClearAll

    ser.Str(string("Demo_Circle"))
    Demo_Circle (100)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_Sine"))
    Demo_Sine (500)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_LineAccel"))
    Demo_LineAccel (15_000)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_LineBitmap"))
    Demo_LineBitmap (1_000)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_PlotAccel"))
    Demo_PlotAccel (15_000)
    time.Sleep (2)
    oled.ClearAll

    oled.DisplayBounds(0, 0, 95, 63)    'Need to reset this here because PlotAccel changes it

    ser.Str(string("Demo_PlotBitmap"))
    Demo_PlotBitmap (1000)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_BoxAccel"))
    Demo_BoxAccel(15_000)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_BoxBitmap"))
    Demo_BoxBitmap(500)
    time.Sleep (2)
    oled.ClearAll

    ser.Str(string("Demo_HLineSpectrumAccel"))
    Demo_HLineSpectrumAccel (1)
    time.Sleep (2)

    ser.Str(string("CopyAccel"))
    oled.CopyAccel (0, 0, 20, 20, 20, 20)
    time.Sleep (2)

    ser.Str(string("Demo_FadeOut"))
    Demo_FadeOut (1, 30)

    ser.Str(string("AllPixelsOff"))
    oled.AllPixelsOff
    oled.DisplayEnabled (FALSE)
    time.MSleep (5)
    Stop
    FlashLED (LED, 100)

PUB Demo_Sine(reps) | r, x, y, modifier, offset, div
' Draw a sine wave the length of the screen, influenced by
'  the system counter
    div := 2048
    offset := YMAX/2                                    ' Offset for Y axis
    _bench_type := BT_FRAME

    repeat r from 1 to reps
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.Plot (x, y, $FF_FF)
        oled.Update
        _bench_iter++
        oled.Clear

PUB Demo_Bitmap(reps)
' Draw bitmap
    _bench_type := BT_FRAME
    repeat reps
        oled.Bitmap (@splash, BUFFSZ, 0)
        oled.Update
        _bench_iter++

PUB Demo_BoxAccel(reps) | sx, sy, ex, ey, c
' Draw random filled boxes using the display's accelerated method
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
'        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        c := RND (65535)
        oled.BoxAccel (sx, sy, ex, ey, c, c)

PUB Demo_BoxBitmap(reps) | sx, sy, ex, ey, c
' Draw random filled boxes using the bitmap library's method
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Box (sx, sy, ex, ey, c, TRUE)
        oled.Update
        _bench_iter++

PUB Demo_Circle(reps) | r, x, y, c
'' Draws random circles
    _rndseed := cnt
    _bench_type := BT_FRAME
    repeat reps
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Circle (x, y, r, c)
        oled.Update
        _bench_iter++

PUB Demo_FadeIn(reps, delay) | c
' Fade out display
    repeat c from 0 to 127
        oled.Contrast (c)
        time.MSleep (delay)

PUB Demo_FadeOut(reps, delay) | c
' Fade out display
    repeat c from 127 to 0
        oled.Contrast (c)
        time.MSleep (delay)

PUB Demo_HLineSpectrumAccel(reps) | x, c
' Plot spectrum from GetColor using full-height vertical lines, using the display's accelerated method
    _bench_type := BT_UNIT
    repeat reps
        repeat x from 0 to 95
            c := GetColor (x * 689)
            oled.LineAccel (x, 0, x, 63, c)
            _bench_iter++

PUB Demo_LineAccel(reps) | sx, sy, ex, ey, c
' Draw random lines, using the display's accelerated method
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.LineAccel (sx, sy, ex, ey, c)
        _bench_iter++

PUB Demo_LineBitmap(reps) | sx, sy, ex, ey, c
' Draw random lines, using the bitmap library's method
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Line (sx, sy, ex, ey, c)
        oled.Update
        _bench_iter++

PUB Demo_MEMScroller(start_addr, end_addr) | pos, st, en
' Dump Propeller Hub RAM (or ROM) to the framebuffer
    _bench_type := BT_FRAME
    repeat pos from start_addr to end_addr-BUFFSZ step BPL
        wordmove(@_framebuff, pos, BUFFSZ/2)
        oled.Update
        _bench_iter++

PUB Demo_PlotAccel(reps) | x, y, c
' Draw random pixels, using the display's accelerated method
    _bench_type := BT_UNIT
    repeat reps
        x := RND (95)
        y := RND (63)
'        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        c := RND (65535)
        oled.PlotAccel (x, y, c)
        _bench_iter++

PUB Demo_PlotBitmap(reps) | x, y, c
' Draw random pixels, using the bitmap library's method
    _bench_type := BT_UNIT
    repeat reps
        x := RND (95)
        y := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Plot(x, y, c)
        oled.Update
        _bench_iter++

PUB C24to16(rgb888)
' Return 16-bit color word of 24-bit color value
    return (Col_GB (rgb888) << 8) | Col_RG (rgb888)

PUB Col_RG(RGB)
' Return Red-Green component of 16-bit color value
    return (RGB & $FF00) >> 8

PUB Col_GB(RGB)
' Return Green-Blue component of 16-bit color value
    return RGB & $FF

PUB FlashLED(led_pin, delay)
' Flash LED forever
    io.Output(led_pin)
    repeat
        io.Toggle(led_pin)
        time.MSleep (delay)

PUB FPS
' Displays approximation of frame rate on terminal
' Send the _bench_iter value to the terminal once every second, and clear it
    repeat
        time.Sleep (1)
        case _bench_type
            BT_FRAME:
                ser.Position (0, 5)
                ser.Str(string("FPS: "))
                ser.Str (int.DecPadded (_bench_iter, 3))

                ser.Position (0, 6)
                ser.Str(string("Approximate throughput: "))
                ser.Str (int.DecPadded (_bench_iter*12288, 7))
                ser.Str(string("bytes/sec"))

            BT_UNIT:
                ser.Position (0, 5)
                ser.Str(string("Units/sec: "))
                ser.Str (int.DecPadded (_bench_iter, 6))

                ser.Position (0, 6)
                ser.Str(string("Approximate throughput: "))
                ser.Str(string("N/A"))

        _bench_iter := 0

PUB GetColor(val) | red, green, blue, inmax, outmax, divisor, tmp
' Return color from gradient scale, setup by SetColorScale
    inmax := 65535
    outmax := 255
    divisor := inmax / outmax

    case val
        _a_min.._a_max:
            red := 0
            green := 0
            blue := val/divisor
        _b_min.._b_max:
            red := 0
            green := val/divisor
            blue := 255
        _c_min.._c_max:
            red := val/divisor
            green := 255
            blue := 255-(val/divisor)
        _d_min.._d_max:
            red := 255
            green := 255-(val/divisor)
            blue := 0
        OTHER:
' RGB888 format
'    return (red << 16) | (green << 8) | blue

' RGB565 format
    return ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3)

PUB RND(max_val) | i
' Returns a random number between 0 and max_val
    i := ?_rndseed
    i >>= 16
    i *= (max_val + 1)
    i >>= 16

    return i

PUB Sin(angle)
' Sin angle is 13-bit; Returns a 16-bit signed value
    result := angle << 1 & $FFE
    if angle & $800
       result := word[$F000 - result]
    else
       result := word[$E000 + result]
    if angle & $1000
       -result

PUB SetColorScale
' Set up 4-point scale for GetColor
    ser.Str(string("SetColorScale"))
    _a_min := 0
    _a_max := 16383
    _a_range := _a_max - _a_min

    _b_min := _a_max + 1
    _b_max := 32767
    _b_range := _b_max - _b_min

    _c_min := _b_max + 1
    _c_max := 49151
    _c_range := _c_max - _c_min

    _d_min := _c_max + 1
    _d_max := 65535
    _d_range := _d_max - _d_min

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    ser.Clear
    ser.Str(string("Serial terminal started"))
    if _oled_cog := oled.Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN)
        ser.Str(string("SSD1331 driver started "))
        oled.Address(@_framebuff)
        oled.Defaults
    else
        ser.Str(string("SSD1331 driver failed to start - halting"))
        Stop
    SetColorScale
    SwapBMBytes
'    _bench_cog := cognew(fps, @_bench_iter_stack)

PUB Stop

    oled.Stop
    time.MSleep (5)
    if _bench_cog
        cogstop(_bench_cog)

PRI SwapBMBytes| i, tmp
' Reverse the byte order of the bitmap at address 'splash'
' This is required specifically for the Propeller Beanie logo splash bitmap,
'   not required in general.
    ser.Str(string("SwapBMBytes"))
    repeat i from 0 to 12224-1 step 2'12288-1 step 2
        tmp.byte[0] := byte[@splash][i+1]
        tmp.byte[1] := byte[@splash][i]
        byte[@splash][i] := tmp.byte[0]
        byte[@splash][i+1] := tmp.byte[1]


DAT

splash  byte $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $FF, $5C, $FF, $5C, $FF, $7D, $FF
        byte $7D, $FF, $7C, $FF, $9D, $FF, $BE, $FF, $BF, $F7, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $9D, $FF, $7C, $FF, $5C, $FF, $1A, $FF, $98, $FE
        byte $56, $FE, $36, $FE, $35, $FE, $B4, $F5, $31, $F5, $11, $F5, $6E, $F4, $6E, $F4
        byte $CC, $F3, $CD, $F3, $2A, $F3, $2A, $F3, $2A, $F3, $2A, $F3, $2A, $F3, $2A, $F3
        byte $2A, $F3, $2A, $F3, $4B, $F3, $CC, $F3, $2E, $F4, $32, $F5, $93, $FD, $73, $ED
        byte $DB, $EE, $DF, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $3B, $FF, $F6, $FD, $F5, $FD, $15, $FE, $15, $FE, $36, $FE
        byte $36, $FE, $97, $FE, $D9, $FE, $D9, $FE, $FA, $F6, $1A, $FF, $7C, $FF, $3C, $E7
        byte $7D, $EF, $DF, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $DF, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $FF
        byte $9D, $FF, $5C, $FF, $1A, $FF, $57, $FE, $35, $FE, $15, $FE, $93, $FD, $11, $FD
        byte $8F, $F4, $4E, $F4, $ED, $F3, $2A, $F3, $0A, $F3, $2A, $F3, $67, $EA, $67, $EA
        byte $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9
        byte $C5, $E9, $C5, $E9, $C5, $E9, $C5, $E9, $E6, $E9, $88, $EA, $2E, $F4, $4E, $F4
        byte $D1, $CC, $DB, $D6, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $5C, $FF, $D, $F4, $CC, $EB, $6E, $F4, $2D, $F4, $CC, $F3, $CC, $F3 
        byte $AC, $F3, $D, $F4, $8F, $F4, $32, $F5, $72, $F5, $F4, $FD, $15, $FE, $78, $E6
        byte $FB, $EE, $FA, $F6, $FA, $FE, $7C, $FF, $5C, $FF, $1C, $DF, $7D, $EF, $DF, $F7
        byte $DF, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $58, $C7
        byte $F6, $AE, $7E, $DF, $3D, $EF, $7D, $E7, $5B, $FF, $B9, $FE, $16, $FE, $B4, $FD, $8F, $FC, $8F, $FC, $4E, $EC, $8C, $CB, $8C
        byte $DB, $2A, $E3, $C9, $CA, $C8, $DA, $88, $E2, $47, $E2, $E5, $E1, $E5, $F1, $E6, $F1, $E6, $F1, $6, $F2, $E6, $F1, $6, $F2, $6
        Byte $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2,   $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $C5, $E9, $68, $F2, $A8, $FA, $B, $A3, $35
        Byte $9D, $FB, $DE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BA, $EE, $E5, $C9, $88, $F2, $A9, $F2, $47, $EA, $6, $EA, $6, $EA
        Byte $6, $EA, $6, $EA, $27, $EA, $A8, $EA, $C9, $F2, $2A, $F3, $EC, $F3, $4E, $F4, $93, $F5, $52, $F5, $15, $FE, $36, $FE, $B8, $FE, $98, $E6, $1B, $F7, $DA, $F6
        Byte $FA, $F6, $FA, $FE, $1A, $FF, $5C, $FF, $5C, $FF, $5C, $FF, $5C, $FF, $5C, $FF, $5C, $FF, $BD, $FF, $BD, $FF, $9D, $FF, $9D, $FF, $7C, $FF, $17, $FE, $AC, $3D 
        byte $CF, $55, $96, $86, $D0, $95, $4D, $BB, $6C, $CB, $A, $C3, $88, $BA, $84, $89, $E6, $79, $E2, $98, $E2, $88, $C2, $70, $A2, $80, $61, $80, $60, $78, $81, $80 
        byte $C2, $90, $C2, $90, $C2, $88, $3, $91, $64, $B9, $84, $C9, $84, $C1, $E5, $E1, $E5, $E1, $26, $FA, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2 
        byte $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $C5, $F1, $7, $B2, $CF, $8B, $18, $BE, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BA, $EE, $A5, $A9, $C5, $E1, $E6, $F1, $E6, $F1, $6, $F2, $6, $F2 
        byte $6, $F2, $E6, $F1, $E6, $F1, $E6, $E9, $E6, $E9, $C5, $E9, $27, $EA, $26, $EA, $A8, $F2, $A8, $F2, $2A, $F3, $9, $F3, $4E, $F4, $4E, $F4, $6F, $F4, $52, $F5 
        byte $72, $F5, $15, $FE, $15, $FE, $36, $FE, $36, $FE, $36, $FE, $56, $FE, $D4, $FD, $93, $FD, $F1, $FC, $CD, $DB, $8C, $C3, $6C, $C3, $2B, $C3, $AD, $AB, $A7, $2A
        byte $2A, $1C, $8A, $24, $46, $14, $4D, $9B, $CE, $9B, $50, $AC, $30, $A4, $4D, $83, $AE, $73, $EB, $7A, $CB, $72, $69, $6A, $69, $62, $28, $62, $7, $5A, $C7, $51 
        byte $65, $49, $45, $41, $65, $41, $81, $50, $60, $70, $81, $78, $81, $70, $A2, $88, $C2, $88, $3, $91, $84, $C1, $84, $C1, $E6, $E1, $E5, $E1, $26, $FA, $6, $F2 
        byte $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $26, $FA, $E5, $E1, $2, $A1, $85, $79, $8E, $7B, $75, $AD, $3C, $E7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $99, $EE, $2, $B1, $E5, $E1, $6, $F2, $6, $F2, $6, $F2, $6, $F2 
        byte $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $E6, $F1, $E6, $F1, $E6, $E9, $E6, $E9, $E5, $E9, $C5, $E9, $27, $EA, $26, $F2, $27, $F2, $A8, $F2 
        byte $C9, $F2, $A, $FB, $9, $F3, $C9, $E2, $A8, $DA, $47, $C2, $6, $AA, $85, $89, $44, $91, $A5, $79, $69, $6A, $EB, $7A, $6D, $8B, $30, $A4, $55, $AD, $31, $94 
        byte $A6, $B, $86, $3, $2A, $4B, $F0, $7B, $D2, $94, $96, $AD, $D7, $B5, $55, $AD, $34, $A5, $F3, $9C, $D3, $94, $B2, $94, $92, $8C, $51, $84, $30, $84, $30, $84 
        byte $EF, $7B, $CE, $73, $AE, $6B, $2C, $73, $CB, $72, $49, $62, $49, $62, $E7, $51, $66, $39, $20, $58, $61, $70, $61, $70, $A2, $80, $C2, $88, $84, $C1, $64, $C1 
        byte $64, $C1, $84, $C9, $C5, $D9, $64, $B9, $64, $C1, $43, $A9, $A2, $80, $E3, $58, $49, $4A, $AE, $73, $34, $A5, $FB, $E6, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $38, $DE, $0, $60, $23, $99, $6, $F2, $6, $F2, $6, $F2, $6, $F2 
        byte $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $F2, $6, $FA, $C5, $D9, $C5, $E1, $A5, $D9 
        byte $43, $B9, $23, $B1, $81, $80, $81, $80, $61, $78, $40, $70, $C2, $58, $A6, $41, $28, $5A, $EB, $62, $CF, $73, $50, $84, $92, $94, $D3, $94, $55, $AD, $18, $CE 
        byte $AA, $33, $C8, $4, $6E, $7B, $8E, $73, $F3, $9C, $38, $CE, $59, $CE, $9A, $D6, $9A, $D6, $79, $D6, $9A, $D6, $9A, $D6, $59, $CE, $38, $C6, $59, $CE, $17, $C6 
        byte $18, $BE, $18, $C6, $B6, $B5, $96, $AD, $14, $A5, $D3, $9C, $B2, $94, $51, $84, $EF, $73, $4D, $7B, $CB, $6A, $49, $62, $E7, $49, $45, $39, $40, $70, $60, $70 
        byte $61, $70, $81, $70, $81, $78, $61, $70, $61, $70, $40, $68, $24, $59, $49, $4A, $C, $5B, $10, $84, $F7, $BD, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7D, $EF, $2C, $9B, $20, $88, $C2, $88, $A4, $C9, $E5, $E1, $C5, $D9 
        byte $6, $F2, $26, $FA, $26, $FA, $26, $FA, $27, $FA, $E5, $E1, $E5, $E1, $E5, $E1, $E5, $E1, $64, $B9, $64, $B9, $64, $B9, $C2, $78, $A1, $78, $A1, $78, $81, $78 
        byte $60, $70, $A2, $60, $A6, $39, $C7, $41, $28, $52, $49, $5A, $EB, $62, $6D, $6B, $CF, $73, $30, $84, $71, $8C, $F3, $9C, $75, $AD, $F7, $BD, $BA, $DE, $97, $B5 
        byte $B1, $5D, $90, $6E, $4E, $83, $92, $94, $79, $CE, $7D, $EF, $9E, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $BE, $F7, $9E, $F7 
        byte $9E, $F7, $7D, $EF, $3C, $E7, $3C, $E7, $3C, $E7, $DB, $DE, $BA, $D6, $38, $C6, $18, $C6, $96, $AD, $F4, $9C, $F3, $9C, $51, $84, $EF, $7B, $4D, $7B, $EB, $6A 
        byte $69, $5A, $8, $4A, $8, $52, $8, $52, $49, $5A, $8A, $62, $CB, $62, $2C, $63, $EF, $7B, $75, $AD, $FB, $E6, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $5D, $EF, $51, $9C, $4, $49, $20, $68, $81, $70, $81, $70 
        byte $A2, $78, $A2, $78, $A2, $78, $A2, $78, $A2, $78, $81, $70, $81, $70, $81, $78, $81, $70, $61, $68, $61, $68, $40, $68, $40, $60, $C7, $39, $A6, $41, $49, $52 
        byte $49, $52, $CB, $62, $C, $63, $6D, $6B, $8E, $73, $10, $84, $51, $8C, $D3, $9C, $55, $AD, $F7, $BD, $18, $C6, $9A, $D6, $1C, $E7, $BE, $F7, $5D, $F7, $2E, $54 
        byte $4A, $D, $73, $76, $9, $5, $B3, $A4, $BA, $D6, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $BE, $F7, $BE, $F7, $3C, $EF, $3C, $EF, $BA, $D6, $18, $C6, $38, $C6, $76, $AD, $14, $9D 
        byte $F3, $9C, $92, $94, $71, $8C, $51, $8C, $30, $84, $51, $8C, $92, $94, $D3, $9C, $96, $B5, $FB, $DE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $5D, $E7, $35, $AD, $6D, $73, $28, $4A, $A6, $31 
        byte $A2, $50, $4, $49, $A2, $50, $45, $41, $61, $58, $65, $41, $A6, $39, $A6, $39, $49, $52, $49, $52, $49, $4A, $EB, $62, $CB, $62, $8E, $6B, $6D, $6B, $8E, $6B 
        byte $10, $84, $51, $8C, $92, $94, $14, $A5, $96, $B5, $D7, $BD, $79, $D6, $DB, $DE, $1C, $E7, $9E, $F7, $BE, $F7, $BE, $F7, $FF, $FF, $FF, $FF, $DF, $FF, $EB, $3B 
        byte $A6, $B, $6B, $15, $C5, $3, $31, $94, $18, $C6, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $BE, $F7, $5D, $EF, $3C, $E7 
        byte $DB, $DE, $BA, $D6, $38, $C6, $38, $C6, $38, $C6, $38, $C6, $79, $CE, $1C, $E7, $9E, $F7, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $1C, $E7, $D7, $BD, $D3, $9C, $71, $8C 
        byte $10, $84, $10, $84, $8E, $73, $EF, $7B, $8E, $73, $6D, $6B, $10, $7C, $6D, $6B, $10, $7C, $10, $84, $EF, $7B, $71, $8C, $92, $94, $D3, $9C, $55, $AD, $B6, $B5 
        byte $D7, $BD, $79, $CE, $DB, $DE, $1C, $E7, $7D, $EF, $9E, $F7, $DF, $FF, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $A6 
        byte $67, $13, $29, $5, $AA, $2B, $8E, $7B, $96, $B5, $3C, $E7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $DF, $FF, $DF, $FF, $DF, $FF, $DF, $FF, $DF, $FF, $DF, $FF, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $3C, $E7, $BA, $D6, $18, $C6 
        byte $B6, $B5, $D7, $BD, $75, $AD, $34, $A5, $34, $A5, $B6, $B5, $35, $AD, $B6, $B5, $D7, $BD, $B6, $B5, $59, $CE, $59, $CE, $59, $CE, $FB, $E6, $FB, $DE, $7D, $F7 
        byte $9E, $F7, $DF, $FF, $DF, $FF, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7E, $DF, $93, $5D 
        byte $9, $5, $51, $66, $91, $45, $AB, $6A, $96, $B5, $3C, $E7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7 
        byte $7D, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $9E, $F7, $7D, $F7, $FF, $FF, $FF, $FF, $DF, $FF, $DF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D3, $65, $2A, $5 
        byte $29, $5, $51, $4D, $93, $6E, $AA, $2B, $96, $BD, $3C, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $FF, $E8, $1B, $45, $3 
        byte $A, $D, $29, $5, $29, $5, $85, $3, $D4, $A4, $9A, $D6, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D9, $BD, $A8, $13 
        byte $A, $5, $2A, $5, $6A, $5, $A, $62, $31, $84, $18, $C6, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $FF, $9F, $E7, $9F, $E7, $7F, $C7, $DC, $DE, $6B, $85 
        byte $A, $75, $A, $75, $89, $AE, $B4, $9C, $B2, $94, $76, $B5, $1C, $E7, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $F7, $9F, $E7, $3F, $B7, $1F, $9F, $FB, $B6, $1D, $BF, $97, $EF, $D5, $FF, $D7, $FF, $23, $FE 
        byte $62, $FC, $21, $FC, $33, $FD, $F6, $FF, $F7, $FF, $BE, $F7, $9E, $E7, $FC, $B6, $3E, $BF, $FC, $BE, $BF, $E7, $DF, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9F, $D7, $1F, $9F, $BF, $76, $7E, $5E, $DA, $9E, $76, $EF, $AC, $FF, $88, $FF, $AA, $FF, $43, $EF, $61, $F4, $23, $F4 
        byte $63, $F4, $63, $F4, $22, $F4, $80, $FD, $8B, $FF, $89, $FF, $8A, $FF, $D4, $FF, $B5, $F7, $5D, $C7, $1E, $A7, $FE, $A6, $DB, $C6, $3C, $E7, $BE, $F7, $DF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $DF, $F7, $7E, $CF, $DE, $86, $3F, $2E, $3F, $2E, $7B, $7E, $F, $DF, $83, $FF, $41, $EF, $60, $FF, $80, $FF, $A0, $FF, $A2, $FC, $43, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $23, $F4, $81, $FD, $C0, $FF, $80, $FF, $60, $FF, $60, $FF, $89, $FF, $6C, $F7, $FA, $B6, $1F, $8F, $1F, $A7, $BA, $BE, $1C, $DF 
        byte $BE, $F7, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $9F, $D7, $DE, $86, $5F, $3E, $FF, $15, $1D, $26, $74, $6E, $6, $CF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $C0, $FF, $2, $FE, $83, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $60, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $24, $D7, $72, $7E, $9D, $6E, $DF, $7E, $1E, $9F 
        byte $BA, $C6, $1C, $D7, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BF, $E7, $1E, $9F 
        byte $3F, $3E, $DE, $15, $FF, $15, $DD, $25, $4F, $86, $60, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $E3, $F4, $43, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $82, $FD, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $40, $F7, $C, $7E, $BB, $1D, $3F, $3E 
        byte $1F, $9F, $BD, $9E, $BC, $B6, $5D, $EF, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9F, $CF, $5E, $56, $DE, $5 
        byte $DE, $15, $5D, $5, $7D, $D, $6F, $86, $80, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $61, $FE, $A3, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $40, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $AC, $9E, $7B, $15 
        byte $BF, $15, $BF, $66, $1F, $8F, $BC, $B6, $DB, $C6, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FE, $96, $FE, $25, $5E, $5, $7E, $5 
        byte $7E, $5, $9D, $D, $6F, $86, $60, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $C0, $FF, $1, $FE, $83, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $82, $FD, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $AC, $9E 
        byte $9B, $1D, $9F, $5, $1E, $26, $DF, $76, $BD, $96, $7B, $B6, $3C, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $FF, $1E, $97, $BE, $5, $5E, $5, $7E, $5, $7E, $5 
        byte $9D, $15, $6F, $86, $60, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $40, $FF, $E2, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $83, $F4, $E0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF 
        byte $6D, $96, $7C, $D, $5F, $5, $DE, $1D, $BF, $66, $BD, $96, $3A, $AE, $FB, $DE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7C, $76, $BE, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $10, $76, $80, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $81, $FE, $C3, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $83, $F4, $0, $FF, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF 
        byte $20, $F7, $31, $76, $9D, $5, $5E, $5, $9E, $5, $BF, $5E, $9E, $76, $D8, $9D, $BA, $DE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7D, $76, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $15, $56 
        byte $21, $EF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $2, $FE, $83, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $83, $F4, $41, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $A0, $FF, $42, $EF, $F5, $5D, $7E, $5, $7E, $5, $BE, $5, $5F, $3E, $9E, $76, $1B, $86, $79, $D6, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $F7, $7D, $6E, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9A, $25, $26, $DF 
        byte $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $C0, $FF, $62, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $62, $FD, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $A0, $FF, $C8, $C6, $BA, $2D, $7E, $5, $7E, $5, $BE, $D, $FD, $35, $BF, $5E, $3B, $86, $17, $CE, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7A, $7E, $7D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $AB, $A6, $A0, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $0, $FF, $2, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $C3, $FC, $C0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $80, $FF, $70, $86, $9D, $D, $7E, $5, $7E, $5, $5D, $5, $5F, $3E, $DF, $66, $35, $6D, $79, $DE, $BE, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9A, $AE, $7B, $15, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $F5, $45, $80, $FF, $80, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $A1, $FE, $C3, $F4, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $C1, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $80, $FF, $41, $F7, $D6, $45, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $7F, $3E, $7D, $66, $76, $75, $FB, $EE, $BE, $F7, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $1D, $D7, $9C, $2D, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $C8, $BE, $A0, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A1, $FE, $E3, $F4, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $83, $F4, $61, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $E8, $BE, $9C, $15, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $7F, $3E, $7D, $66, $B7, $7D, $FB, $E6, $BE, $F7, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $F7, $BB, $45, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $33, $6E, $80, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A0, $FF, $C1, $FD, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $42, $FD, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $D6, $65, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $7F, $3E, $FD, $2D, $75, $B5, $7D, $F7, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7A, $7E, $7C, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5F, $5, $64, $EF, $A0, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $C0, $FF, $82, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $E3, $FC, $A0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $E7, $CE, $9C, $D, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $BC, $1D, $3F, $2E, $75, $4D, $D7, $D5, $7D, $EF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $1D, $CF, $5A, $25, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $D3, $4D, $C0, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C0, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $E2, $FC, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $D6, $65, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7D, $5, $5F, $36, $FD, $25, $72, $54, $FB, $E6 
        byte $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $DC, $4D, $3D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5F, $5, $E8, $C6, $A0, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $A1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $81, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $48, $AE, $7D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $5F, $2E, $39, $1D, $33, $BD 
        byte $7D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $9A, $A6, $19, $15, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $7C, $45, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $C1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $61, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $81, $FF, $B7, $3D, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $1D, $2E, $51, $4C 
        byte $59, $D6, $5D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $DF, $F7, $DC, $45, $3D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $EA, $8D, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $81, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $8F, $96, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $3F, $2E, $3C, $5 
        byte $D2, $B4, $FB, $DE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $BA, $A6, $19, $1D, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5F, $5, $82, $FF, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A0, $FF, $A2, $FD, $23, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $2, $FD, $C0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $25, $DF, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $1D, $36 
        byte $51, $4C, $D7, $C5, $5D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $DF, $EF, $59, $45, $FC, $4, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $F2, $55, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A0, $FF, $A2, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $2, $FD, $C0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $B6, $3D, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $3C, $15, $71, $A4, $FB, $DE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $1D, $C7, $5B, $2D, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $EA, $95, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A0, $FF, $A2, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $2, $FD, $C0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $AE, $9E, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $5C, $5, $72, $4C, $D6, $C5, $7D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DE, $FF 
        byte $59, $7E, $39, $5, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5E, $5, $8, $CF, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A2, $FD, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $2, $FD, $C0, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $24, $E7, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $D 
        byte $1E, $26, $56, $1C, $F2, $AC, $FB, $DE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9D, $E7 
        byte $58, $4D, $FC, $4, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $9A, $25, $80, $FF, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $A1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $43, $F4, $2, $FD, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $B7, $3D, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7F, $5, $1A, $15, $F, $8C, $79, $CE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BA, $A6 
        byte $19, $1D, $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5F, $5, $31, $7E, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $61, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $C0, $FF, $D7, $6D, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $5C, $5, $73, $44, $54, $B5, $5D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D8, $7D 
        byte $97, $C, $7D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $B, $96, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $81, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $AD, $9E, $5F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $D8, $24, $71, $9C, $79, $CE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9E, $E7, $79, $55 
        byte $FB, $4, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5E, $5, $8, $C7, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C1, $FE, $E3, $FC, $43, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4 
        byte $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $63, $F4, $A3, $F4, $81, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $A0, $FF, $44, $EF, $5F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $9F, $5, $FA, $1C, $F, $84, $F7, $C5, $7D, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $3D, $CF, $39, $35 
        byte $1C, $5, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5E, $5, $43, $EF, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $C0, $FE, $E2, $FC, $43, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC 
        byte $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $63, $FC, $A3, $FC, $81, $FE, $A0, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF 
        byte $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $81, $FF, $7C, $15, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $9E, $5, $3B, $D, $52, $54, $75, $B5, $7D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9A, $A6, $F8, $1C 
        byte $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $98, $25, $60, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $80, $FF 
        byte $80, $FF, $80, $FF, $60, $FF, $80, $FF, $80, $FF, $80, $FF, $A0, $FF, $82, $F6, $A3, $FC, $63, $F4, $64, $E4, $64, $EC, $64, $EC, $64, $EC, $64, $EC, $64, $EC 
        byte $64, $EC, $64, $EC, $64, $EC, $64, $EC, $64, $EC, $64, $EC, $64, $EC, $64, $E4, $64, $EC, $82, $FC, $22, $EE, $C0, $FF, $80, $FF, $80, $FF, $80, $FF, $80, $FF 
        byte $80, $FF, $80, $FF, $80, $FF, $80, $FF, $80, $FF, $60, $FF, $60, $FF, $60, $FF, $80, $FF, $80, $FF, $B6, $3D, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $9E, $5, $3C, $5, $12, $44, $D2, $A4, $1C, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F9, $7D, $97, $4 
        byte $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $13, $56, $80, $FF, $80, $FF, $60, $FF, $80, $FF, $60, $FF, $62, $F7, $61, $F7, $3, $DF 
        byte $25, $D7, $25, $D7, $E5, $C6, $C7, $BE, $AB, $A6, $AC, $A6, $CC, $A6, $CE, $8D, $CE, $94, $EF, $8C, $11, $75, $12, $6D, $F2, $6C, $12, $6D, $12, $6D, $12, $6D 
        byte $12, $6D, $12, $6D, $12, $6D, $12, $6D, $12, $6D, $12, $6D, $F2, $6C, $11, $75, $F0, $7C, $CD, $9C, $70, $7D, $CC, $A6, $AB, $A6, $AB, $A6, $AA, $B6, $E7, $CE 
        byte $25, $D7, $25, $D7, $3, $DF, $42, $EF, $62, $F7, $60, $FF, $80, $FF, $80, $FF, $A0, $FF, $A0, $FF, $30, $76, $5F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $5D, $5, $35, $24, $50, $94, $79, $CE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DF, $F7, $DA, $65, $99, $4 
        byte $5D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $5F, $5, $53, $76, $61, $F7, $26, $D7, $6, $D7, $A9, $AE, $8F, $8E, $51, $76, $32, $6E, $B4, $4D 
        byte $F8, $45, $D8, $3D, $B8, $2D, $99, $25, $7C, $D, $7D, $5, $7D, $5, $9D, $D, $9E, $5, $9E, $5, $9E, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5 
        byte $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9E, $5, $9E, $5, $9E, $5, $9E, $5, $7E, $5, $7C, $15, $7C, $D, $7C, $1D, $9A, $2D 
        byte $D7, $35, $F8, $45, $D5, $4D, $32, $66, $51, $76, $8D, $96, $AA, $A6, $6, $CF, $26, $CF, $80, $FF, $8F, $96, $5F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $97, $24, $CE, $8B, $F7, $C5, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9E, $E7, $79, $55, $DA, $4 
        byte $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $F7, $4D, $52, $6E, $D8, $3D, $F8, $45, $7D, $5, $5F, $5, $7E, $5, $5F, $5, $7F, $5 
        byte $7F, $5, $7F, $5, $7F, $5, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5 
        byte $7F, $5, $7F, $5, $7F, $5, $7F, $5, $7F, $5, $7C, $D, $7D, $D, $D8, $35, $D9, $3D, $52, $66, $15, $5E, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $9F, $5, $D8, $14, $AC, $6B, $96, $B5, $5D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $3D, $CF, $18, $35, $FB, $4 
        byte $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7D, $5, $5F, $5, $7F, $5, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $9E, $5, $9E, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5 
        byte $9E, $D, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9E, $5, $9E, $5, $9E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $7F, $5, $5F, $5, $7D, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $9F, $5, $19, $D, $2F, $54, $14, $A5, $1C, $E7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $1C, $BF, $F7, $2C, $FB, $4 
        byte $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5 
        byte $7E, $5, $9E, $5, $5E, $5, $5D, $5, $FB, $C, $F9, $1C, $F9, $1C, $F9, $1C, $D6, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C 
        byte $B3, $2C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B4, $1C, $B5, $1C, $F8, $1C, $B5, $1C, $F9, $1C, $F9, $1C, $FA, $C, $1C, $5, $3D, $5 
        byte $7E, $5, $5E, $5, $7F, $5, $9F, $5, $9F, $5, $9F, $5, $9E, $5, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $F9, $C, $11, $54, $92, $9C, $DB, $DE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BB, $B6, $75, $1C, $1B, $5 
        byte $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9E, $5, $9F, $5, $9F, $5, $5D, $5, $7E, $5, $FC, $4, $F8, $24, $93, $1C, $93, $1C, $72, $24 
        byte $EB, $43, $2B, $44, $EB, $3B, $EB, $3B, $A9, $4B, $A8, $53, $A8, $53, $A8, $53, $86, $53, $84, $53, $84, $53, $84, $53, $84, $53, $84, $53, $84, $53, $89, $3A 
        byte $65, $53, $84, $53, $84, $53, $84, $53, $84, $53, $84, $53, $84, $53, $84, $53, $85, $53, $A7, $53, $85, $53, $A8, $53, $A8, $53, $A9, $4B, $AA, $3B, $EB, $3B 
        byte $EB, $43, $2F, $2C, $93, $1C, $93, $1C, $93, $1C, $D7, $24, $FB, $4, $5E, $5, $5D, $5, $9F, $5, $9F, $5, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $1A, $D, $F0, $4B, $51, $94, $9A, $D6, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7A, $AE, $14, $14, $1B, $5 
        byte $9E, $5, $7E, $5, $7E, $5, $9E, $5, $9F, $5, $7E, $5, $FC, $4, $F9, $1C, $93, $24, $72, $1C, $EA, $43, $A9, $43, $A7, $5B, $64, $53, $64, $53, $64, $5B 
        byte $40, $6B, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $42, $63, $42, $63, $42, $63, $42, $63, $42, $63, $61, $63, $C4, $5A 
        byte $42, $63, $41, $63, $42, $63, $42, $63, $42, $63, $42, $63, $42, $63, $42, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63, $41, $63 
        byte $40, $6B, $63, $5B, $84, $53, $64, $53, $64, $53, $A6, $5B, $A8, $43, $C9, $43, $51, $24, $72, $24, $D8, $24, $FC, $4, $5E, $5, $9F, $5, $9E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $9E, $5, $3B, $D, $10, $54, $51, $94, $39, $CE, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $5A, $AE, $34, $14, $1B, $5 
        byte $9E, $5, $7E, $5, $9F, $5, $1D, $5, $73, $14, $31, $1C, $89, $3B, $66, $53, $44, $53, $44, $53, $21, $63, $21, $63, $21, $63, $21, $63, $21, $63, $22, $63 
        byte $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $42, $63 
        byte $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B, $22, $5B 
        byte $22, $5B, $22, $63, $21, $63, $21, $63, $21, $63, $21, $63, $21, $63, $20, $63, $44, $53, $43, $53, $66, $53, $67, $43, $31, $1C, $52, $1C, $DC, $4, $9E, $D 
        byte $7E, $5, $7E, $5, $9E, $5, $3C, $5, $F2, $33, $F, $8C, $38, $CE, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $59, $A6, $34, $14, $1C, $5 
        byte $9E, $5, $9E, $5, $D9, $14, $CA, $64, $C4, $84, $A4, $84, $82, $8C, $82, $8C, $83, $8C, $83, $8C, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84 
        byte $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84 
        byte $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84 
        byte $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $84, $83, $8C, $83, $8C, $82, $8C, $82, $8C, $A5, $7C, $C3, $8C, $E7, $74, $94, $35 
        byte $7F, $5, $7E, $5, $9E, $5, $5D, $5, $F3, $2B, $CE, $83, $18, $C6, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $7A, $A6, $B2, $3, $98, $4 
        byte $7E, $5, $9E, $5, $7C, $15, $B2, $44, $A, $4C, $C2, $94, $2, $9D, $E2, $9C, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95 
        byte $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95 
        byte $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95 
        byte $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $3, $95, $E2, $9C, $2, $9D, $1, $A5, $E9, $4B, $90, $4C, $3A, $D 
        byte $9E, $5, $9E, $5, $7D, $5, $78, $4, $51, $23, $CE, $83, $18, $C6, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $5D, $EF, $11, $5C, $AF, $2 
        byte $B9, $4, $9E, $5, $9E, $5, $7E, $5, $FA, $4, $95, $14, $51, $3C, $4E, $55, $28, $75, $E1, $A4, $E1, $9C, $E2, $9C, $E2, $9C, $E3, $94, $C3, $94, $C3, $94 
        byte $E3, $94, $E3, $94, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $C3, $8C, $C3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $94 
        byte $C3, $94, $E3, $94, $C3, $8C, $E3, $94, $C3, $8C, $E3, $94, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $E3, $8C, $C3, $8C, $C3, $8C 
        byte $E3, $8C, $E3, $94, $C3, $94, $E3, $94, $E3, $94, $E2, $94, $E2, $9C, $E1, $9C, $E0, $A4, $27, $7D, $6D, $55, $50, $44, $75, $14, $FA, $4, $5D, $5, $7E, $5 
        byte $9F, $5, $9E, $5, $98, $4, $51, $13, $AB, $5A, $EF, $83, $18, $C6, $9E, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $99, $CE, $E, $33 
        byte $D0, $2, $77, $4, $7D, $5, $BF, $5, $9F, $5, $7E, $5, $5E, $5, $9E, $5, $1A, $D, $F9, $C, $B6, $3D, $4D, $55, $4E, $55, $27, $7D, $47, $AE, $E6, $A5 
        byte $2, $9D, $C7, $9D, $62, $AD, $45, $BE, $A4, $AD, $5, $B6, $E4, $AD, $E5, $AD, $5, $AE, $84, $A5, $46, $B6, $44, $9D, $86, $BE, $3, $95, $A7, $C6, $E3, $94 
        byte $A, $96, $A2, $8C, $28, $CF, $82, $8C, $8, $CF, $C2, $8C, $C7, $C6, $3, $95, $A7, $BE, $24, $9D, $66, $BE, $84, $A5, $25, $BE, $A4, $AD, $4, $B6, $E4, $B5 
        byte $C3, $B5, $85, $9D, $48, $A6, $68, $85, $E7, $74, $ED, $75, $6D, $5D, $B4, $45, $19, $15, $F9, $C, $9D, $5, $5D, $5, $7E, $5, $9E, $5, $BF, $5, $BF, $5 
        byte $1B, $5, $52, $3, $6D, $2, $6C, $1A, $EB, $62, $51, $8C, $18, $C6, $7D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $58, $CE 
        byte $E, $3B, $EB, $1, $11, $3, $78, $4, $3C, $5, $BF, $5, $BF, $5, $9F, $5, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7D, $5, $1A, $D, $BB, $25 
        byte $B6, $3D, $B7, $3D, $94, $45, $6E, $55, $AF, $5D, $50, $6E, $8C, $6D, $A7, $95, $47, $AE, $27, $A6, $48, $A6, $28, $A6, $48, $A6, $28, $A6, $48, $A6, $27, $A6 
        byte $48, $A6, $27, $A6, $48, $A6, $27, $A6, $48, $A6, $27, $A6, $48, $A6, $27, $A6, $47, $AE, $27, $AE, $4A, $96, $CD, $6D, $8A, $75, $EF, $5D, $6E, $55, $93, $45 
        byte $B7, $3D, $99, $2D, $9B, $1D, $9B, $1D, $7D, $D, $9E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $9F, $5, $9F, $5, $BF, $5, $5C, $5, $B8, $4, $73, $3 
        byte $4D, $2, $2B, $12, $28, $4A, $2C, $63, $4D, $6B, $14, $A5, $FB, $DE, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $DE, $FF 
        byte $59, $CE, $10, $8C, $6C, $22, $C, $2, $2C, $2, $52, $3, $73, $3, $98, $4, $5C, $5, $BF, $5, $BF, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7F, $5, $9D, $15, $1B, $5, $7C, $15, $9C, $1D, $9C, $1D, $9C, $1D 
        byte $9C, $1D, $9C, $1D, $9C, $1D, $9C, $1D, $9C, $1D, $9C, $1D, $9C, $15, $7F, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5, $7E, $5 
        byte $7E, $5, $7E, $5, $7E, $5, $9E, $5, $9F, $5, $9F, $5, $9F, $5, $BF, $5, $DF, $5, $7D, $5, $B8, $4, $D9, $4, $73, $3, $2B, $A, $4C, $2, $2C, $A 
        byte $E7, $49, $CB, $5A, $4C, $6B, $AE, $7B, $B2, $94, $59, $CE, $5D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $5D, $EF, $DB, $DE, $55, $AD, $CF, $83, $8A, $62, $B, $A, $B, $2, $2C, $2, $B, $2, $73, $3, $52, $3, $D9, $4, $B8, $4, $7D, $5, $5C, $5, $5C, $5 
        byte $DF, $5, $BF, $5, $BF, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5 
        byte $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $9F, $5, $BF, $5, $BF, $5 
        byte $BF, $5, $BF, $5, $DF, $5, $7D, $5, $7D, $5, $D9, $4, $D9, $4, $93, $3, $94, $3, $2C, $A, $2C, $2, $2C, $2, $2C, $2, $2C, $2, $89, $5A, $8A, $5A 
        byte $C, $6B, $2C, $6B, $71, $8C, $34, $AD, $59, $CE, $7D, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $BE, $F7, $5D, $EF, $79, $CE, $75, $B5, $71, $94, $CE, $83, $8A, $5A, $89, $62, $B, $2, $B, $2, $B, $2, $B, $A, $EB, $9, $2B, $A, $73, $3 
        byte $52, $3, $32, $3, $B4, $3, $B8, $4, $98, $4, $98, $4, $97, $4, $FA, $4, $3C, $5, $3C, $5, $3C, $5, $3C, $5, $3C, $5, $3C, $5, $3C, $5, $3B, $5 
        byte $3C, $5, $3B, $5, $3C, $5, $3B, $5, $3C, $5, $3B, $5, $3C, $5, $3C, $5, $3C, $5, $3C, $5, $1B, $5, $97, $4, $98, $4, $B8, $4, $F5, $3, $32, $3 
        byte $52, $3, $52, $3, $73, $3, $6D, $2, $EA, $9, $B, $A, $B, $A, $2B, $A, $2C, $2, $C6, $41, $AA, $5A, $8A, $5A, $89, $5A, $4C, $73, $CE, $7B, $CF, $7B 
        byte $B2, $94, $55, $AD, $59, $CE, $5D, $EF, $BE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $5D, $EF, $DB, $DE, $59, $C6, $55, $AD, $14, $A5, $71, $94, $CE, $83, $2C, $73, $8A, $5A, $8A, $5A, $C6, $41, $C6, $49 
        byte $C7, $39, $2C, $2, $2B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $EA, $9, $31, $3, $2B, $A, $32, $3 
        byte $EA, $9, $73, $3, $CA, $9, $73, $3, $EA, $9, $52, $3, $EA, $9, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $B, $A, $2B, $A, $2C, $A 
        byte $2C, $A, $E8, $31, $A, $1A, $E8, $31, $69, $5A, $AA, $5A, $8A, $5A, $2C, $73, $4C, $73, $2C, $6B, $CF, $7B, $CE, $7B, $71, $8C, $F3, $9C, $55, $AD, $38, $C6 
        byte $DB, $DE, $5D, $EF, $BE, $F7, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BE, $F7, $BE, $F7, $5D, $EF, $BA, $D6, $18, $C6, $38, $C6, $B6, $B5, $55, $AD, $F3, $A4, $71, $8C, $71, $8C 
        byte $EF, $7B, $CE, $83, $4C, $73, $2C, $6B, $AA, $5A, $AA, $5A, $CA, $62, $8C, $32, $29, $32, $4B, $22, $9, $32, $2B, $22, $6D, $A, $E7, $41, $4C, $12, $E7, $49 
        byte $6C, $A, $C6, $51, $6D, $2, $C6, $51, $6D, $A, $C6, $49, $6D, $A, $4C, $1A, $8, $42, $4B, $1A, $28, $52, $CA, $62, $AA, $5A, $AA, $5A, $AA, $5A, $B, $6B 
        byte $4C, $73, $4D, $73, $4C, $73, $CE, $7B, $CF, $7B, $CF, $7B, $51, $8C, $71, $8C, $B2, $94, $55, $AD, $96, $B5, $38, $C6, $18, $C6, $BA, $D6, $5D, $EF, $BE, $F7 
        byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
        byte $FF, $FF, $FF, $FF, $FF, $FF  

DAT
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
