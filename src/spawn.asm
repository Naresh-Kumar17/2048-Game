; ============================================================
; spawn.asm  -  Module 7: Tile spawner
; Owner : Naresh Kumar (25K-2501)
; Branch: feature/m7-spawner
; Phases: M7-P1 CountEmpty + FindNthEmpty   (count / locate empties)
;         M7-P2 random choice of an empty cell (RandomRange)
;         M7-P3 place 2 (90%) or 4 (10%); Randomize once at startup
;
; Uses shared globals from data.asm: boardN, board.
; Board is a flat row-major DWORD array: cell = row*N + col.
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC InitRandom, CountEmpty, FindNthEmpty, SpawnTile
EXTERN boardN:DWORD, board:DWORD

.code
; ============================================================
; M7-P3  InitRandom
; Seeds the generator.  Call ONCE at program start (before the
; menu), never per game or per spawn, or tiles repeat in a burst.
; ============================================================
InitRandom PROC
    call Randomize
    ret
InitRandom ENDP

; ============================================================
; M7-P1  CountEmpty
; Returns: EAX = number of cells in the N x N board that hold 0
; ============================================================
CountEmpty PROC USES ecx esi
    mov ecx, boardN                 ; ECX = total cells = N * N
    imul ecx, boardN
    xor eax, eax                    ; EAX = empty counter
    xor esi, esi                    ; ESI = cell index
scan:
    cmp esi, ecx
    jae done
    cmp board[esi * 4], 0
    jne occupied
    inc eax
occupied:
    inc esi
    jmp scan
done:
    ret
CountEmpty ENDP

; ============================================================
; M7-P1  FindNthEmpty(n)
; Returns the cell index (0..N*N-1) of the n-th empty cell,
; counting from 0 in row-major order.
; Returns: EAX = index, or -1 if there is no such empty cell
; ============================================================
FindNthEmpty PROC USES ebx ecx esi, n:DWORD
    mov ecx, boardN
    imul ecx, boardN                ; ECX = total cells
    mov ebx, n                      ; EBX = empties still to skip
    xor esi, esi
scan:
    cmp esi, ecx
    jae notFound
    cmp board[esi * 4], 0
    jne next
    cmp ebx, 0                      ; empty cell: is it the one we want?
    je  found
    dec ebx                         ; no, skip it
next:
    inc esi
    jmp scan
found:
    mov eax, esi
    ret
notFound:
    mov eax, -1
    ret
FindNthEmpty ENDP

; ============================================================
; M7-P2 + M7-P3  SpawnTile
; Picks a random empty cell and puts a 2 (90%) or a 4 (10%) in it.
; Returns: EAX = 1 if a tile was placed, 0 if the board is full
; ============================================================
SpawnTile PROC USES ebx ecx edx
    call CountEmpty                 ; EAX = number of empty cells
    test eax, eax
    jz  boardFull

    call RandomRange                ; EAX = random 0 .. count-1   (M7-P2)
    INVOKE FindNthEmpty, eax        ; EAX = cell index of that empty
    mov ebx, eax                    ; keep the index in EBX

    mov eax, 10                     ; M7-P3: roll 0..9
    call RandomRange
    mov ecx, 2                      ; 0..8  (90%) -> tile 2
    cmp eax, 9
    jb  place
    mov ecx, 4                      ; 9     (10%) -> tile 4
place:
    mov board[ebx * 4], ecx
    mov eax, 1
    ret

boardFull:
    xor eax, eax
    ret
SpawnTile ENDP

END
