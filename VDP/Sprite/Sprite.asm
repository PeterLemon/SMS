// SMS Sprite demo by krom (Peter Lemon):
// 1. Load BG/Sprite Palette Data To CRAM
// 2. Load BG/Sprite Tile Data To VRAM
// 3. Set Sprite Vertical/Horizontal Position
// 4. Turn Display On
arch sms.cpu
output "Sprite.sms", create

macro seek(variable offset) {
  origin offset
  base offset
}

// BANK 0..7 (128KB)
seek($0000); fill $20000 // Fill Bank 0..7 With Zero Bytes
include "LIB/SMS_HEADER.ASM" // Include SMS Header
include "LIB/SMS_VDP.ASM" // Include VDP Macros

seek($0000)
di // Disable Interrupts
im 1 // Set Interrupt Mode 1
jp Start

seek($0100); Start:
// Load Palette
SMSPALWrite(BGSPRPAL, 32, 0) // Load 32 GG Colors To CRAM, Offset By 0 Colors

// Load Tile Characters
VDPCHRWrite(BGSPRCHR, 4, 0) // Load 4 8x8 Tiles To VRAM, Offset By 0 (1st Tile is BG Default)

// Set Sprite Vertical Positions
VDPVRAMWrite(SPRVPOS, 3, $3F00) // Write 3 Vertical Position Bytes To VRAM, Offset By $3F00

// Set Sprites Horizontal Positions & Character #'s
VDPVRAMWrite(SPRHPOSCHR, 6, $3F80) // Write 3 Horizontal Position Bytes & 3 Character # Bytes Interleaved To VRAM, Offset By $3F80

// Write VDP Register 1 (Turn Display On)
VDPREGWrite(%11100000, 1) // Write VDP Register 1 Data (%1DI000S0 D = Display 0: Off 1: On, I = Interrupts 0: Off 1: On, S = Sprite Size 0: 8x8 1: 8x16)

Loop:
  jr Loop

BGSPRPAL: // Include BG / Sprite Palette Data
  include "BGSPRPAL.asm"

BGSPRCHR: // Include BG 12BPP 8x8 Tile Font Character Data
  include "BGSPRCHR.asm"

SPRVPOS: // Include 3 * Sprite Vertical Positions
  db 92, 92, 92

SPRHPOSCHR: // Include 3 * Sprite Horizontal Positions / Character #'s
  db 116, 1, 124, 2, 132, 3