CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    CS          = 2
    RST         = 4
    DC          = 3
    CLK         = 1
    DIN         = 0

OBJ

    cfg     : "core.con.boardcfg.activityboard"
    oled    : "display.oled.ssd1331.96x64"
    ser     : "com.serial.terminal"
    time    : "time"

VAR

    byte _ser_cog, _oled_cog

    long a_min, a_max, a_range
    long b_min, b_max, b_range
    long c_min, c_max, c_range
    long d_min, d_max, d_range
    word _ir_frame[64]
'    byte _d_buff[12288]

PUB Main | lcnt, x, y, col, acc, sx, sy, width, height, i, color, line, c, k

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

    oled.Clear
    lcnt := 0
    col := 1

    sx := 7           ' Starting position of thermal image
    sy := 5
    width := 4        ' Size of each pixel
    height := 4
'    c := cnt & $FFFF
'' Draw box surrounding thermal image
    oled.box(sx-2, sy-2, (width*20) + sx+1, (height*5) + sy+1, oled#White, 0)

    repeat i from 0 to 95
        oled.line (i, (height*5)+sy+3, i, (height*5)+sy+11, GetColor (i*689))
    oled.boxFillOn
    repeat
'    oled.SetPos (0, 0)
'    color := 1
'    repeat
'        bytefill(@_d_buff, cnt & $FFFF, 12288)
'        oled.SendBuff (@_d_buff)
{
    repeat
'        if color > $FFFF
  '          color := 1
'        oled.ssd1331_data (color)
        oled.SetPix (color)
        ?color
}
{
    repeat
        repeat line from 0 to 3
            repeat col from 0 to 15
'                k := (col * 4) + line
                c := cnt & $FFFF
                color := GetColor (c)
                oled.box((col * 5) + sx, (line * 5)+sy, (col * 5) + sx + width, (line * 5) + sy + height, color, color)
}
'    repeat 'SPI speed test
'        oled.Line (0, 0, 95, 63, ?col)

    repeat acc from 1 to 16
        repeat x from 0 to 95
            OLED.line(x, 0, 95-x, 63, col)
            col += acc
        repeat y from 0 to 63
            OLED.line(95, y, 0, 63-y, col)
            col += acc

    oled.copy(28, 22, 68, 42, 0, 43)  
'    oled.ScrollDiagLeft (2, 0, 64, 1, 0)'(horiz_step, vert_start, total_rows, vert_step, time_int)
'    oled.ScrollVert (0, 64, 1, 0)'(start_row, total_rows, scroll_step, time_int)
    oled.ScrollHoriz (1, 32, 31, 6)'(start_col, start_row, total_rows, time_int)
    repeat

PUB Constrain(val, lower, upper)

  return lower #> val <# upper

PUB GetColor(val) | red, green, blue, inmax, outmax, divisor

    inmax := 65535
    outmax := 255
    divisor := Constrain (inmax, 0, 65535)/outmax

    case val
        a_min..a_max:
            red := Constrain ((val/divisor), 0, 255)
            green := 0
            blue := Constrain ((val/divisor), 0, 255)
        b_min..b_max:
            red := Constrain (255-(val/divisor), 0, 255)
            green := 0
            blue := 255
        c_min..c_max:
            red := Constrain ((val/divisor), 0, 255)
            green := Constrain ((val/divisor), 0, 255)
            blue := Constrain (255-(val/divisor), 0, 255)
        d_min..d_max:
            red := 255
            green := 255
            blue := Constrain ((val/divisor), 0, 255)
        OTHER:
            return 0
' RGB888 format
'    return (red << 16) | (green << 8) | blue

' RGB565 format
    return ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
    if _oled_cog := OLED.Start(CS, DC, DIN, CLK, RST)
        ser.Str (string("ssd1331 driver started", ser#NL))
    else
        ser.Str (string("ssd1331 driver failed to start - halting", ser#NL))
        oled.stop
        time.MSleep (500)
        ser.Stop
        repeat

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    