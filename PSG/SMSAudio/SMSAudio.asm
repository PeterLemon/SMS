// SMS PSG Audio Player demo by krom (Peter Lemon):
arch sms.cpu
output "SMSAudio.sms", create

macro seek(variable offset) {
  origin offset
  base offset
}

// BANK 0..7 (128KB)
seek($0000); fill $20000 // Fill Bank 0..7 With Zero Bytes
include "LIB\SMS_HEADER.ASM" // Include SMS Header
include "LIB\SMS_INPUT.ASM" // includes INPUT Macros
include "LIB\SMS_PSG.ASM" // includes PSG Macros
include "LIB\SMS_VDP.ASM" // Include VDP Macros

seek($0000)
di // Disable Interrupts
im 1 // Set Interrupt Mode 1
jp Start

seek($0100); Start:
ld a,0 // A = 0

// Character Buffer: $C000-$C001
ld ($C000),a // Character #
ld ($C001),a // Character Palette

ld ($C002),a // Option Selection
ld ($C003),a // Tone Generator #1 Channel Disable/Enable (1 bit)
ld ($C004),a // Tone Generator #2 Channel Disable/Enable (1 bit)
ld ($C005),a // Tone Generator #3 Channel Disable/Enable (1 bit)
ld ($C006),a // Noise Generator   Channel Disable/Enable (1 bit)
ld ($C007),a // Tone Generator #1 Attenuation (4 bits)
ld ($C008),a // Tone Generator #2 Attenuation (4 bits)
ld ($C009),a // Tone Generator #3 Attenuation (4 bits)
ld ($C00A),a // Noise Generator   Attenuation (4 bits)
ld ($C00B),a // Tone Generator #1 Frequency (10 bits)
ld ($C00C),a
ld ($C00D),a // Tone Generator #2 Frequency (10 bits)
ld ($C00E),a
ld ($C00F),a // Tone Generator #3 Frequency (10 bits)
ld ($C010),a
ld ($C011),a // Noise Generator Type (1 bit)
ld ($C012),a // Noise Generator Clock Source (2 bits)

// Load Palette
SMSPALWrite(BGPAL, 32, 0) // Load 32 Colors To CRAM, Offset By 0 Colors

// Load Tile Characters
VDPCHRWrite(BGCHR, 95, $400) // Loads 95 8x8 Tiles To VRAM, Offset By $400

// Clear Screen To Black Using The Space Font Character
ld e,27 // E = Row Count
ClearBG:
  VDPMAPRepeat($20, 0, 32, $3800) // Load 32 Tile Map Words (Space = $20) To VRAM, Offset By $3800
  dec e // Decrement Row Count
  jr nz,ClearBG // IF (Row Count != 0) Clear BG

// Draw 1st Screen
VDPMAPWrite(TEXTSMSAUDIOPLAYER, 29, $3844) // Load 29 Tile Map Words To VRAM, Offset By $3844
VDPMAPWrite(TEXTToneGenerator1, 18, $38C4) // Load 18 Tile Map Words To VRAM, Offset By $38C4
VDPMAPWrite(TEXTChannel, 8, $3908) // Load 8 Tile Map Words To VRAM, Offset By $3908
VDPMAPWrite(TEXTAttenuation, 15, $3948) // Load 15 Tile Map Words To VRAM, Offset By $3948
VDPMAPWrite(TEXTFrequency, 15, $3988) // Load 15 Tile Map Words To VRAM, Offset By $3988
VDPMAPWrite(TEXTToneGenerator2, 18, $3A04) // Load 18 Tile Map Words To VRAM, Offset By $3A04
VDPMAPWrite(TEXTChannel, 8, $3A48) // Load 8 Tile Map Words To VRAM, Offset By $3A48
VDPMAPWrite(TEXTAttenuation, 15, $3A88) // Load 15 Tile Map Words To VRAM, Offset By $3A88
VDPMAPWrite(TEXTFrequency, 15, $3AC8) // Load 15 Tile Map Words To VRAM, Offset By $3AC8
VDPMAPWrite(TEXTToneGenerator3, 18, $3B44) // Load 18 Tile Map Words To VRAM, Offset By $3B44
VDPMAPWrite(TEXTChannel, 8, $3B88) // Load 8 Tile Map Words To VRAM, Offset By $3B88
VDPMAPWrite(TEXTAttenuation, 15, $3BC8) // Load 15 Tile Map Words To VRAM, Offset By $3BC8
VDPMAPWrite(TEXTFrequency, 15, $3C08) // Load 15 Tile Map Words To VRAM, Offset By $3C08
VDPMAPWrite(TEXTNoiseGenerator, 16, $3C84) // Load 16 Tile Map Words To VRAM, Offset By $3C84
VDPMAPWrite(TEXTChannel, 8, $3CC8) // Load 8 Tile Map Words To VRAM, Offset By $3CC8
VDPMAPWrite(TEXTAttenuation, 15, $3D08) // Load 15 Tile Map Words To VRAM, Offset By $3D08
VDPMAPWrite(TEXTType, 5, $3D48) // Load 5 Tile Map Words To VRAM, Offset By $3D48
VDPMAPWrite(TEXTClockSource, 13, $3D88) // Load 13 Tile Map Words To VRAM, Offset By $3D88

