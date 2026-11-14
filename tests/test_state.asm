; ============================================================
; test_state.asm - tests for Modules 8 and 9
;   M8-P1 UpdateScore   M8-P2 ApplyMove   M8-P3 CheckWin
;   M8-P4 IsGameOver    M9-P1 UndoMove    M9-P2 RestartGame
; TEST PROJECT = this file + logic.asm + spawn.asm + state.asm
;                (+ game_macros.inc, module.inc).
; Do NOT add data.asm, ui.asm, input.asm or main.asm: this file
; defines its own globals and its own main.
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC boardN, target, board, score, bestScore
PUBLIC backupBoard, backupScore, scratchBoard, canUndo, hasWon

mReport MACRO nameLbl               ; BL = 1 pass / 0 fail
    movzx eax, bl
    mov edx, OFFSET nameLbl
    call Report
ENDM

.data
boardN       DWORD 4
target       DWORD 2048
board        DWORD MAX_CELLS DUP(0)
score        DWORD 0
bestScore    DWORD 0
backupBoard  DWORD MAX_CELLS DUP(0)
backupScore  DWORD 0
scratchBoard DWORD MAX_CELLS DUP(0)
canUndo      DWORD 0
hasWon       DWORD 0

a4     DWORD 2,2,0,0,  0,2,0,2,  4,0,4,0,  2,4,8,16    ; sum 46, 10 tiles
b4     DWORD 2,4,8,0,  0,0,0,0,  0,0,0,0,  0,0,0,0     ; Left changes nothing
win4   DWORD 0,0,0,0,  0,2048,0,0,  0,0,0,0,  0,0,0,0
win3   DWORD 0,0,0,  0,512,0,  0,0,0
full3a DWORD 2,4,2,  4,2,4,  2,4,2                      ; full, no move possible
full3b DWORD 2,2,4,  4,8,16,  8,16,32                   ; full, one equal pair

sPass BYTE "PASS  ",0
sFail BYTE "FAIL  ",0
t1  BYTE "UpdateScore(4): score 4, best stays 10",0Dh,0Ah,0
t2  BYTE "UpdateScore(8): score 12, best becomes 12",0Dh,0Ah,0
t3  BYTE "UpdateScore(0): nothing changes",0Dh,0Ah,0
t4  BYTE "No-op move: ApplyMove returns 0",0Dh,0Ah,0
t5  BYTE "No-op move: score unchanged",0Dh,0Ah,0
t6  BYTE "No-op move: no tile spawned (still 3 tiles)",0Dh,0Ah,0
t7  BYTE "Valid move: ApplyMove returns 1",0Dh,0Ah,0
t8  BYTE "Valid move: score = 16 and best = 16",0Dh,0Ah,0
t9  BYTE "Valid move: exactly one tile spawned (8 tiles)",0Dh,0Ah,0
t10 BYTE "Valid move: spawned tile is 2 or 4 (sum 48 or 50)",0Dh,0Ah,0
t11 BYTE "Best score survives InitBoard (score reset, best kept)",0Dh,0Ah,0
t12 BYTE "CheckWin: 2048 on a 4x4 board",0Dh,0Ah,0
t13 BYTE "CheckWin: no target tile -> 0",0Dh,0Ah,0
t14 BYTE "CheckWin: 512 wins on a 3x3 board",0Dh,0Ah,0
t15 BYTE "IsGameOver: full 3x3, no moves -> 1",0Dh,0Ah,0
t16 BYTE "IsGameOver: board left unchanged",0Dh,0Ah,0
t17 BYTE "IsGameOver: full 3x3 with one equal pair -> 0",0Dh,0Ah,0
t18 BYTE "IsGameOver: board with empty cells -> 0",0Dh,0Ah,0
t19 BYTE "UndoMove with nothing saved -> 0",0Dh,0Ah,0
t20 BYTE "UndoMove after a move restores board and score",0Dh,0Ah,0
t21 BYTE "UndoMove is one level only (second call -> 0)",0Dh,0Ah,0
t22 BYTE "No-op move does not create an undo backup",0Dh,0Ah,0
t23 BYTE "RestartGame: exactly 2 tiles on the board",0Dh,0Ah,0
t24 BYTE "RestartGame: score 0, flags cleared, same N",0Dh,0Ah,0

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

LoadBoard PROC USES eax ecx esi edi, src:DWORD   ; copy N*N cells into board
    cld
    mov esi, src
    mov edi, OFFSET board
    mov ecx, boardN
    imul ecx, boardN
    rep movsd
    ret
LoadBoard ENDP

BoardEquals PROC USES ecx esi edi, src:DWORD     ; EAX = 1 if board == src
    cld
    mov esi, OFFSET board
    mov edi, src
    mov ecx, boardN
    imul ecx, boardN
    repe cmpsd
    sete al
    movzx eax, al
    ret
BoardEquals ENDP

CountTiles PROC USES ecx esi        ; EAX = number of non-zero cells
    mov ecx, boardN
    imul ecx, boardN
    xor eax, eax
    xor esi, esi
cntLoop:
    cmp esi, ecx
    jae cntDone
    cmp board[esi * 4], 0
    je  cntNext
    inc eax
cntNext:
    inc esi
    jmp cntLoop
cntDone:
    ret
CountTiles ENDP

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

