//=========
// SMS VDP
//=========
// Wait For Vertical Counter Position
macro VDPWaitV(VPOS) { // VPOS = Wait Vertical Counter Position
  -
    in a,($7E) // A = Current Vertical Counter Position
    cp {VPOS}  // IF (Current Vertical Counter Position != VPOS)
    jr nz,-    // Wait For Vertical Counter Position
}

// Wait For Horizontal Counter Position
macro VDPWaitH(HPOS) { // HPOS = Wait Horizontal Counter Position
  -
    in a,($7F) // A = Current Horizontal Counter Position
    cp {HPOS}  // IF (Current Horizontal Counter Position != HPOS)
    jr nz,-    // Wait For Horizontal Counter Position
}

// Write Data Byte To VDP Register
macro VDPREGWrite(DATA, REG) { // DATA = Byte To Send To VDP, REG = VDP Register To Write (0..15)
  ld a,{DATA} // A = VDP Register Data
  out ($BF),a // Write VDP Register Data To VDP (1st Byte Of Command Pair)
  ld a,%10000000 + {REG} // A = VDP REG Write, VDP Register (%TT00RRRR TT %10 = VDP REG Write, %RRRR = VDP Register 0..15)
  out ($BF),a // Write VDP Data To VDP Register (2nd Byte Of Command Pair)
}

// Write SMS 6-Bit BGR Palette # Of Colors Offset By Address To CRAM
macro SMSPALWrite(PAL, COL, OFFSET) { // PAL = Palette Address, COL = Number Of Colors (0..32), OFFSET = CRAM Address Offset (0..32)
  ld a,{OFFSET}  // A = CRAM Address Offset (%000AAAAA = CRAM Address Offset)
  out ($BF),a    // Write CRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%11000000 // A = CRAM Write Command (%11000000 = CRAM Write)
  out ($BF),a    // Write CRAM Write Command To VDP (2nd Byte Of Command Pair)
  ld hl,{PAL} // HL = Palette Address
  ld b,{COL}  // B = Palette Data Size In Bytes
  ld c,$BE
  otir // OUT (C), (LD A, (HL)++), A = 6-Bit Palette Color %00BBGGRR Loaded From HL Palette Address, Write Palette Color To VDP CRAM Address Offset, Offset++, B--
}

// Write Tile Characters # Of Tiles Offset By Addres To VRAM
macro VDPCHRWrite(TILE, NUM, OFFSET) { // TILE = Tile Address, NUM = Number Of Tiles (0..255), OFFSET = VRAM Address Offset
  ld a,{OFFSET} & $FF              // A = VRAM Address Offset (%AAAAAAAA = VRAM Address Offset LO)
  out ($BF),a                      // Write VRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%01000000 + ({OFFSET} >> 8) // A = VRAM Write Address Offset (%TTAAAAAA TT %00 = VRAM Read, TT %01 = VRAM Write, %AAAAAA = VRAM Address Offset HI)
  out ($BF),a                      // Write VRAM Write Address Offset To VDP (2nd Byte Of Command Pair)
  ld hl,{TILE} // HL = Tile Address
  ld c,$BE
  ld d,{NUM} // D = Number Of Tiles
  -
    ld b,32 // B = Number Of Tile Bytes To Write (8 * 4 Bits = 32 Bytes)
    otir // OUT (C), (LD A, (HL)++), A = 8-Bit Tile Byte Loaded From HL Tile Address, Write Tile Byte To VDP VRAM Address Offset, Offset++, B--
    dec d // Decrement Number Of Tiles
    jr nz,- // Writes # Of Tiles To VRAM
}

// Write Tile Map # Of Tile Map Words Offset By Address To VRAM
macro VDPMAPWrite(MAP, NUM, OFFSET) { // MAP = Tile Map Address, NUM = Number Of Tile Map Words (0..255), OFFSET = VRAM Address Offset
  ld a,{OFFSET} & $FF              // A = VRAM Address Offset (%AAAAAAAA = VRAM Address Offset LO)
  out ($BF),a                      // Write VRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%01000000 + ({OFFSET} >> 8) // A = VRAM Write Address Offset (%TTAAAAAA TT %00 = VRAM Read, TT %01 = VRAM Write, %AAAAAA = VRAM Address Offset HI)
  out ($BF),a                      // Write VRAM Write Address Offset To VDP (2nd Byte Of Command Pair)
  ld hl,{MAP} // HL = Tile Map Address
  ld b,{NUM}  // B = Number Of Tile Map Words
  -
    outi // OUT (C), (LD A, (HL)++), A = 8-Bit Tile Map Byte Loaded From HL Tile Map Address, Write Tile Map Byte To VDP VRAM Address Offset, Offset++, B--
    inc b // Increment Number Of Tile Map Words
    outi // OUT (C), (LD A, (HL)++), A = 8-Bit Tile Map Byte Loaded From HL Tile Map Address, Write Tile Map Byte To VDP VRAM Address Offset, Offset++, B--
    jr nz,- // Writes # Of Tile Map Words To VRAM
}

