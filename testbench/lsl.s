MOV     R0, #0x1         // Carrega 0x1 em R0
MOV     R1, R0, LSL #1   // R1 = R0 << 1 (deverá resultar em 0x2)
MOV     R4, #0xF 
// Teste 2: Deslocar 0x1 quatro posições para a esquerda
MOV     R2, #0x1         // Carrega 0x1 em R2

                    B
MOV     R3, R2, LSL #4   // R3 = R2 << 4 (deverá resultar em 0x10)

// Teste 3: Deslocar 0xF duas posições para a esquerda
MOV     R4, #0xF         // Carrega 0xF em R4
MOV     R5, R4, LSL #2   // R5 = R4 << 2 (deverá resultar em 0x3C)

// Teste 4: Deslocar 0x80000000 uma posição (testando overflow)
LDR     R6, =0x80000000  // Carrega 0x80000000 em R6
MOV     R7, R6, LSL #1   // R7 = R6 << 1 (deverá resultar em 0x00000000)

// Teste 5: Deslocar 0x12345678 oito posições
LDR     R8, =0x12345678  // Carrega 0x12345678 em R8
MOV     R9, R8, LSL #8 