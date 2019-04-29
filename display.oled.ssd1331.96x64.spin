CON

' Transaction type selection
    TRANS_CMD   = 0
    TRANS_DATA  = 1

' Display on/off modes
    DISP_OFF    = 0
    DISP_ON     = 1
    DISP_ON_DIM = 2

OBJ

    core    : "core.con.ssd1331"
    time    : "time"
    io      : "io"
    spi     : "com.spi.fast"

VAR

    long _DC, _RES
'    byte _shadow_reg[67]
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG, _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_POWERSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL

PUB Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN): okay
  ''Startup the SPI system
    if lookdown(CS_PIN: 0..31)
        if lookdown(DC_PIN: 0..31)
            if lookdown(DIN_PIN: 0..31)
                if lookdown(CLK_PIN: 0..31)
                    if lookdown(RES_PIN: 0..31)
                        if okay := spi.start (CS_PIN, CLK_PIN, DIN_PIN, -1)
                            dira[_DC] := 1
                            dira[_RES] := 1
                            _DC := DC_PIN
                            _RES := RES_PIN
                            Reset
                            return okay
    return FALSE

PUB Stop

    DisplayEnabled (FALSE)
    'other power-off code here
    spi.stop

PUB Defaults

    DisplayEnabled (FALSE)
    MirrorH (FALSE)
    StartLine (0)
    VertOffset (0)
    DispInverted (FALSE)
    DisplayLines (64)
    ExtSupply
    PowerSaving (FALSE)
    Phase1Adj (1)
    Phase2Adj (3)
{    SetClk (15, 1)
    SetPrechargeSpd ($64, $78, $64)
    SetPrechargeLev ($3A)
    SetCOMDesLvl (83)
    SetCurrentLimit (7)
    SetContrastA ($fF)
    SetContrastB ($fF)
    SetContrastC ($fF)
    SetContrastA ($91)
    SetContrastB ($50)
    SetContrastC ($7D)
    EnableDisplay (TRUE)
    SetDisplayBounds (0, 0, 95, 63)

    invertDisplay(FALSE)
    ' AutoUpdateOn
    Clear
}


