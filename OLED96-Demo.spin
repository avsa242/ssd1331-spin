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

PUB Main | lcnt

    Setup
'    oled.line (0, 0, 95, 63, oled#Green)
    OLED.clearDisplay
    OLED.AutoUpdateOff

    OLED.clearDisplay
    OLED.clearDisplay  
    lcnt := $FFFF
'    repeat
        OLED.line(0,0,95,63,?lcnt)

    OLED.line(0,63,95,0,OLED#Green)
    OLED.boxFillOn
    OLED.box($2,$3,$15,$12,OLED#Yellow,OLED#Red)
    OLED.boxFillOff 
    OLED.box(28,22,68,42,OLED#White,OLED#Black)
    OLED.copy(28,22,68,42,0,43)  
    
    repeat

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#NL))
'    OLED.Init(CS,DC,DIN,CLK,RST)
    if _oled_cog := OLED.Start(CS, DC, DIN, CLK, RST)
        ser.Str (string("ssd1331 driver started", ser#NL))
'        ser.Dec (_oled_cog)
    else
        ser.Str (string("ssd1331 driver failed to start - halting", ser#NL))
'        ser.Dec (_oled_cog)
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