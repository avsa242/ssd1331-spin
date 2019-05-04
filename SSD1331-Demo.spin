{
    --------------------------------------------
    Filename:
    Author:
    Description:
    Copyright (c) 20__
    Started Month Day, Year
    Updated Month Day, Year
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    RES_PIN     = 0
    DC_PIN      = 1
    CS_PIN      = 2
    CLK_PIN     = 3
    DIN_PIN     = 4

    LED         = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    oled    : "display.oled.ssd1331.96x64"

VAR

    long rndSeed
    long a_min, a_max, a_range
    long b_min, b_max, b_range
    long c_min, c_max, c_range
    long d_min, d_max, d_range
    byte _ser_cog, _oled_cog

PUB Main

    Setup
    a_min := 0
    a_max := 16383
    a_range := a_max - a_min

    b_min := a_max + 1
    b_max := 32767
    b_range := b_max - b_min

    c_min := b_max + 1
    c_max := 49151
    c_range := c_max - c_min

    d_min := c_max + 1
    d_max := 65535
    d_range := d_max - d_min

    oled.VertAltScan (FALSE)
    oled.SubpixelOrder (oled#SUBPIX_RGB)
    oled.MirrorH (FALSE)
    oled.Interlaced (FALSE)
    oled.MirrorV (FALSE)
    oled.Clear
    Demo_LineRND (5000)
    oled.Clear
    Demo_PlotRND (5000)
    oled.Clear
    Demo_BoxRND (5000)
    Demo_HLineSpectrum (1)
    time.Sleep (2)
    oled.Copy (0, 0, 20, 20, 20, 20)
    time.Sleep (2)
    Demo_FadeOut (1)
    oled.AllPixelsOff
    oled.DisplayEnabled (FALSE)
    Flash (LED)

PUB Constrain(val, lower, upper)

    return lower #> val <# upper

PUB Demo_BoxRND(reps) | sx, sy, ex, ey, c

    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := GetColor (RND (65535))

        oled.Box (sx, sy, ex, ey, c, c)

PUB Demo_FadeOut(reps) | c

    repeat c from 127 to 0
        oled.ContrastA (||c)
        oled.ContrastB (||c)
        oled.ContrastC (||c)
        time.MSleep (50)

PUB Demo_HLineSpectrum(reps) | x, c

    repeat x from 0 to 95
        c := GetColor (x * 689)
        oled.Line (x, 0, x, 63, c)

PUB Demo_LineRND(reps) | sx, sy, ex, ey, c

    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := GetColor (RND (65535))
        oled.Line (sx, sy, ex, ey, c)

PUB Demo_HPlotSpectrum(reps) | x, y, c

    repeat y from 0 to 63
        repeat x from 0 to 95
            c := GetColor (x*689)
            oled.PlotXY (x, y, c)

PUB Demo_PlotRND(reps) | x, y, c

    repeat reps
        x := RND (95)
        y := RND (63)
        c := GetColor (RND (65535))
        oled.PlotXY (x, y, c)

PUB GetColor(val) | red, green, blue, inmax, outmax, divisor, tmp

    inmax := 65535
    outmax := 255
    divisor := Constrain (inmax, 0, 65535)/outmax

    case val
        a_min..a_max:
            red := 0
            green := 0
            blue := Constrain ((val/divisor), 0, 255)
        b_min..b_max:
            red := 0
            green := Constrain ((val/divisor), 0, 255)
            blue := 255
        c_min..c_max:
            red := Constrain ((val/divisor), 0, 255)
            green := 255
            blue := Constrain (255-(val/divisor), 0, 255)
        d_min..d_max:
            red := 255
            green := Constrain (255-(val/divisor), 0, 255)
            blue := 0
        OTHER:
' RGB888 format
'    return (red << 16) | (green << 8) | blue

' RGB565 format
    return ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3)
'    tmp := ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3)
'    result := RG16bitColor (tmp)
'    result := result | (GB16bitColor (tmp) << 8)

PUB RND(upperlimit) | i       'Returns a random number between 0 and upperlimit

  i :=? rndSeed
  i >>= 16
  i *= (upperlimit + 1)
  i >>= 16

  return i

PUB RG16bitColor(RGB)
    return (RGB & $FF00) >> 8
'    return ((RGB & $1F_00_00) >> 13) | ((RGB & $E0_00) >> 13)

PUB GB16bitColor(RGB)
    return RGB & $FF
'    return ((RGB & $7FF) >> 3) | (RGB & $1F)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _oled_cog := oled.Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN)
        ser.Str (string("SSD1331 driver started", ser#NL))
        oled.Defaults
    else
        ser.Str (string("SSD1331 driver failed to start - halting", ser#NL))
        Stop

PUB Stop

    oled.Stop
    time.MSleep (5)
    ser.Stop
    Flash(LED)

PUB Flash(led_pin)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (500)

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