// Write VDP Register 1 (Turn Display On)
VDPREGWrite(%11100000, 1) // Write VDP Register 1 Data (%1DI000S0 D = Display 0: Off 1: On, I = Interrupts 0: Off 1: On, S = Sprite Size 0: 8x8 1: 8x16)

Refresh:
  // Slow Down Input By Waiting 8 VSyncs
  ld e,8 // E = VSync Count
  WaitLoop:
    VDPWaitV(0)   // Wait for V Counter Position 0
    VDPWaitV(192) // Wait for V Counter Position 192
    dec e // Decrement VSync Count
    jr nz,WaitLoop // IF (VSync Count != 0) Wait Loop


  TESTPortA(%00010000) // Test Port A Joypad 1 A Button
  jp nz,ChannelALLOFF
  VDPMAPWrite(TEXTPLAYINGRed, 7, $38AC) // Load 7 Tile Map Words To VRAM, Offset By $38AC
      
  ld a,($C003) // Load Tone Generator #1 Channel To A
  cp 0 // Compare A To Zero
  jr z,Channel1OFF // IF (A == Zero) Channel 1 OFF
  ld a,($C007) // Load Tone Generator #1 Attenuation To A
  add a,$90 // Add Tone Generator #1 Attenuation Write Upper Nibble Command 
  PSGWriteByte(a) // Set Tone Generator #1 Attenuation

  ld a,($C00B) // Load Tone Generator #1 Frequency LO Nibble To A
  and $0F // A &= $F
  add a,$80 // Add Tone Generator #1 Frequency LO Nibble Command
  PSGWriteByte(a) // Set Tone Generator #1 Frequency LO Nibble

  ld a,($C00C) // Load Tone Generator #1 Frequency HI Nibble Command To B
  ld b,a
  ld a,($C00B) // Load Tone Generator #1 Frequency LO Nibble To A
  srl a // A >>= 4
  srl a
  srl a
  srl a
  sla b // B <<= 4
  sla b
  sla b
  sla b
  add a,b // A += B
  PSGWriteByte(a) // Set Tone Generator #1 Frequency HI 10-Bit Nibble
  jr Channel1Set
  Channel1OFF:
    PSGWriteByte($9F) // Set PSG Channel 1 Attenuation To "OFF"
  Channel1Set:


  ld a,($C004) // Load Tone Generator #2 Channel To A
  cp 0 // Compare A To Zero
  jr z,Channel2OFF // IF (A == Zero) Channel 2 OFF
  ld a,($C008) // Load Tone Generator #2 Attenuation To A
  add a,$B0 // Add Tone Generator #2 Attenuation Write Upper Nibble Command
  PSGWriteByte(a) // Set Tone Generator #2 Attenuation

  ld a,($C00D) // Load Tone Generator #2 Frequency LO Nibble To A
  and $0F // A &= $F
  add a,$A0 // Add Tone Generator #2 Frequency LO Nibble Command
  PSGWriteByte(a) // Set Tone Generator #2 Frequency LO Nibble

  ld a,($C00E) // Load Tone Generator #2 Frequency HI Nibble Command To B
  ld b,a
  ld a,($C00D) // Load Tone Generator #2 Frequency LO Nibble To A
  srl a // A >>= 4
  srl a
  srl a
  srl a
  sla b // B <<= 4
  sla b
  sla b
  sla b
  add a,b // A += B
  PSGWriteByte(a) // Set Tone Generator #2 Frequency HI 10-Bit Nibble
  jr Channel2Set
  Channel2OFF:
    PSGWriteByte($BF) // Set Tone Generator #2 Attenuation To "OFF"
  Channel2Set:


  ld a,($C005) // Load Tone Generator #3 Channel To A
  cp 0 // Compare A To Zero
  jr z,Channel3OFF // IF (A == Zero) Channel 3 OFF
  ld a,($C009) // Load Tone Generator #3 Attenuation To A
  add a,$D0 // Add Tone Generator #3 Attenuation Write Upper Nibble Command
  PSGWriteByte(a) // Set Tone Generator #3 Attenuation

  ld a,($C00F) // Load Tone Generator #3 Frequency LO Nibble To A
  and $0F // A &= $F
  add a,$C0 // Add Tone Generator #3 Frequency LO Nibble Command
  PSGWriteByte(a) // Set Tone Generator #3 Frequency LO nibble

  ld a,($C010) // Load Tone Generator #3 Frequency HI Nibble Command To B
  ld b,a
  ld a,($C00F) // Load Tone Generator #3 Frequency LO Nibble To A
  srl a // A >>= 4
  srl a
  srl a
  srl a
  sla b // B <<= 4
  sla b
  sla b
  sla b
  add a,b // A += B
  PSGWriteByte(a) // Set Tone Generator #3 Frequency HI 10-Bit Nibble
  jr Channel3Set
  Channel3OFF:
    PSGWriteByte($DF) // Set Tone Generator #3 Attenuation To "OFF"
  Channel3Set:


  ld a,($C006) // Load Noise Generator Channel To A
  cp 0 // Compare A To Zero
  jr z,Channel4OFF // IF (A == Zero) Channel 4 OFF
  ld a,($C00A) // Load Noise Generator Attenuation To A
  add a,$F0 // Add Noise Generator Attenuation Write Upper Nibble Command
  PSGWriteByte(a) // Set Noise Generator Attenuation

  ld a,($C012) // Load Noise Generator Frequency LO Nibble Command To B
  ld b,a
  ld a,($C011) // Load Noise Generator Frequency HI Nibble To A
  sla a // a <<= 4
  sla a
  add a,b // A += B
  add a,$E0 // A += $E0
  PSGWriteByte(a) // Set Noise Generator Frequency HI 10-Bit Nibble
  jr Channel4Set
  Channel4OFF:
    PSGWriteByte($FF) // Set Noise Generator Attenuation To "OFF"
  Channel4Set:


  jr ChannelALLSet
  ChannelALLOFF:
    PSGWriteByte($9F) // Set Tone Generator #1 Attenuation To "OFF"
    PSGWriteByte($BF) // Set Tone Generator #2 Attenuation To "OFF"
    PSGWriteByte($DF) // Set Tone Generator #3 Attenuation To "OFF"
    PSGWriteByte($FF) // Set Noise Generator   Attenuation To "OFF"
    VDPMAPWrite(TEXTSTOPPEDWhite, 7, $38AC) // Load 7 Tile Map Words To VRAM, Offset By $38AC
  ChannelALLSet:


  ld hl,$C002 // Load Option Selection Mem Address To HL
  TESTPortA(%00000001) // Test Port A Joypad 1 Up Button
  jr nz,JoyNoUp
  dec (hl)
  JoyNoUp:
    TESTPortA(%00000010) // Test Port A Joypad 1 Down Button
    jr nz,JoyNoDown
    inc (hl)
  JoyNoDown:
    ld a,$FF // Check Option Selection Is Not Below Zero
    cp (hl)
    jr nz,NOMax
    ld a,12 // Set Option Selection To 12 IF Below Zero
    ld ($C002),a
  NOMax:
    ld a,12 // Check Option Selection Is Not Higher Than 12
    cp (hl)
    jr nc,NOMin
    ld a,0 // Set Option Selection To Zero IF Above 12
    ld ($C002),a
  NOMin:

  //===========================
  // Tone Generator #1 Channel
  //===========================
  ld a,($C002) // Load Option Selection To A
  cp 0 // Compare A To Tone Generator #1 Channel Selection
  jr z,Channel1Red
  ld hl,TEXTDISABLEDWhite
  jr Channel1
  Channel1Red:
    ld hl,TEXTDISABLEDRed

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Channel1NoLeft
  ld a,($C003)
  dec a
  and $01
  ld ($C003),a
  Channel1NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Channel1
    ld a,($C003)
    inc a
    and $01
    ld ($C003),a
  Channel1:
    // Write Tone Generator #1 Channel Text To VRAM
    ld a,($C003)
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(8, $3924) // Load 8 Tile Map Words To VRAM, Offset By $3924

  //===============================
  // Tone Generator #1 Attenuation
  //===============================
  ld a,($C002) // Load Selection Number To A
  cp 1 // Compare A To Tone Generator #1 Attenuation Selection
  jr z,Attenuation1Red
  ld a,0
  ld ($C001),a
  jr Attenuation1
  Attenuation1Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Attenuation1NoLeft
  ld a,($C007)
  dec a
  and $0F
  ld ($C007),a
  Attenuation1NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Attenuation1
    ld a,($C007)
    inc a
    and $0F
    ld ($C007),a
  Attenuation1:
    // Write Tone Generator #1 Attenuation Byte To VRAM
    ld a,($C007)
    cp 10
    jr c,Attenuation1Hex
    add a,7      
  Attenuation1Hex: 
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3966) // Load 1 Tile Map Word To VRAM Offset By $3966

  //=============================
  // Tone Generator #1 Frequency
  //=============================
  ld a,($C002) // Load Selection Number To A
  cp 2 // Compare A To Tone Generator #1 Frequency Selection
  jr z,Frequency1Red
  ld a,0
  ld ($C001),a
  jr Frequency1
  Frequency1Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Frequency1NoLeft
  ld hl,($C00B)
  dec hl
  ld a,h
  and 3
  ld h,a
  ld ($C00B),hl
  Frequency1NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Frequency1
    ld hl,($C00B)
    inc hl
    ld a,h
    and 3
    ld h,a
    ld ($C00B),hl
  Frequency1:
    // Write Tone Generator #1 Frequency Bytes To VRAM
    ld a,($C00C)
    and $0F
    cp 10
    jr c,Frequency1Hex
    add a,7      
  Frequency1Hex:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $39A6) // Load 1 Tile Map Word To VRAM, Offset By $39A6
    ld a,($C00B)
    srl a
    srl a
    srl a
    srl a
    cp 10
    jr c,Frequency1HexB
    add a,7      
  Frequency1HexB:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $39A8) // Load 1 Tile Map Word To VRAM, Offset By $39A8
    ld a,($C00B)
    and $0F
    cp 10
    jr c,Frequency1HexC
    add a,7      
  Frequency1HexC:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $39AA) // Load 1 Tile Map Word To VRAM, Offset By $39AA

  //===========================
  // Tone Generator #2 Channel
  //===========================
  ld a,($C002) // Load Option Selection To A
  cp 3 // Compare A To Tone Generator #2 Channel Selection
  jr z,Channel2Red
  ld hl,TEXTDISABLEDWhite
  jr Channel2
  Channel2Red:
    ld hl,TEXTDISABLEDRed

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Channel2NoLeft
  ld a,($C004)
  dec a
  and $01
  ld ($C004),a
  Channel2NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Channel2
    ld a,($C004)
    inc a
    and $01
    ld ($C004),a
  Channel2:
    // Write Tone Generator #2 Channel Text To VRAM
    ld a,($C004)
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(8, $3A64) // Load 8 Tile Map Words To VRAM, Offset By $3A64

  //===============================
  // Tone Generator #2 Attenuation
  //===============================
  ld a,($C002) // Load Selection Number To A
  cp 4 // Compare A To Tone Generator #2 Attenuation Selection
  jr z,Attenuation2Red
  ld a,0
  ld ($C001),a
  jr Attenuation2
  Attenuation2Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Attenuation2NoLeft
  ld a,($C008)
  dec a
  and $0F
  ld ($C008),a
  Attenuation2NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Attenuation2
    ld a,($C008)
    inc a
    and $0F
    ld ($C008),a
  Attenuation2:
    // Write Tone Generator #2 Attenuation Byte To VRAM
    ld a,($C008)
    cp 10
    jr c,Attenuation2Hex
    add a,7      
  Attenuation2Hex: 
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3AA6) // Load 1 Tile Map Word To VRAM, Offset By $3AA6

  //=============================
  // Tone Generator #2 Frequency
  //=============================
  ld a,($C002) // Load Selection Number To A
  cp 5 // Compare A To Tone Generator #2 Frequency Selection
  jr z,Frequency2Red
  ld a,0
  ld ($C001),a
  jr Frequency2
  Frequency2Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Frequency2NoLeft
  ld hl,($C00D)
  dec hl
  ld a,h
  and 3
  ld h,a
  ld ($C00D),hl
  Frequency2NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Frequency2
    ld hl,($C00D)
    inc hl
    ld a,h
    and 3
    ld h,a
    ld ($C00D),hl
  Frequency2:
    // Write Tone Generator #2 Frequency Bytes To VRAM
    ld a,($C00E)
    and $0F
    cp 10
    jr c,Frequency2Hex
    add a,7      
  Frequency2Hex:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3AE6) // Load 1 Tile Map Word To VRAM, Offset By $3AE6
    ld a,($C00D)
    srl a
    srl a
    srl a
    srl a
    cp 10
    jr c,Frequency2HexB
    add a,7      
  Frequency2HexB:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3AE8) // Load 1 Tile Map Word To VRAM, Offset By $3AE8
    ld a,($C00D)
    and $0F
    cp 10
    jr c,Frequency2HexC
    add a,7      
  Frequency2HexC:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3AEA) // Load 1 Tile Map Word To VRAM, Offset By $3AEA

  //===========================
  // Tone Generator #3 Channel
  //===========================
  ld a,($C002) // Load Option Selection To A
  cp 6 // Compare A To Tone Generator #3 Channel Selection
  jr z,Channel3Red
  ld hl,TEXTDISABLEDWhite
  jr Channel3
  Channel3Red:
    ld hl,TEXTDISABLEDRed

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Channel3NoLeft
  ld a,($C005)
  dec a
  and $01
  ld ($C005),a
  Channel3NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Channel3
    ld a,($C005)
    inc a
    and $01
    ld ($C005),a
  Channel3:
    // Write Tone Generator #3 Channel Text To VRAM
    ld a,($C005)
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(8, $3BA4) // Load 8 Tile Map Words To VRAM, Offset By $3BA4

  //===============================
  // Tone Generator #3 Attenuation
  //===============================
  ld a,($C002) // Load Selection Number To A
  cp 7 // Compare A To Tone Generator #3 Attenuation Selection
  jr z,Attenuation3Red
  ld a,0
  ld ($C001),a
  jr Attenuation3
  Attenuation3Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Attenuation3NoLeft
  ld a,($C009)
  dec a
  and $0F
  ld ($C009),a
  Attenuation3NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Attenuation3
    ld a,($C009)
    inc a
    and $0F
    ld ($C009),a
  Attenuation3:
    // Write Tone Generator #3 Attenuation Byte To VRAM
    ld a,($C009)
    cp 10
    jr c,Attenuation3Hex
    add a,7      
  Attenuation3Hex: 
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3BE6) // Load 1 Tile Map Word To VRAM, Offset By $3BE6

  //=============================
  // Tone Generator #3 Frequency
  //=============================
  ld a,($C002) // Load Selection Number To A
  cp 8 // Compare A To Tone Generator #3 Frequency Selection
  jr z,Frequency3Red
  ld a,0
  ld ($C001),a
  jr Frequency3
  Frequency3Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Frequency3NoLeft
  ld hl,($C00F)
  dec hl
  ld a,h
  and 3
  ld h,a
  ld ($C00F),hl
  Frequency3NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Frequency3
    ld hl,($C00F)
    inc hl
    ld a,h
    and 3
    ld h,a
    ld ($C00F),hl
  Frequency3:
    // Write Tone Generator #3 Frequency Bytes To VRAM
    ld a,($C010)
    and $0F
    cp 10
    jr c,Frequency3Hex
    add a,7      
  Frequency3Hex:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3C26) // Load 1 Tile Map Word To VRAM, Offset By $3C26
    ld a,($C00F)
    srl a
    srl a
    srl a
    srl a
    cp 10
    jr c,Frequency3HexB
    add a,7      
  Frequency3HexB:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3C28) // Load 1 Tile Map Word To VRAM, Offset By $3C28
    ld a,($C00F)
    and $0F
    cp 10
    jr c,Frequency3HexC
    add a,7      
  Frequency3HexC:
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3C2A) // Load 1 Tile Map Word To VRAM, Offset By $3C2A

  //=========================
  // Noise Generator Channel
  //=========================
  ld a,($C002) // Load Option Selection To A
  cp 9 // Compare A To Noise Generator Channel Selection
  jr z,Channel4Red
  ld hl,TEXTDISABLEDWhite
  jr Channel4
  Channel4Red:
    ld hl,TEXTDISABLEDRed

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Channel4NoLeft
  ld a,($C006)
  dec a
  and $01
  ld ($C006),a
  Channel4NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Channel4
    ld a,($C006)
    inc a
    and $01
    ld ($C006),a
  Channel4:
    // Write Noise Generator Channel Text To VRAM
    ld a,($C006)
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(8, $3CE4) // Load 8 Tile Map Words To VRAM, Offset By $3CE4

  //=============================
  // Noise Generator Attenuation
  //=============================
  ld a,($C002) // Load Selection number To A
  cp 10 // Compare A To Noise Generator Attenuation Selection
  jr z,Attenuation4Red
  ld a,0
  ld ($C001),a
  jr Attenuation4
  Attenuation4Red:
    ld a,8
    ld ($C001),a

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,Attenuation4NoLeft
  ld a,($C00A)
  dec a
  and $0F
  ld ($C00A),a
  Attenuation4NoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,Attenuation4
    ld a,($C00A)
    inc a
    and $0F
    ld ($C00A),a
  Attenuation4:
    // Write Noise Generator Attenuation Byte To VRAM
    ld a,($C00A)
    cp 10
    jr c,Attenuation4Hex
    add a,7      
  Attenuation4Hex: 
    add a,48
    ld ($C000),a
    VDPMAPWrite($C000, 1, $3D26) // Load 1 Tile Map Word To VRAM, Offset By $3D26

  //======================
  // Noise Generator Type
  //======================
  ld a,($C002) // Load Option Selection To A
  cp 11 // Compare A To Noise Generator Type Selection
  jr z,NoiseTypeRed
  ld hl,TEXTPERIODICWhite
  jr NoiseType
  NoiseTypeRed:
    ld hl,TEXTPERIODICRed

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,NoiseTypeNoLeft
  ld a,($C011)
  dec a
  and $01
  ld ($C011),a
  NoiseTypeNoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,NoiseType
    ld a,($C011)
    inc a
    and $01
    ld ($C011),a
  NoiseType:
    // Write Noise Generator Type Text To VRAM
    ld a,($C011)
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(8, $3D64) // Load 8 Tile Map Words To VRAM, Offset By $3D64

  //==============================
  // Noise Generator Clock Source
  //==============================
  ld a,($C002) // Load Option Selection To A
  cp 12 // Compare A To Noise Generator Clock Source Selection
  jr z,NoiseClockSourceRed
  ld hl,TEXTCLOCK2White
  jr NoiseClockSource
  NoiseClockSourceRed:
    ld hl,TEXTCLOCK2Red

  TESTPortA(%00000100) // Test Port A Joypad 1 Left Button
  jr nz,NoiseClockSourceNoLeft
  ld a,($C012)
  dec a
  and $03
  ld ($C012),a
  NoiseClockSourceNoLeft:
    TESTPortA(%00001000) // Test Port A Joypad 1 Right Button
    jr nz,NoiseClockSource
    ld a,($C012)
    inc a
    and $03
    ld ($C012),a
  NoiseClockSource:
    // Write Noise Generator Clock Source Text To VRAM
    ld a,($C012)
    sla a
    sla a
    sla a
    sla a
    sla a
    ld d,0
    ld e,a
    add hl,de
    VDPMAPWriteHL(11, $3DA4) // Load 11 Tile Map Words To VRAM, Offset By $3DA4      

  jp Refresh

