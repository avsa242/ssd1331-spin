{
    --------------------------------------------
    Filename: core.con.ssd1331.spin
    Author: Jesse Burt
    Copyright (c) 2018
    Started: Nov 18, 2018
    Updated: Nov 18, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON
'' Register map
    SSD1331_SSD1331_CMD_DRAWLINE                = $21
    SSD1331_CMD_DRAWRECT                = $22
    SSD1331_CMD_COPY                    = $23
    SSD1331_CMD_CLEAR                   = $25
    SSD1331_CMD_FILL                    = $26
    SSD1331_CMD_SCROLLSETUP             = $27
    SSD1331_CMD_SCROLLSTOP              = $2E
    SSD1331_CMD_SCROLLSTART             = $2F
    SSD1331_CMD_SETCOLUMN               = $15
    SSD1331_CMD_SETROW                  = $75
    SSD1331_CMD_CONTRASTA               = $81
    SSD1331_CMD_CONTRASTB               = $82
    SSD1331_CMD_CONTRASTC               = $83
    SSD1331_CMD_MASTERCURRENT           = $87

    SSD1331_CMD_SETREMAP                = $A0
    SSD1331_CMD_SETREMAP_MASK           = $FF
        FLD_SEGREMAP                    = 1
        MASK_SEGREMAP                   = SSD1331_CMD_SETREMAP_MASK ^ (1 << FLD_SEGREMAP)

    SSD1331_CMD_STARTLINE               = $A1
    SSD1331_CMD_DISPLAYOFFSET           = $A2
    SSD1331_CMD_NORMALDISPLAY           = $A4
    SSD1331_CMD_DISPLAYALLON            = $A5
    SSD1331_CMD_DISPLAYALLOFF           = $A6
    SSD1331_CMD_INVERTDISPLAY           = $A7
    SSD1331_CMD_SETMULTIPLEX            = $A8
    SSD1331_CMD_DISPLAYONDIM            = $AC

    SSD1331_CMD_SETMASTER               = $AD
        MASTERCFG_EXT_VCC               = $8E

    SSD1331_CMD_DISPLAYOFF              = $AE
    SSD1331_CMD_DISPLAYON               = $AF
    SSD1331_CMD_POWERMODE               = $B0
    SSD1331_CMD_PRECHARGE               = $B1
    SSD1331_CMD_CLOCKDIV                = $B3
    SSD1331_CMD_PRECHARGEA              = $8A
    SSD1331_CMD_PRECHARGEB              = $8B
    SSD1331_CMD_PRECHARGEC              = $8C
    SSD1331_CMD_PRECHARGELEVEL          = $BB
    SSD1331_CMD_NOP1                    = $BC
    SSD1331_CMD_NOP2                    = $BD
    SSD1331_CMD_VCOMH                   = $BE

    SSD1331_CMD_NOP3                    = $E3

'' Other constants
    SEL_EXTERNAL_VCC            = $8E

PUB Null
'' This is not a top-level object
