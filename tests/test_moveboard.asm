; ============================================================
; test_moveboard.asm - M6-P3: MoveBoard on N = 3, 4 and 8
; TEST PROJECT = this file + logic.asm (+ game_macros.inc, module.inc).
; Do NOT add data.asm: this file defines its own globals.
;
; Part A: 10 whole-board cases for N = 3 and N = 4 (data-driven).
; Part B: 4 cases for N = 8 (a tile in each corner, all 4 moves).
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC boardN, target, board, score, bestScore

NUM_MV  EQU 10
MV_REC  EQU 24                      ; N, dir, in*, exp*, gain, moved

.data
boardN    DWORD 4
target    DWORD 2048
board     DWORD MAX_CELLS DUP(0)
score     DWORD 0
bestScore DWORD 0
recPtr    DWORD ?
n8Ptr     DWORD ?
tmp       DWORD ?

; ---- N = 4 boards ----
a4   DWORD 2,2,0,0,   0,2,0,2,   4,0,4,0,   2,4,8,16
a4L  DWORD 4,0,0,0,   4,0,0,0,   8,0,0,0,   2,4,8,16      ; gain 16
a4R  DWORD 0,0,0,4,   0,0,0,4,   0,0,0,8,   2,4,8,16      ; gain 16
a4U  DWORD 2,4,4,2,   4,4,8,16,  2,0,0,0,   0,0,0,0       ; gain 4
a4D  DWORD 0,0,0,0,   2,0,0,0,   4,4,4,2,   2,4,8,16      ; gain 4
b4   DWORD 2,4,8,0,   0,0,0,0,   0,0,0,0,   0,0,0,0       ; Left / Up change nothing

; ---- N = 3 boards ----
a3   DWORD 2,2,2,   0,0,0,   4,4,0
a3L  DWORD 4,2,0,   0,0,0,   8,0,0                         ; gain 12
a3R  DWORD 0,2,4,   0,0,0,   0,0,8                         ; gain 12
a3U  DWORD 2,2,2,   4,4,0,   0,0,0                         ; gain 0, moved
a3D  DWORD 0,0,0,   2,2,0,   4,4,2                         ; gain 0, moved

;        N, dir,       input,      expected,    gain, moved
mvCases DWORD 4, DIR_LEFT,  OFFSET a4, OFFSET a4L, 16, 1
        DWORD 4, DIR_RIGHT, OFFSET a4, OFFSET a4R, 16, 1
        DWORD 4, DIR_UP,    OFFSET a4, OFFSET a4U,  4, 1
        DWORD 4, DIR_DOWN,  OFFSET a4, OFFSET a4D,  4, 1
        DWORD 4, DIR_LEFT,  OFFSET b4, OFFSET b4,   0, 0
        DWORD 4, DIR_UP,    OFFSET b4, OFFSET b4,   0, 0
        DWORD 3, DIR_LEFT,  OFFSET a3, OFFSET a3L, 12, 1
        DWORD 3, DIR_RIGHT, OFFSET a3, OFFSET a3R, 12, 1
        DWORD 3, DIR_UP,    OFFSET a3, OFFSET a3U,  0, 1
        DWORD 3, DIR_DOWN,  OFFSET a3, OFFSET a3D,  0, 1

; ---- N = 8: dir, cell that must hold 4, second cell that must hold 4 ----
n8Cases DWORD DIR_LEFT,   0, 56
        DWORD DIR_RIGHT,  7, 63
        DWORD DIR_UP,     0,  7
        DWORD DIR_DOWN,  56, 63

sPass BYTE "PASS  N=",0
sFail BYTE "FAIL  N=",0
sDir  BYTE "  dir=",0

.code
ClearAll PROC USES eax ecx edi
    cld
    mov edi, OFFSET board
    mov ecx, MAX_CELLS
    xor eax, eax
    rep stosd
    ret
ClearAll ENDP

SumBoard PROC USES ecx esi          ; EAX = sum of the N*N cells
    mov ecx, boardN
    imul ecx, boardN
    xor eax, eax
    xor esi, esi
sumLoop:
    cmp esi, ecx
    jae sumDone
    add eax, board[esi * 4]
    inc esi
    jmp sumLoop
sumDone:
    ret
SumBoard ENDP

; RunMove(rec) -> EAX = 1 pass, 0 fail
RunMove PROC USES ebx ecx esi edi, rec:DWORD
    LOCAL gainGot:DWORD, movedGot:DWORD
    mov ebx, rec
    mov eax, [ebx]
    mov boardN, eax                 ; N of this case
    call ClearAll
    mov ecx, boardN
    imul ecx, boardN
    mov esi, [ebx + 8]              ; input board
    mov edi, OFFSET board
    cld
    rep movsd

    INVOKE MoveBoard, DWORD PTR [ebx + 4]
    mov gainGot, eax
    mov movedGot, edx

    mov ecx, boardN                 ; compare the whole N*N board
    imul ecx, boardN
    mov esi, OFFSET board
    mov edi, [ebx + 12]             ; expected board
    cld
    repe cmpsd
    jne mvFail
    mov eax, gainGot
    cmp eax, [ebx + 16]
    jne mvFail
    mov eax, movedGot
    cmp eax, [ebx + 20]
    jne mvFail
    mov eax, 1
    ret
mvFail:
    xor eax, eax
    ret
RunMove ENDP

main PROC
    ; ---------- Part A: N = 3 and N = 4 ----------
    mov recPtr, OFFSET mvCases
    mov tmp, NUM_MV
mvLoop:
    INVOKE RunMove, recPtr
    mov edx, OFFSET sFail
    test eax, eax
    jz  mvShow
    mov edx, OFFSET sPass
mvShow:
    call WriteString
    mov esi, recPtr
    mov eax, [esi]
    call WriteDec
    mov edx, OFFSET sDir
    call WriteString
    mov eax, [esi + 4]
    call WriteDec
    call Crlf
    add recPtr, MV_REC
    dec tmp
    jnz mvLoop

    ; ---------- Part B: N = 8, one tile in each corner ----------
    mov n8Ptr, OFFSET n8Cases
    mov tmp, 4
n8Loop:
    mov boardN, 8
    call ClearAll
    mov board[0], 2                 ; (row 0, col 0)
    mov board[7 * 4], 2             ; (row 0, col 7)
    mov board[56 * 4], 2            ; (row 7, col 0)
    mov board[63 * 4], 2            ; (row 7, col 7)
    mov esi, n8Ptr
    INVOKE MoveBoard, DWORD PTR [esi]
    mov ebx, eax                    ; gain must be 4 + 4 = 8
    xor ecx, ecx                    ; ECX = pass flag
    cmp ebx, 8
    jne n8Show
    mov eax, [esi + 4]
    cmp board[eax * 4], 4
    jne n8Show
    mov eax, [esi + 8]
    cmp board[eax * 4], 4
    jne n8Show
    call SumBoard                   ; nothing else on the board
    cmp eax, 8
    jne n8Show
    mov ecx, 1
n8Show:
    mov edx, OFFSET sFail
    test ecx, ecx
    jz  n8Print
    mov edx, OFFSET sPass
n8Print:
    call WriteString
    mov eax, 8
    call WriteDec
    mov edx, OFFSET sDir
    call WriteString
    mov esi, n8Ptr
    mov eax, [esi]
    call WriteDec
    call Crlf
    add n8Ptr, 12
    dec tmp
    jnz n8Loop

    call Crlf
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP
END main
