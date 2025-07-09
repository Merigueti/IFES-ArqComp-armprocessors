MOV R0, #0b1100      // R0 = 1100 (12 em decimal)
MOV R1, #0b1010      // R1 = 1010 (10 em decimal)
EOR R2, R0, R1         // R2 = R0 XOR R1
EOR R3, R0, #0b1111  // R3 = R0 XOR 1111
EOR R0, R0, #0b0110  // R0 = R0 XOR 0110