.threads 8
.data 1 2 3 4 2 6 7 1 2 1 1 2 3 4 5 3      ; matrix A (1x16)
.data 1 2 3 4 2 3 2 3 1 1 1 2 3 4 5 2      ; matrix B (16x1)
.data 0 0 0 0 0 0 0 0                          ; matrix C (8 partial sums) 初期化

; 各スレッドが異なるC[t]にアクセスしてC[t] = A[2*t] * B[2*t] + A[2*t+1] * B[2*t+1]
CONST R1, #1                   ; increment
CONST R2, #2                   ; N (number of k steps per thread)
CONST R3, #0                   ; baseA (matrix A base address)
CONST R4, #16                  ; baseB (matrix B base address)
CONST R5, #32                  ; baseC (matrix C base address)

; 計算: t = blockIdx * blockDim + threadIdx
MUL R0, %blockIdx, %blockDim
ADD R0, R0, %threadIdx         ; t = blockIdx * blockDim + threadIdx (0..7)

; tに基づいて各スレッドが処理するAとBのインデックスを計算
MUL R6, R0, R2                 ; R6 = t * 2
; 以下の命令は不要なため削除
; ADD R6, R6, #0                 ; R6 = t*2 +0 (スタートインデックス)

CONST R8, #0                   ; acc = 0
CONST R9, #0                   ; k = 0

LOOP:
    ; Aのインデックス計算: a_idx = t*2 + k
    ADD R10, R6, R9              ; R10 = t*2 + k
    ADD R10, R10, R3             ; addr(A[a_idx]) = baseA + a_idx
    LDR R10, R10                 ; load A[a_idx] from global memory

    ; Bのインデックス計算: b_idx = t*2 + k
    ADD R11, R6, R9              ; R11 = t*2 + k
    ADD R11, R11, R4             ; addr(B[b_idx]) = baseB + b_idx
    LDR R11, R11                 ; load B[b_idx] from global memory

    ; 積の計算: A[a_idx] * B[b_idx]
    MUL R12, R10, R11            ; R12 = A[a_idx] * B[b_idx]
    ADD R8, R8, R12              ; acc += A[a_idx] * B[b_idx]

    ; kのインクリメント
    ADD R9, R9, R1               ; k +=1

    ; ループの継続条件チェック: k < N
    CMP R9, R2
    BRn LOOP                      ; loop while k < N

; 部分合計の格納: C[t] = acc
ADD R10, R5, R0                   ; addr(C[t]) = baseC + t
STR R10, R8                       ; store C[t] = acc in global memory

RET                              ; end of kernel
