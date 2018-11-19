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

    CMD_DRAWLINE                = $21
    CMD_DRAWRECT                = $22
    CMD_COPY                    = $23
    CMD_CLEAR                   = $25
    CMD_FILL                    = $26
    CMD_SCROLLSETUP             = $27
    CMD_SCROLLSTOP              = $2E
    CMD_SCROLLSTART             = $2F
    CMD_SETCOLUMN               = $15
    CMD_SETROW                  = $75
    CMD_CONTRASTA               = $81
    CMD_CONTRASTB               = $82
    CMD_CONTRASTC               = $83
    CMD_MASTERCURRENT           = $87
    CMD_SETREMAP                = $A0
    CMD_STARTLINE               = $A1
    CMD_DISPLAYOFFSET           = $A2
    CMD_NORMALDISPLAY           = $A4
    CMD_DISPLAYALLON            = $A5
    CMD_DISPLAYALLOFF           = $A6
    CMD_INVERTDISPLAY           = $A7
    CMD_SETMULTIPLEX            = $A8
    CMD_SETMASTER               = $AD
    CMD_DISPLAYOFF              = $AE
    CMD_DISPLAYON               = $AF
    CMD_POWERMODE               = $B0
    CMD_PRECHARGE               = $B1
    CMD_CLOCKDIV                = $B3
    CMD_PRECHARGEA              = $8A
    CMD_PRECHARGEB              = $8B
    CMD_PRECHARGEC              = $8C
    CMD_PRECHARGELEVEL          = $BB
    CMD_VCOMH                   = $BE

    CMD_SET_VERT_SCROLL_AREA    = $A3
    CMD_RIGHT_HORIZ_SCROLL      = $26
    CMD_LEFT_HORIZ_SCROLL       = $27
    CMD_VERTRIGHTHORIZSCROLL    = $29
    CMD_VERTLEFTHORIZSCROLL     = $2A

    CMD_NOP                     = $E3

PUB Null
'' This is not a top-level object
