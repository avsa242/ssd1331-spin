{
    --------------------------------------------
    Filename: SSD1331-Test.spin
    Author: Jesse Burt
    Description: Test object for the SSD1331 driver
    Copyright (c) 2019
    Started Apr 28, 2019
    Updated May 3, 2019
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

    COL_REG     = 0
    COL_SET     = 14
    COL_READ    = COL_SET+12
    COL_PF      = COL_READ+14


OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    oled    : "display.oled.ssd1331.96x64"

VAR

    long _fails, _expanded
    byte _ser_cog, _oled_cog, _row

PUB Main

    Setup
    oled.Defaults
    _row := 3
    Test_FILL (1)
    Test_COMLRSWAP (1)
    Test_SUBPIX_ORDER (1)
    Test_ADDRINC (1)
    Test_INTERLACE (1)
    Test_MIRRORV (1)
    Test_COLORFORMAT (1)
    Test_CONTRAST_C (1)
    Test_CONTRAST_B (1)
    Test_CONTRAST_A (1)
    Test_MASTERCURRENT (1)
    Test_VCOMH (1)
    Test_PRECHARGELEV (1)
    Test_PRECHARGEA (1)
    Test_PRECHARGEB (1)
    Test_PRECHARGEC (1)
    Test_CLKDIV (1)
    Test_FOSCFREQ (1)
    Test_PRECHARGE2 (1)
    Test_PRECHARGE1 (1)
    Test_POWERSAVE (1)
    Test_MUXRATIO (1)
    Test_DISPMODE (1)
    Test_DISPOFFSET (1)
    Test_STARTLINE (1)
    Test_MIRRORH (1)
    Test_DISPONOFF (1)
    Flash (LED)


PUB Test_FILL(reps) | tmp, read

    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.Fill (tmp)
            read := oled.Fill (-3)
            Message (string("FILL"), tmp, read)

PUB Test_COMLRSWAP(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.VertAltScan (tmp)
            read := oled.VertAltScan (-3)
            Message (string("COMLRSWAP"), tmp, read)

PUB Test_SUBPIX_ORDER(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from oled#SUBPIX_RGB to oled#SUBPIX_BGR
            oled.SubpixelOrder (tmp)
            read := oled.SubpixelOrder (-3)
            Message (string("SUBPIX_ORDER"), tmp, read)

PUB Test_ADDRINC(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from oled#ADDR_HORIZ to oled#ADDR_VERT
            oled.AddrIncMode (tmp)
            read := oled.AddrIncMode (-3)
            Message (string("ADDRINC"), tmp, read)

PUB Test_INTERLACE(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.Interlaced (tmp)
            read := oled.Interlaced (-3)
            Message (string("INTERLACE"), tmp, read)

    oled.MirrorV (FALSE)

PUB Test_MIRRORV(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.MirrorV (tmp)
            read := oled.MirrorV (-3)
            Message (string("MIRRORV"), tmp, read)

    oled.MirrorV (FALSE)

PUB Test_COLORFORMAT(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 2
            oled.ColorDepth (tmp)
            read := oled.ColorDepth (-3)
            Message (string("COLORDEPTH"), tmp, read)

PUB Test_CONTRAST_C(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.ContrastC (tmp)
            read := oled.ContrastC (-3)
            Message (string("CONTRAST_C"), tmp, read)

PUB Test_CONTRAST_B(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.ContrastB (tmp)
            read := oled.ContrastB (-3)
            Message (string("CONTRAST_B"), tmp, read)

PUB Test_CONTRAST_A(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.ContrastA (tmp)
            read := oled.ContrastA (-3)
            Message (string("CONTRAST_A"), tmp, read)

PUB Test_MASTERCURRENT(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 16
            oled.CurrentLimit (tmp)
            read := oled.CurrentLimit (-3)
            Message (string("MASTERCURRENT"), tmp, read)

PUB Test_VCOMH(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 5
            oled.VCOMHDeselect (lookup(tmp: 440, 520, 610, 710, 830))
            read := oled.VCOMHDeselect (-3)
            Message (string("VCOMH"), lookup(tmp: 440, 520, 610, 710, 830), read)

PUB Test_PRECHARGELEV(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 32
            oled.PrechargeLevel (lookup(tmp: 100, 110, 130, 140, 150, 170, 180, 190, 200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360, 370, 390, 400, 410, 430, 440, 450, 460, 480, 490, 500))
            read := oled.PrechargeLevel (-3)
            Message (string("PRECHARGELEV"), lookup(tmp: 100, 110, 130, 140, 150, 170, 180, 190, 200, 220, 230, 240, 260, 270, 280, 300, 310, 320, 330, 350, 360, 370, 390, 400, 410, 430, 440, 450, 460, 480, 490, 500), read)

PUB Test_PRECHARGEC(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.PrechargeSpeed (tmp, tmp, tmp)
            read := oled.PrechargeSpeed (tmp, tmp, -3)
            Message (string("PRECHARGEC"), tmp, read)

PUB Test_PRECHARGEB(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.PrechargeSpeed (tmp, tmp, tmp)
            read := oled.PrechargeSpeed (tmp, -3, tmp)
            Message (string("PRECHARGEB"), tmp, read)

PUB Test_PRECHARGEA(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            oled.PrechargeSpeed (tmp, tmp, tmp)
            read := oled.PrechargeSpeed (-3, tmp, tmp)
            Message (string("PRECHARGEA"), tmp, read)

PUB Test_CLKDIV(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 16
            oled.ClockDiv (tmp)
            read := oled.ClockDiv (-3)
            Message (string("CLKDIV"), tmp, read)

PUB Test_FOSCFREQ(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 15
            oled.ClockFreq (tmp)
            read := oled.ClockFreq (-3)
            Message (string("FOSCFREQ"), tmp, read)

PUB Test_PRECHARGE2(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 15
            oled.Phase2Adj (tmp)
            read := oled.Phase2Adj (-3)
            Message (string("PRECHARGE2"), tmp, read)

PUB Test_PRECHARGE1(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 15
            oled.Phase1Adj (tmp)
            read := oled.Phase1Adj (-3)
            Message (string("PRECHARGE1"), tmp, read)

PUB Test_POWERSAVE(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.PowerSaving (tmp)
            read := oled.PowerSaving (-3)
            Message (string("POWERSAVE"), tmp, read)

    oled.MirrorH (FALSE)

PUB Test_MUXRATIO(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 16 to 64
            oled.DisplayLines (tmp)
            read := oled.DisplayLines (-3)
            Message (string("MUXRATIO"), tmp, read)

PUB Test_DISPMODE(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.DispInverted (tmp)
            read := oled.DispInverted  (-3)
            Message (string("DISPMODE"), tmp, read)

    oled.MirrorH (FALSE)

PUB Test_DISPOFFSET(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 63
            oled.VertOffset (tmp)
            read := oled.VertOffset (-3)
            Message (string("DISPOFFSET"), tmp, read)

PUB Test_STARTLINE(reps) | tmp, read

'    _expanded:=TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 63
            oled.StartLine (tmp)
            read := oled.StartLine (-3)
            Message (string("STARTLINE"), tmp, read)

PUB Test_MIRRORH(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to -1
            oled.MirrorH (tmp)
            read := oled.MirrorH (-3)
            Message (string("MIRRORH"), tmp, read)

    oled.MirrorH (FALSE)

PUB Test_DISPONOFF(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 2
            oled.DisplayEnabled (tmp)
            read := oled.DisplayEnabled (-3)
            Message (string("DISPONOFF"), tmp, read)

    oled.DisplayEnabled (FALSE)

PUB Message(field, arg1, arg2)

    case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0:
            ser.Str (string("FAIL"))
            _fails++

        -1:
            ser.Str (string("PASS"))

        OTHER:
            ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _oled_cog := oled.Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN)
        ser.Str (string("SSD1331 driver started", ser#NL))
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
        time.MSleep (100)

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
