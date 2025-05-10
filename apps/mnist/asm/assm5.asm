.threads 8
.fdata 0 1 2 3 4 5 6 7          ; matrix A (1 x 8) dummy
.fdata 0 1 2 3 4 5 6 7          ; matrix B (1 x 8) dummy

MUL R0, %blockIdx, %blockDim
ADD R0, R0, %threadIdx         ; i = blockIdx * blockDim + threadIdx

CONST R1, #1                       ; 
CONST R11, #8                      ; w start address(0x08)

CONST R5 #0                        ; x value
LDR R4, R5                         ; R4 <= MEM(0x00)

CONST R5, #1                       ; R2: data num
LDR R2, R5                         ; R2 <= MEM(0x01)

CONST R5, #2                       ; R3: write address start
LDR R3, R5                         ; R3 <= MEM(0x02)

CONST R5, #8                       : R5: read address start
CONST R8, #0
CONST R9, #3
CONST R10, #8

DIV R9 R2 R10                       ; (data num) / 8

LOOP:

    ADD R5, R11, R0                 ; addr(W[i]) = base + i
    LDR R6, R5                     ; load B[i] from global memory

    FMUL R6, R4, R6                 ; C[i] = X * W[i]

    ADD R7, R3, R0                 ; addr(C[i]) = baseC + i
    STR R7, R6                     ; store C[i] in global memory
    ;STR R7, R0

    ; Increment i
    ADD R8, R8, R1                 ; R8 = R8 + 1
    
    ; Address incriment
    ADD R11, R11, R10
    ADD R3, R3, R10

    ; Check loop condition: i < R9
    CMP R8, R9
    BRn LOOP                       ; loop while i < data num

RET                                ; end of kernel
