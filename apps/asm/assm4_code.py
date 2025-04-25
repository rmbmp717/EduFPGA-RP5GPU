program = [
    0b1001000100000001, #CONST R1; #1  ; increment
    0b1001001000010000, #CONST R2; #16  ; total number of elements
    0b1001001100000000, #CONST R3; #0  ; baseA (matrix A base address)
    0b1001010000010000, #CONST R4; #16  ; baseB (matrix B base address)
    0b1001010100100000, #CONST R5; #32  ; baseC (matrix C base address)
    0b1001011000000000, #CONST R6; #0  ; index i = 0
    # LOOP:
    0b0011011100110110, #ADD R7; R3; R6  ; addr(A[i]) = baseA + i
    0b0111100001110000, #LDR R8; R7  ; load A[i] from global memory
    0b0011011101000110, #ADD R7; R4; R6  ; addr(B[i]) = baseB + i
    0b0111100101110000, #LDR R9; R7  ; load B[i] from global memory
    0b1101101010001001, #FMUL R10; R8; R9  ; R10 = A[i] * B[i]
    0b0011011101010110, #ADD R7; R5; R6  ; addr(C[i]) = baseC + i
    0b1000000001111010, #STR R7; R10  ; store C[i] = A[i] * B[i] in global memory
    0b0011011001100001, #ADD R6; R6; R1  ; i += 1
    0b0010000001100010, #CMP R6; R2
    0b0001100000000110, #BRn LOOP  ; loop while i < 16
    0b1111000000000000 #RET  ; end of kernel
]
