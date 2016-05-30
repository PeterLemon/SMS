//============
// SMS Header
//============
seek($7FF0) // Header Can Be At Offset $1FF0, $3FF0 Or $7FF0
db "TMR SEGA" // ($7FF0) Required For Export Master System & Game Gear BIOS
db 0, 0 // ($7FF8) Reserved Space, Can Be $20,$20 For 2 ASCII Spaces e.g "TMR SEGA__"
db 0, 0 // ($7FFA) Little-Endian Word ROM Checksum For Export Master System BIOS
  
// BCD Product Code = 15027 / Version Number = 0 ($7FFC)
db $27, $50, $10 // BCD Product Code 2.5 Bytes / Version Number 0.5 Bytes
                 // Byte 3    2    1             Byte 3
                 // Bits 4..7 0..7 0..7          Bits 0..3
                 // Value Product Code           Value Version Number
                 //      $1   $50  $27           $0

// Region Code = SMS Export / ROM Size = 128KB ($7FFF)
db $4F // Region Code 0.5 Bytes / ROM Size 0.5 Bytes:
       // Bits 4..7               Bits 0..3
       // Value System / Region   Value Rom Size Comment
       // $3    SMS Japan         $A    8KB      Unused
       // $4    SMS Export        $B    16KB     Unused
       // $5    GG Japan          $C    32KB
       // $6    GG Export         $D    48KB     Unused Buggy
       // $7    GG International  $E    64KB     Rarely Used
       //                         $F    128KB
       //                         $0    256KB
       //                         $1    512KB    Rarely Used
       //                         $2    1MB      Unused Buggy