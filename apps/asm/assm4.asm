.threads 8
.fdata 10 2 3 4 2 6 7 8 1 2 3 4 5 6 7 8      ; matrix A (1x16)
.fdata -1 2 3 4 2 6 7 8 1 2 3 4 5 6 7 8      ; matrix B (16x1)
.data 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0              ; matrix C (16 partial products) initialization

; Set up constants
CONST R1, #1                   ; increment
CONST R2, #16                  ; total number of elements
CONST R3, #0                   ; baseA (matrix A base address)
CONST R4, #16                  ; baseB (matrix B base address)
CONST R5, #32                  ; baseC (matrix C base address)

CONST R6, #0                   ; index i = 0

LOOP:
    ; Load A[i] and B[i]
    ADD R7, R3, R6              ; addr(A[i]) = baseA + i
    LDR R8, R7                  ; load A[i] from global memory

    ADD R7, R4, R6              ; addr(B[i]) = baseB + i
    LDR R9, R7                  ; load B[i] from global memory

    ; Compute A[i] * B[i]
    FMUL R10, R8, R9            ; R10 = A[i] * B[i]

    ; Store the result in C[i]
    ADD R7, R5, R6              ; addr(C[i]) = baseC + i
    STR R7, R10                 ; store C[i] = A[i] * B[i] in global memory

    ; Increment i
    ADD R6, R6, R1              ; i += 1

    ; Check loop condition: i < 16
    CMP R6, R2
    BRn LOOP                    ; loop while i < 16

RET                             ; end of kernel
