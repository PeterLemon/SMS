// SMS "Hello, World!" Text Printing demo by krom (Peter Lemon):
// 1. Load BG Palette Data To CRAM
// 2. Load BG Tile Data To VRAM
// 3. Print Text Characters To BG Map VRAM
// 4. Turn Display On
arch sms.cpu
output "HelloWorld.sms", create

macro seek(variable offset) {
  origin offset
  base offset
}

// BANK 0..7 (128KB)
seek($0000); fill $20000 // Fill Bank 0..7 With Zero Bytes
include "LIB\SMS_HEADER.ASM" // Include SMS Header
include "LIB\SMS_VDP.ASM" // Include VDP Macros

seek($0000)
di // Disable Interrupts
im 1 // Set Interrupt Mode 1
jp Start

seek($0100); Start:
// Load Palette
SMSPALWrite(BGPAL, 32, 0) // Load 32 Colors To CRAM, Offset By 0 Colors

// Load Tile Characters
VDPCHRWrite(BGCHR, 95, $400) // Load 95 8x8 Tiles To VRAM, Offset By $400

// Load Tile Map A
VDPMAPWrite(BGMAPA, 13, $3912) // Load 13 Tile Map Words To VRAM, Offset By $3912

// Load Tile Map B
VDPMAPWrite(BGMAPB, 13, $3992) // Load 13 Tile Map Words To VRAM, Offset By $3992

// Load Tile Map C
VDPMAPWrite(BGMAPC, 13, $3A12) // Load 13 Tile Map Words To VRAM, Offset By $3A12

// Load Tile Map D
VDPMAPWrite(BGMAPD, 13, $3A92) // Load 13 Tile Map Words To VRAM, Offset By $3A92

// Write VDP Register 1 (Turn Display On)
VDPREGWrite(%11100000, 1) // Write VDP Register 1 Data (%1DI000S0 D = Display 0: Off 1: On, I = Interrupts 0: Off 1: On, S = Sprite Size 0: 8x8 1: 8x16)

Loop:
  jr Loop

BGPAL: // Include BG Palette Data
  include "FontPAL.asm"

BGCHR: // Include BG 12BPP 8x8 Tile Font Character Data
  include "Font8x8.asm"

map ' ', $0020, 95 // Map Char Table, Normal Tiles, Palette 1
BGMAPA:
  dw "Hello, World!" // Hello World Text (26 Bytes)

map ' ', $0620, 95 // Map Char Table, Tile XY Flip, Palette 1
BGMAPB:
  dw "Hello, World!" // Hello World Text (26 Bytes)

map ' ', $0820, 95 // Map Char Table, Normal Tiles, Palette 2
BGMAPC:
  dw "Hello, World!" // Hello World Text (26 Bytes)

map ' ', $0E20, 95 // Map Char Table, Tile XY Flip, Palette 2
BGMAPD:
  dw "Hello, World!" // Hello World Text (26 Bytes)