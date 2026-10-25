; ============================================================
; test_spawn.asm - self-checking harness for Module 7
; Use in a SEPARATE test project together with spawn.asm.
; It defines its own boardN / board, so do NOT add it to the
; main game project.  Prints PASS / FAIL for each check.
; ============================================================
INCLUDE Irvine32.inc

InitRandom   PROTO
CountEmpty   PROTO
FindNthEmpty PROTO, n:DWORD
SpawnTile    PROTO

PUBLIC boardN, board

mReport MACRO nameLbl               ; BL = 1 pass / 0 fail
    movzx eax, bl
    mov edx, OFFSET nameLbl
    call Report
ENDM

.data
boardN   DWORD 4
board    DWORD 64 DUP(0)
tmp      DWORD ?
okFlag   DWORD ?
fours    DWORD ?
cellMask DWORD ?

sPass BYTE "PASS  ",0
sFail BYTE "FAIL  ",0
n1  BYTE "CountEmpty on empty 4x4 = 16",0Dh,0Ah,0
n2  BYTE "CountEmpty with 3 tiles = 13",0Dh,0Ah,0
n3  BYTE "FindNthEmpty(0) skips filled cell 0 -> 1",0Dh,0Ah,0
n4  BYTE "FindNthEmpty(3) -> 4",0Dh,0Ah,0
n5  BYTE "Full board: SpawnTile returns 0",0Dh,0Ah,0
n6  BYTE "Full board: nothing changed",0Dh,0Ah,0
n7  BYTE "One empty cell (3x3): SpawnTile returns 1",0Dh,0Ah,0
n8  BYTE "One empty cell: tile is 2 or 4",0Dh,0Ah,0
n9  BYTE "One empty cell: no other cell touched",0Dh,0Ah,0
n10 BYTE "3x3: nine spawns all succeed",0Dh,0Ah,0
n11 BYTE "3x3: tenth spawn fails (board full)",0Dh,0Ah,0
n12 BYTE "1000 spawns: number of 4s within 60..140 (about 10%)",0Dh,0Ah,0
n13 BYTE "400 spawns on empty 4x4 reach all 16 cells",0Dh,0Ah,0
sFoursIs BYTE "      4s seen in 1000 spawns: ",0

.code
; ---- helpers ------------------------------------------------
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

ClearAll PROC USES eax ecx edi      ; zero all 64 cells
    cld
    mov edi, OFFSET board
    mov ecx, 64
    xor eax, eax
    rep stosd
    ret
ClearAll ENDP

FillAll PROC USES eax ecx edi       ; put 2 in all N*N cells
    cld
    mov edi, OFFSET board
    mov ecx, boardN
    imul ecx, boardN
    mov eax, 2
    rep stosd
    ret
FillAll ENDP

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

; ---- tests --------------------------------------------------
main PROC
    call InitRandom

    ; ---- M7-P1: counting and locating ----
    mov boardN, 4
    call ClearAll
    xor ebx, ebx
    call CountEmpty
    cmp eax, 16
    sete bl
    mReport n1

    mov board[0], 2
    mov board[5 * 4], 4
    mov board[9 * 4], 2
    xor ebx, ebx
    call CountEmpty
    cmp eax, 13
    sete bl
    mReport n2

    call ClearAll
    mov board[0], 2                 ; cell 0 filled
    xor ebx, ebx
    INVOKE FindNthEmpty, 0
    cmp eax, 1
    sete bl
    mReport n3
    xor ebx, ebx
    INVOKE FindNthEmpty, 3
    cmp eax, 4
    sete bl
    mReport n4

    ; ---- M7-P2: full board does nothing ----
    call FillAll                    ; 4x4 all 2s, sum = 32
    xor ebx, ebx
    call SpawnTile
    cmp eax, 0
    sete bl
    mReport n5
    xor ebx, ebx
    call SumBoard
    cmp eax, 32
    sete bl
    mReport n6

    ; ---- M7-P2: single empty cell is always chosen ----
    mov boardN, 3
    call ClearAll
    call FillAll                    ; 3x3 all 2s
    mov board[7 * 4], 0             ; only cell 7 empty, sum = 16
    xor ebx, ebx
    call SpawnTile
    cmp eax, 1
    sete bl
    mReport n7

    xor ebx, ebx
    mov eax, board[7 * 4]
    cmp eax, 2
    je  tileOk
    cmp eax, 4
    jne tileDone
tileOk:
    mov bl, 1
tileDone:
    mReport n8

    xor ebx, ebx
    call SumBoard
    mov ecx, board[7 * 4]
    add ecx, 16
    cmp eax, ecx
    sete bl
    mReport n9

    ; ---- fill a 3x3 completely with spawns ----
    call ClearAll
    mov okFlag, 1
    mov tmp, 9
fill9:
    call SpawnTile
    and okFlag, eax
    dec tmp
    jnz fill9
    xor ebx, ebx
    cmp okFlag, 1
    sete bl
    mReport n10
    xor ebx, ebx
    call SpawnTile
    cmp eax, 0
    sete bl
    mReport n11

    ; ---- M7-P3: 90 / 10 distribution ----
    mov boardN, 4
    mov fours, 0
    mov tmp, 1000
dist:
    call ClearAll
    call SpawnTile
    call SumBoard                   ; one tile on board, sum = its value
    cmp eax, 4
    jne not4
    inc fours
not4:
    dec tmp
    jnz dist
    xor ebx, ebx
    mov eax, fours
    cmp eax, 60
    jb  distDone
    cmp eax, 140
    ja  distDone
    mov bl, 1
distDone:
    mReport n12
    mov edx, OFFSET sFoursIs
    call WriteString
    mov eax, fours
    call WriteDec
    call Crlf

    ; ---- M7-P2: every cell can be chosen ----
    mov cellMask, 0
    mov tmp, 400
spread:
    call ClearAll
    call SpawnTile
    xor esi, esi
findTile:                           ; locate the single tile
    cmp board[esi * 4], 0
    jne gotTile
    inc esi
    jmp findTile
gotTile:
    bts cellMask, esi               ; mark cell ESI as seen
    dec tmp
    jnz spread
    xor ebx, ebx
    cmp cellMask, 0FFFFh
    sete bl
    mReport n13

    call Crlf
    call WaitMsg
    INVOKE ExitProcess, 0
main ENDP
END main
