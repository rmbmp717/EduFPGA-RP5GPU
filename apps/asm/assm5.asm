.threads 8
.fdata 0 1 2 3 4 5 6 7          ; matrix A (1 x 8) dummy
.fdata 0 1 2 3 4 5 6 7          ; matrix B (1 x 8) dummy

MUL R0, %blockIdx, %blockDim
ADD R0, R0, %threadIdx             ; i = blockIdx * blockDim + threadIdx

CONST R1, #8                       ; 

CONST R4 #0                        ; x value
LDR R4, R4                         ; R4 <= MEM(0x00)

CONST R4, #1                       ; R2: data num
LDR R2, R4                         ; R2 <= MEM(0x01)

CONST R4, #2                       ; R3: write address start
LDR R3, R4                         ; R3 <= MEM(0x02)

CONST R5, #8                       : R5: read address start

LOOP:

    ADD R5, R2, R0                 ; addr(W[i]) = base + i
    LDR R5, R5                     ; load B[i] from global memory

    FMUL R6, R4, R5                 ; C[i] = X * W[i]

    ADD R7, R3, R0                 ; addr(C[i]) = baseC + i
    STR R7, R6                     ; store C[i] in global memory

    ; Increment i
    ADD R6, R6, R1                 ; i += 8
    ADD R5, R5, R1                 ; i += 8
    
    ; Check loop condition: i < R2
    CMP R6, R2
    BRn LOOP                       ; loop while i < data num

RET                                ; end of kernel