BGPAL: // Include BG Palette Data
  include "FontPAL.asm"

BGCHR: // Include BG 12BPP 8x8 Tile Font Character Data
  include "Font8x8.asm"

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
TEXTSMSAUDIOPLAYER:
  dw "SMS AUDIO PLAYER " // Font Tiles Palette 2

map ' ', $0020, 95 // Map Char Table, Normal Tiles, Palette 1
  dw "V1.0 By krom" // Font Tiles Palette 1

TEXTToneGenerator1:
  dw "Tone Generator #1:" // Font Tiles Palette 1
TEXTToneGenerator2:
  dw "Tone Generator #2:" // Font Tiles Palette 1
TEXTToneGenerator3:
  dw "Tone Generator #3:" // Font Tiles Palette 1
TEXTNoiseGenerator:
  dw "Noise Generator:" // Font Tiles Palette 1
TEXTChannel:
  dw "Channel:" // Font Tiles Palette 1
TEXTAttenuation:
  dw "Attenuation:  $" // Font Tiles Palette 1
TEXTFrequency:
  dw "Frequency:    $" // Font Tiles Palette 1
TEXTType:
  dw "Type:" // Font Tiles Palette 1
TEXTClockSource:
  dw "Clock Source:" // Font Tiles Palette 1

TEXTDISABLEDWhite:
  dw "DISABLED" // Font Tiles Palette 1