main PROC
    call InitRandom

    ; ---------- M8-P1: UpdateScore ----------
    mov score, 0
    mov bestScore, 10
    INVOKE UpdateScore, 4
    xor ebx, ebx
    cmp score, 4
    jne p1done
    cmp bestScore, 10
    jne p1done
    mov bl, 1
p1done:
    mReport t1

    INVOKE UpdateScore, 8
    xor ebx, ebx
    cmp score, 12
    jne p2done
    cmp bestScore, 12
    jne p2done
    mov bl, 1
p2done:
    mReport t2

    INVOKE UpdateScore, 0
    xor ebx, ebx
    cmp score, 12
    jne p3done
    cmp bestScore, 12
    jne p3done
    mov bl, 1
p3done:
    mReport t3

    ; ---------- M8-P2: move that changes nothing ----------
    mov boardN, 4
    mov score, 0
    mov bestScore, 0
    mov canUndo, 0
    INVOKE LoadBoard, OFFSET b4
    INVOKE ApplyMove, DIR_LEFT
    xor ebx, ebx
    cmp eax, 0
    sete bl
    mReport t4
    xor ebx, ebx
    cmp score, 0
    sete bl
    mReport t5
    xor ebx, ebx
    call CountTiles
    cmp eax, 3
    sete bl
    mReport t6

    ; ---------- M9-P1: a no-op move leaves no backup ----------
    xor ebx, ebx
    cmp canUndo, 0
    sete bl
    mReport t22

    ; ---------- M8-P2: move that changes the board ----------
    mov score, 0
    mov bestScore, 0
    INVOKE LoadBoard, OFFSET a4
    INVOKE ApplyMove, DIR_LEFT      ; merges give 4+4+8 = 16
    xor ebx, ebx
    cmp eax, 1
    sete bl
    mReport t7
    xor ebx, ebx
    cmp score, 16
    jne p8done
    cmp bestScore, 16
    jne p8done
    mov bl, 1
p8done:
    mReport t8
    xor ebx, ebx
    call CountTiles                 ; 7 tiles after the move + 1 spawned
    cmp eax, 8
    sete bl
    mReport t9
    xor ebx, ebx
    call SumBoard                   ; 46 + (2 or 4)
    cmp eax, 48
    je  p10ok
    cmp eax, 50
    jne p10done
p10ok:
    mov bl, 1
p10done:
    mReport t10

    ; ---------- M9-P1: undo after that valid move ----------
    call UndoMove
    xor ebx, ebx
    cmp eax, 1
    jne u20done
    INVOKE BoardEquals, OFFSET a4
    cmp eax, 1
    jne u20done
    cmp score, 0
    jne u20done
    mov bl, 1
u20done:
    mReport t20

    xor ebx, ebx
    call UndoMove                   ; second undo: nothing left
    cmp eax, 0
    sete bl
    mReport t21

    ; ---------- best score is session-long ----------
    call InitBoard                  ; M2: clears board, score = 0
    xor ebx, ebx
    cmp score, 0
    jne p11done
    cmp bestScore, 16
    jne p11done
    mov bl, 1
p11done:
    mReport t11

    ; ---------- M9-P1: nothing saved at all ----------
    mov canUndo, 0
    xor ebx, ebx
    call UndoMove
    cmp eax, 0
    sete bl
    mReport t19

    ; ---------- M8-P3: CheckWin ----------
    mov boardN, 4
    mov target, 2048
    INVOKE LoadBoard, OFFSET win4
    xor ebx, ebx
    call CheckWin
    cmp eax, 1
    sete bl
    mReport t12

    INVOKE LoadBoard, OFFSET a4
    xor ebx, ebx
    call CheckWin
    cmp eax, 0
    sete bl
    mReport t13

    mov boardN, 3
    mov target, 512
    INVOKE LoadBoard, OFFSET win3
    xor ebx, ebx
    call CheckWin
    cmp eax, 1
    sete bl
    mReport t14

    ; ---------- M8-P4: IsGameOver ----------
    mov boardN, 3
    INVOKE LoadBoard, OFFSET full3a
    xor ebx, ebx
    call IsGameOver
    cmp eax, 1
    sete bl
    mReport t15
    INVOKE BoardEquals, OFFSET full3a
    mov bl, al
    mReport t16

    INVOKE LoadBoard, OFFSET full3b
    xor ebx, ebx
    call IsGameOver
    cmp eax, 0
    sete bl
    mReport t17

    mov boardN, 4
    INVOKE LoadBoard, OFFSET a4
    xor ebx, ebx
    call IsGameOver
    cmp eax, 0
    sete bl
    mReport t18

    ; ---------- M9-P2: RestartGame ----------
    mov boardN, 4
    INVOKE LoadBoard, OFFSET a4     ; junk on the board
    mov score, 77
    mov canUndo, 1
    mov hasWon, 1
    call RestartGame
    xor ebx, ebx
    call CountTiles
    cmp eax, 2
    sete bl
    mReport t23
    xor ebx, ebx
    cmp score, 0
    jne r24done
    cmp canUndo, 0
    jne r24done
    cmp hasWon, 0
    jne r24done
    cmp boardN, 4
    jne r24done
    mov bl, 1
r24done:
    mReport t24

    call Crlf
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP
END main