// Write HL Tile Map # Of Tile Map Words Offset By Address To VRAM
macro VDPMAPWriteHL(NUM, OFFSET) { // HL = Tile Map Address, NUM = Number Of Tile Map Words (0..255), OFFSET = VRAM Address Offset
  ld a,{OFFSET} & $FF              // A = VRAM Address Offset (%AAAAAAAA = VRAM Address Offset LO)
  out ($BF),a                      // Write VRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%01000000 + ({OFFSET} >> 8) // A = VRAM Write Address Offset (%TTAAAAAA TT %00 = VRAM Read, TT %01 = VRAM Write, %AAAAAA = VRAM Address Offset HI)
  out ($BF),a                      // Write VRAM Write Address Offset To VDP (2nd byte Of Command Pair)
  ld b,{NUM} // B = Number Of Tile Map Words
  -
    outi // OUT (C), (LD A, (HL)++), A = 8-Bit Tile Map Byte Loaded From HL Tile Map Address, Write Tile Map Byte To VDP VRAM Address Offset, Offset++, B--
    inc b // Increment Number Of Tile Map Words
    outi // OUT (C), (LD A, (HL)++), A = 8-Bit Tile Map Byte Loaded From HL Tile Map Address, Write Tile Map Byte To VDP VRAM Address Offset, Offset++, B--
    jr nz,- // Writes # Of Tile Map Words To VRAM
}

// Repeat Tile Map # Of Tile Map Words Offset By Address To VRAM
macro VDPMAPRepeat(MAPA, MAPB, NUM, OFFSET) { // MAPA = Tile Map Byte A, MAPB = Tile Map Byte B, NUM = Number Of Repeats (0..255), OFFSET = VRAM Address Offset
  ld a,{OFFSET} & $FF              // A = VRAM Address Offset (%AAAAAAAA = VRAM Address Offset LO)
  out ($BF),a                      // Write VRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%01000000 + ({OFFSET} >> 8) // A = VRAM Write Address Offset (%TTAAAAAA TT %00 = VRAM Read, TT %01 = VRAM Write, %AAAAAA = VRAM Address Offset HI)
  out ($BF),a                      // Write VRAM Write Address Offset To VDP (2nd Byte Of Command Pair)
  ld a,{MAPA} // A = Tile Map Byte A
  ld b,{MAPB} // B = Tile Map Byte B
  ld c,$BE
  ld d,{NUM} // D = Number Of Repeats
  -
    out (c),a // Write Tile Map Byte A To VDP VRAM Address Offset, VRAM Address Offset++
    out (c),b // Write Tile Map Byte B To VDP VRAM Address Offset, VRAM Address Offset++
    dec d // Decrement Number Of Repeats
    jr nz,- // Writes # Of Tile Map Words To VRAM
}

// Repeating Tile Map # Of Tile Map Words To VRAM
macro VDPMAPRepeating(MAPA, MAPB, NUM) { // MAPA = Tile Map Byte A, MAPB = Tile Map Byte B, NUM = Number Of Repeats (0..255)
  ld a,{MAPA} // A = Tile Map Byte A
  ld b,{MAPB} // B = Tile Map Byte B
  ld d,{NUM} // D = Number Of Repeats
  -
    out (c),a // Write Tile Map Byte A into VDP VRAM Address Offset, VRAM Address Offset++
    out (c),b // Write Tile Map Byte B into VDP VRAM Address Offset, VRAM Address Offset++
    dec d // Decrement Number Of Repeats
    jr nz,- // Writes # of tile map words to VRAM
}

// Write Data # Of Bytes Offset By Address To VRAM
macro VDPVRAMWrite(DATA, NUM, OFFSET) { // DATA = Data Address, NUM = Number Of Bytes (0..255), OFFSET = VRAM Address Offset
  ld a,{OFFSET} & $FF              // A = VRAM Address Offset (%AAAAAAAA = VRAM Address Offset LO)
  out ($BF),a                      // Write VRAM Address Offset To VDP (1st Byte Of Command Pair)
  ld a,%01000000 + ({OFFSET} >> 8) // A = VRAM Write Address Offset (%TTAAAAAA TT %00 = VRAM Read, TT %01 = VRAM Write, %AAAAAA = VRAM Address Offset HI)
  out ($BF),a                      // Write VRAM Write Address Offset To VDP (2nd Byte Of Command Pair)
  ld hl,{DATA} // HL = Data Address
  ld b,{NUM} // B = Number Of Bytes
  otir // OUT (C), (LD A, (HL)++), A = 8-Bit Data Byte Loaded From HL Data Address Offset, Write Data Byte To VDP VRAM Address Offset, Offset++, B--
}

// Writing Data # Of Bytes Offset By Address To VRAM
macro VDPVRAMWriting(DATA, NUM) { // DATA = Data Address, NUM = Number of Bytes (0..255)
  ld hl,{DATA} // HL = Data Address
  ld b,{NUM} // B = Number Of Bytes
  otir // OUT (C), (LD A, (HL)++), A = 8-Bit Data Byte Loaded From HL Data Address Offset, Write Data Byte To VDP VRAM Address Offset, Offset++, B--
}