TEXTENABLEDWhite:
  dw "ENABLED " // Font Tiles Palette 1

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
TEXTDISABLEDRed:
  dw "DISABLED" // Font Tiles Palette 2
TEXTENABLEDRed:
  dw "ENABLED " // Font Tiles Palette 2

map ' ', $0020, 95 // Map Char Table, Normal Tiles, Palette 1
TEXTPERIODICWhite:
  dw "PERIODIC" // Font Tiles Palette 1
TEXTWHITEWhite:
  dw "WHITE   " // Font Tiles Palette 1

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
TEXTPERIODICRed:
  dw "PERIODIC" // Font Tiles Palette 2
TEXTWHITERed:
  dw "WHITE   " // Font Tiles Palette 2

map ' ', $0020, 95 // Map Char Table, Normal Tiles, Palette 1
TEXTCLOCK2White:
  dw "CLOCK/2         " // Font Tiles Palette 1
TEXTCLOCK4White:
  dw "CLOCK/4         " // Font Tiles Palette 1
TEXTCLOCK8White:
  dw "CLOCK/8         " // Font Tiles Palette 1
TEXTTONEGEN3White:
  dw "TONE GEN #3     " // Font Tiles Palette 1

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
TEXTCLOCK2Red:
  dw "CLOCK/2         " // Font Tiles Palette 2
TEXTCLOCK4Red:
  dw "CLOCK/4         " // Font Tiles Palette 2
TEXTCLOCK8Red:
  dw "CLOCK/8         " // Font Tiles Palette 2
TEXTTONEGEN3Red:
  dw "TONE GEN #3     " // Font Tiles Palette 2

map ' ', $0020, 95 // Map Char Table, Normal Tiles, Palette 1
TEXTSTOPPEDWhite:
  dw "STOPPED" // Font Tiles Palette 1

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
TEXTPLAYINGRed:
  dw "PLAYING" // Font Tiles Palette 2