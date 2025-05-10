program = [
    0b0101000011011110, #MUL R0; %blockIdx; %blockDim
    0b0011000000001111, #ADD R0; R0; %threadIdx  ; i = blockIdx * blockDim + threadIdx
    0b1001000100000001, #CONST R1; #1
    0b1001101100001000, #CONST R11; #8  ; w start address(0x08)
    0b1001010100000000, #CONST R5 #0  ; x value
    0b0111010001010000, #LDR R4; R5  ; R4 <= MEM(0x00)
    0b1001010100000001, #CONST R5; #1  ; R2: data num
    0b0111001001010000, #LDR R2; R5  ; R2 <= MEM(0x01)
    0b1001010100000010, #CONST R5; #2  ; R3: write address start
    0b0111001101010000, #LDR R3; R5  ; R3 <= MEM(0x02)
    0b1001010100001000, #CONST R5; #8                       : R5: read address start
    0b1001100000000000, #CONST R8; #0
    0b1001100100000011, #CONST R9; #3
    0b1001101000001000, #CONST R10; #8
    0b0110100100101010, #DIV R9 R2 R10  ; (data num) / 8
    # LOOP:
    0b0011010110110000, #ADD R5; R11; R0  ; addr(W[i]) = base + i
    0b0111011001010000, #LDR R6; R5  ; load B[i] from global memory
    0b1101011001000110, #FMUL R6; R4; R6  ; C[i] = X * W[i]
    0b0011011100110000, #ADD R7; R3; R0  ; addr(C[i]) = baseC + i
    0b1000000001110110, #STR R7; R6  ; store C[i] in global memory
    0b0011100010000001, #ADD R8; R8; R1  ; R8 = R8 + 1
    0b0011101110111010, #ADD R11; R11; R10
    0b0011001100111010, #ADD R3; R3; R10
    0b0010000010001001, #CMP R8; R9
    0b0001100000001111, #BRn LOOP  ; loop while i < data num
    0b1111000000000000 #RET  ; end of kernel
]
