//===========
// SMS Input
//===========
// %DUBARLDU: U = Joy1Up, D = Joy1Down, L = Joy1Left, R = Joy1Right, A = Joy1A, B = Joy1B, U = Joy2Up, D = Joy2Down
// Test Port A Joypad Status Register
macro TESTPortA(STATUS) { // STATUS = Bitfield To Compare
  in a,($DC) // A = Joypad Status Register (PortA)
  and {STATUS}
}

// %000RBARL: L = Joy2Left, R = Joy2Right, A = Joy2A, B = Joy2B, R = Reset Button
// Test Port B Joypad Status Register
macro TESTPortB(STATUS) { // STATUS = Bitfield To Compare
  in a,($DD) // A = Joypad Status Register (PortB)
  and {STATUS}
}