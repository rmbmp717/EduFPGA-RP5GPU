program = [
    0b0101000011011110, #MUL R0; %blockIdx; %blockDim
    0b0011000000001111, #ADD R0; R0; %threadIdx  ; i = blockIdx * blockDim + threadIdx
    0b0101000011011110, #MUL R0; %blockIdx; %blockDim
    0b0011000000001111, #ADD R0; R0; %threadIdx  ; i = blockIdx * blockDim + threadIdx
    0b1001000100000000, #CONST R1; #0  ; baseA (matrix A base address)
    0b1001001000001000, #CONST R2; #8  ; baseB (matrix B base address)
    0b1001001100010000, #CONST R3; #16  ; baseC (matrix C base address)
    # LOOP:
    0b1001010000000000, #CONST R4 #0
    0b0111010001000000, #LDR R4; R4  ; load A[i] from global memory
    0b0011010100100000, #ADD R5; R2; R0  ; addr(B[i]) = baseB + i
    0b0111010101010000, #LDR R5; R5  ; load B[i] from global memory
    0b1101011001000101, #FMUL R6; R4; R5  ; C[i] = A[i] + B[i]
    0b0011011100110000, #ADD R7; R3; R0  ; addr(C[i]) = baseC + i
    0b1000000001110110, #STR R7; R6  ; store C[i] in global memory
    0b0011011001100001, #ADD R6; R6; R1  ; i += 1
    0b0010000001100010, #CMP R6; R2
    0b0001100000000111, #BRn LOOP  ; loop while i < 16
    0b1111000000000000 #RET  ; end of kernel
]
