; ============================================================
; test_board.asm - harness for Module 2 (M2-P1, M2-P2)
; Use in a SEPARATE test project together with board.asm.
; It defines its own globals, so do NOT add it to the main game.
;
; Part A: automatic PASS / FAIL checks (SetTarget, InitBoard).
; Part B: interactive - type sizes into AskBoardSize.
;         Try: 2  9  0  -4  abc  (just Enter)  then 3, 5, 8.
; ============================================================
INCLUDE Irvine32.inc

MIN_N          EQU 3
MAX_N          EQU 8
MAX_CELLS      EQU MAX_N * MAX_N
TARGET_3X3     EQU 512
TARGET_DEFAULT EQU 2048

AskBoardSize PROTO
SetTarget    PROTO
InitBoard    PROTO

PUBLIC boardN, target, board, score

mReport MACRO nameLbl               ; BL = 1 pass / 0 fail
    movzx eax, bl
    mov edx, OFFSET nameLbl
    call Report
ENDM

.data
boardN    DWORD 4
target    DWORD 0
board     DWORD MAX_CELLS DUP(0)
score     DWORD 0
okFlag    DWORD ?

sPass BYTE "PASS  ",0
sFail BYTE "FAIL  ",0
t1  BYTE "SetTarget: N=3 gives 512",0Dh,0Ah,0
t2  BYTE "SetTarget: N=4..8 give 2048",0Dh,0Ah,0
t3  BYTE "InitBoard N=4: first 16 cells are 0",0Dh,0Ah,0
t4  BYTE "InitBoard N=4: cell 16 and cell 63 untouched",0Dh,0Ah,0
t5  BYTE "InitBoard N=4: score reset to 0",0Dh,0Ah,0
t6  BYTE "InitBoard N=8: all 64 cells are 0",0Dh,0Ah,0
t7  BYTE "InitBoard N=3: first 9 cells 0, cell 9 untouched",0Dh,0Ah,0
sPartB  BYTE 0Dh,0Ah,"Part B: type board sizes (3 tries).",0Dh,0Ah,0
sGot    BYTE "  -> N = ",0
sTgt    BYTE "   target = ",0

.code
Report PROC USES eax edx            ; EAX = 1/0, EDX = name string
    push edx
    test eax, eax
    jz  bad
    mov edx, OFFSET sPass
    jmp show
bad:
    mov edx, OFFSET sFail
show:
    call WriteString
    pop edx
    call WriteString
    ret
Report ENDP

FillAll7 PROC USES eax ecx edi      ; put 7 in all 64 cells
    cld
    mov edi, OFFSET board
    mov ecx, MAX_CELLS
    mov eax, 7
    rep stosd
    ret
FillAll7 ENDP

SumFirstN PROC USES ecx esi         ; EAX = sum of the first N*N cells
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
SumFirstN ENDP

main PROC
    ; ---- M2-P1: target rule ----
    mov boardN, 3
    call SetTarget
    xor ebx, ebx
    cmp target, 512
    sete bl
    mReport t1

    mov okFlag, 1
    mov boardN, 4
nLoop:
    call SetTarget
    xor ebx, ebx
    cmp target, 2048
    sete bl
    and okFlag, ebx
    inc boardN
    cmp boardN, 8
    jbe nLoop
    xor ebx, ebx
    cmp okFlag, 1
    sete bl
    mReport t2

    ; ---- M2-P2: InitBoard N=4 ----
    call FillAll7
    mov boardN, 4
    mov score, 999
    call InitBoard
    xor ebx, ebx
    call SumFirstN
    cmp eax, 0
    sete bl
    mReport t3

    xor ebx, ebx
    cmp board[16 * 4], 7
    jne p4done
    cmp board[63 * 4], 7
    jne p4done
    mov bl, 1
p4done:
    mReport t4

    xor ebx, ebx
    cmp score, 0
    sete bl
    mReport t5

    ; ---- InitBoard N=8 ----
    call FillAll7
    mov boardN, 8
    call InitBoard
    xor ebx, ebx
    call SumFirstN
    cmp eax, 0
    sete bl
    mReport t6

    ; ---- InitBoard N=3 ----
    call FillAll7
    mov boardN, 3
    call InitBoard
    call SumFirstN
    mov ecx, eax                    ; sum of first 9 cells
    xor ebx, ebx
    cmp ecx, 0
    jne p7done
    cmp board[9 * 4], 7
    jne p7done
    mov bl, 1
p7done:
    mReport t7

    ; ---- Part B: interactive validation ----
    mov edx, OFFSET sPartB
    call WriteString
    mov okFlag, 3
askLoop:
    call AskBoardSize
    mov edx, OFFSET sGot
    call WriteString
    mov eax, boardN
    call WriteDec
    mov edx, OFFSET sTgt
    call WriteString
    mov eax, target
    call WriteDec
    call Crlf
    dec okFlag
    jnz askLoop

    call Crlf
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP
END main