PUB AllPixelsOn | tmp

    _sh_DISPMODE := core#SSD1331_CMD_DISPLAYALLON
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB AllPixelsOff | tmp

    _sh_DISPMODE := core#SSD1331_CMD_DISPLAYALLOFF
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB DisplayEnabled(enabled) | tmp

    tmp := _sh_DISPONOFF
    case ||enabled
        DISP_OFF, DISP_ON, DISP_ON_DIM:
            enabled := lookupz(enabled: core#SSD1331_CMD_DISPLAYOFF, core#SSD1331_CMD_DISPLAYON, core#SSD1331_CMD_DISPLAYONDIM)
        OTHER:
            return lookdownz(tmp: core#SSD1331_CMD_DISPLAYOFF, core#SSD1331_CMD_DISPLAYON, core#SSD1331_CMD_DISPLAYONDIM)

    _sh_DISPONOFF := enabled
    writeRegX (TRANS_CMD, 1, @_sh_DISPONOFF)

PUB DisplayLines(lines) | tmp

    tmp := _sh_MULTIPLEX
    case lines
        16..64:
            lines -= 1
        OTHER:
            return tmp + 1

    _sh_MULTIPLEX := lines
    tmp.byte[0] := core#SSD1331_CMD_SETMULTIPLEX
    tmp.byte[1] := lines
    writeRegX (TRANS_CMD, 2, @tmp)

PUB DispInverted(enabled) | tmp

    tmp := _sh_DISPMODE
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#SSD1331_CMD_NORMALDISPLAY, core#SSD1331_CMD_INVERTDISPLAY)
        OTHER:
            result := lookdownz(tmp: core#SSD1331_CMD_NORMALDISPLAY, core#SSD1331_CMD_INVERTDISPLAY)
            return (result & %1) * TRUE

    _sh_DISPMODE := enabled
    tmp := _sh_DISPMODE
    writeRegX (TRANS_CMD, 1, @tmp)

PUB MirrorH(enabled) | tmp

    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_SEGREMAP
        OTHER:
            return ((tmp >> core#FLD_SEGREMAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_SEGREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SSD1331_CMD_SETREMAP_MASK
    tmp.byte[0] := core#SSD1331_CMD_SETREMAP
    tmp.byte[1] := _sh_REMAPCOLOR
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Phase1Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        1..15:
        OTHER:
            return tmp & core#BITS_PHASE1

    _sh_PHASE12PER &= core#MASK_PHASE1
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#SSD1331_CMD_PRECHARGE
    tmp.byte[1] := _sh_PHASE12PER
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Phase2Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        1..15:
            clks <<= core#FLD_PHASE2
        OTHER:
            return (tmp >> core#FLD_PHASE2) & core#BITS_PHASE2

    _sh_PHASE12PER &= core#MASK_PHASE2
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    tmp.byte[0] := core#SSD1331_CMD_PRECHARGE
    tmp.byte[1] := _sh_PHASE12PER
    writeRegX (TRANS_CMD, 2, @tmp)

PUB PlotXY(x, y, rgb) | tmp[2]

    tmp.byte[0] := core#SSD1331_CMD_SETCOLUMN
    tmp.byte[1] := x
    tmp.byte[2] := 95
    tmp.byte[3] := core#SSD1331_CMD_SETROW
    tmp.byte[4] := y
    tmp.byte[5] := 63
    
    writeRegX (TRANS_CMD, 6, @tmp)

    time.USleep (3)

    writeRegX (TRANS_DATA, 2, @rgb)

PUB PowerSaving(enabled) | tmp

    tmp := _sh_POWERSAVE
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#POWERMODE_POWERSAVE_DIS, core#POWERMODE_POWERSAVE_ENA)
        OTHER:
            return (lookdownz(_sh_POWERSAVE: core#POWERMODE_POWERSAVE_DIS, core#POWERMODE_POWERSAVE_ENA) & %1) * TRUE

    _sh_POWERSAVE := enabled
    tmp.byte[0] := core#SSD1331_CMD_POWERMODE
    tmp.byte[1] := enabled
    writeRegX (TRANS_CMD, 2, @tmp)

PUB ExtSupply | tmp

    tmp.byte[0] := core#SSD1331_CMD_SETMASTER
    tmp.byte[1] := core#MASTERCFG_EXT_VCC
    writeRegX (TRANS_CMD, 2, @tmp)

PUB StartLine(line) | tmp

    tmp := _sh_DISPSTARTLINE
    case line
        0..63:
        OTHER:
            return tmp

    _sh_DISPSTARTLINE := line
    tmp.byte[0] := core#SSD1331_CMD_STARTLINE
    tmp.byte[1] := line
    writeRegX (TRANS_CMD, 2, @tmp)

PUB VertOffset(line) | tmp

    tmp := _sh_DISPOFFSET
    case line
        0..63:
        OTHER:
            return tmp

    _sh_DISPOFFSET := line
    tmp.byte[0] := core#SSD1331_CMD_DISPLAYOFFSET
    tmp.byte[1] := line
    writeRegX (TRANS_CMD, 2, @tmp)

PUB Reset

    dira[_RES] := 1

    outa[_RES] := 1
    time.MSleep (1)
    outa[_RES] := 0
    time.MSleep (10)
    outa[_RES] := 1

{    io.High (_RES)
    time.MSleep (1)
    io.Low (_RES)
    time.MSleep (10)
    io.High (_RES)
}
PUB writeRegX(trans_type, nr_bytes, buf_addr)

    case trans_type
        TRANS_DATA:
'            io.High (_DC)
            outa[_DC] := 1
        TRANS_CMD:
'            io.Low (_DC)
            outa[_DC] := 0

        OTHER:
            return

    spi.writeSPI (TRUE, buf_addr, nr_bytes) ' Write SPI transaction with blocking enabled


{PRI POR
'shadow reg binary blob: array of bytes set during startup
'api-level methods use symbolic names in read/writeRegX
'low-level methods use lookup/lookdown table to find that reg in array
'core.con file uses std masks, fields, bits
'   _shadow_reg.byte[0] := $00
'   _shadow_reg.byte[1] := $5F
'   _shadow_reg.byte[1] := $00
'   _shadow_reg.byte[1] := $3F
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $5F
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $3F
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $0F
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $40
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $A4
    _shadow_reg.byte[0] := $3F
    _shadow_reg.byte[0] := $00 '$AB - A
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $80
    _shadow_reg.byte[0] := $0F '$AB - E
    _shadow_reg.byte[0] := $00
    _shadow_reg.byte[0] := $00
 }   
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