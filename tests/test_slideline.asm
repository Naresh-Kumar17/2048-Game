; ============================================================
; test_slideline.asm - M5-P4: unit tests for SlideLine
; TEST PROJECT = this file + logic.asm (+ game_macros.inc, module.inc).
; Do NOT add data.asm: this file defines its own globals.
;
; Each case describes ONE line:
;   first  = lowest cell index of the line
;   stride = distance between cells in cells (1 = row, N = column)
;   len    = cells in the line
;   rev    = 0 travel toward higher index (Left/Up start),
;            1 travel from the highest cell (Right/Down start)
;   in[8]  = tile values, lowest cell first
;   exp[8] = expected values after SlideLine, lowest cell first
;   gain, moved = expected return values
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC boardN, target, board, score, bestScore

; ---- record layout (bytes) ----
C_FIRST   EQU 0
C_STRIDE  EQU 4
C_LEN     EQU 8
C_REV     EQU 12
C_IN      EQU 16
C_EXP     EQU 48
C_GAIN    EQU 80
C_MOVED   EQU 84
REC_SIZE  EQU 88
NUM_CASES EQU 15

.data
boardN    DWORD 4
target    DWORD 2048
board     DWORD MAX_CELLS DUP(0)
score     DWORD 0
bestScore DWORD 0
recPtr    DWORD ?
caseNo    DWORD ?
passCnt   DWORD ?

sPass  BYTE "PASS  case ",0
sFail  BYTE "FAIL  case ",0
sTotal BYTE 0Dh,0Ah,"Passed: ",0
sOf    BYTE " of 15",0Dh,0Ah,0

;          first,stride,len,rev |      in[8]       |      exp[8]      | gain,moved
cases DWORD 0,1,4,0,  2,2,0,0,0,0,0,0,  4,0,0,0,0,0,0,0,  4,1    ;  1 [2 2 0 0] left
      DWORD 0,1,4,1,  2,2,0,0,0,0,0,0,  0,0,0,4,0,0,0,0,  4,1    ;  2 [2 2 0 0] right
      DWORD 0,1,4,0,  2,2,2,2,0,0,0,0,  4,4,0,0,0,0,0,0,  8,1    ;  3 [2 2 2 2] merge once each
      DWORD 0,1,4,0,  4,2,2,0,0,0,0,0,  4,4,0,0,0,0,0,0,  4,1    ;  4 [4 2 2 0] no chaining
      DWORD 0,1,4,0,  2,4,2,4,0,0,0,0,  2,4,2,4,0,0,0,0,  0,0    ;  5 nothing to do
      DWORD 0,1,4,0,  0,2,0,2,0,0,0,0,  4,0,0,0,0,0,0,0,  4,1    ;  6 gaps then merge
      DWORD 0,1,4,1,  2,0,2,4,0,0,0,0,  0,0,4,4,0,0,0,0,  4,1    ;  7 reverse, gaps
      DWORD 0,1,4,0,  4,0,0,0,0,0,0,0,  4,0,0,0,0,0,0,0,  0,0    ;  8 already packed
      DWORD 0,1,4,0,  0,0,0,2,0,0,0,0,  2,0,0,0,0,0,0,0,  0,1    ;  9 pack only, no merge
      DWORD 0,4,4,0,  0,2,0,2,0,0,0,0,  4,0,0,0,0,0,0,0,  4,1    ; 10 column, step +4N
      DWORD 0,4,4,1,  2,0,2,4,0,0,0,0,  0,0,4,4,0,0,0,0,  4,1    ; 11 column reverse, -4N
      DWORD 0,1,8,0,  2,0,0,0,0,0,0,2,  4,0,0,0,0,0,0,0,  4,1    ; 12 length 8 forward
      DWORD 0,1,8,1,  2,0,0,0,0,0,0,2,  0,0,0,0,0,0,0,4,  4,1    ; 13 length 8 reverse
      DWORD 0,1,3,0,  2,2,2,0,0,0,0,0,  4,2,0,0,0,0,0,0,  4,1    ; 14 length 3
      DWORD 0,1,4,1,  2,2,4,4,0,0,0,0,  0,0,4,8,0,0,0,0, 12,1    ; 15 two merges, reverse

.code
ClearAll PROC USES eax ecx edi
    cld
    mov edi, OFFSET board
    mov ecx, MAX_CELLS
    xor eax, eax
    rep stosd
    ret
ClearAll ENDP

; RunCase(rec) -> EAX = 1 pass, 0 fail
RunCase PROC USES ebx ecx edx esi edi, rec:DWORD
    LOCAL gainGot:DWORD, movedGot:DWORD, ok:DWORD
    mov ok, 1
    call ClearAll
    mov esi, rec

    ; place the line: cell k of the line sits at FIRST + k*STRIDE
    xor ebx, ebx
placeLoop:
    mov eax, ebx
    imul eax, [esi + C_STRIDE]
    add eax, [esi + C_FIRST]
    mov edx, [esi + C_IN + ebx * 4]
    mov board[eax * 4], edx
    inc ebx
    cmp ebx, [esi + C_LEN]
    jb  placeLoop

    ; start address and signed byte step
    mov edx, [esi + C_STRIDE]
    shl edx, 2                      ; EDX = forward step in bytes
    mov ebx, [esi + C_FIRST]
    shl ebx, 2
    add ebx, OFFSET board           ; EBX = address of the lowest cell
    cmp DWORD PTR [esi + C_REV], 0
    je  callSlide
    mov eax, [esi + C_LEN]
    dec eax
    imul eax, edx                   ; (len - 1) * step
    add ebx, eax                    ; start at the highest cell
    neg edx                         ; and walk backwards
callSlide:
    INVOKE SlideLine, ebx, edx, DWORD PTR [esi + C_LEN]
    mov gainGot, eax
    mov movedGot, edx

    mov eax, gainGot
    cmp eax, [esi + C_GAIN]
    je  gainOk
    mov ok, 0
gainOk:
    mov eax, movedGot
    cmp eax, [esi + C_MOVED]
    je  movedOk
    mov ok, 0
movedOk:
    xor ebx, ebx
cmpLoop:
    mov eax, ebx
    imul eax, [esi + C_STRIDE]
    add eax, [esi + C_FIRST]
    mov edx, board[eax * 4]
    cmp edx, [esi + C_EXP + ebx * 4]
    je  cellOk
    mov ok, 0
cellOk:
    inc ebx
    cmp ebx, [esi + C_LEN]
    jb  cmpLoop
    mov eax, ok
    ret
RunCase ENDP

main PROC
    mov recPtr, OFFSET cases
    mov caseNo, 1
    mov passCnt, 0
nextCase:
    INVOKE RunCase, recPtr
    mov edx, OFFSET sFail
    test eax, eax
    jz  show
    mov edx, OFFSET sPass
    inc passCnt
show:
    call WriteString
    mov eax, caseNo
    call WriteDec
    call Crlf
    add recPtr, REC_SIZE
    inc caseNo
    cmp caseNo, NUM_CASES
    jbe nextCase

    mov edx, OFFSET sTotal
    call WriteString
    mov eax, passCnt
    call WriteDec
    mov edx, OFFSET sOf
    call WriteString
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP
END main
