//=========
// SMS PSG
//=========
// Write 4 Bytes Of Data To PSG
macro PSGWrite(DATA) { // DATA = Bytes To Send To PSG Register
  ld hl,{DATA} // HL = Data Address
  ld b,4       // B = Data Length (4 Bytes)
  ld c,$7F     // C = PSG Port ($7F)
  otir         // OUT (C), (LD A, (HL)++), A = Byte Loaded From HL Address, Write Byte To PSG, Offset++, B--
}

// Write Data Byte To PSG
macro PSGWriteByte(DATA) // DATA = Byte To Send To VDP Register
  ld a,{DATA} // A = PSG Data
  out ($7F),a // Write PSG Data To PSG Register
}