CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    CS          = 2
    RST         = 4
    DC          = 3
    CLK         = 1
    DIN         = 0

OBJ

    cfg     : "core.con.client.activityboard"
    oled    : "display.oled.ssd1331.96x64"
    ser     : "com.serial.terminal"
    time    : "time"

VAR

    byte _ser_cog, _oled_cog

PUB Main | lcnt, x, y, col, acc

    Setup

    oled.Clear
    lcnt := 0
    col := 1
    repeat acc from 1 to 2
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