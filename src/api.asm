; ============================================================
; api.asm  -  DLL interface of the assembly game engine
;
; The whole game (slide, merge, score, spawn, undo, win, game over,
; best-score file) stays in logic.asm, spawn.asm and state.asm.
; This file only exposes it to the Python GUI as game2048.dll.
; Every function is stdcall and returns its result in EAX.
; Direction codes: 0 Left, 1 Right, 2 Up, 3 Down.
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC Game_Init, Game_New, Game_Move, Game_Undo, Game_Restart
PUBLIC Game_Cell, Game_Size, Game_Score, Game_Best, Game_Target
PUBLIC Game_CheckWin, Game_IsOver, Game_CanUndo, Game_Save
EXTERN boardN:DWORD, board:DWORD, score:DWORD, bestScore:DWORD, target:DWORD
EXTERN canUndo:DWORD, hasWon:DWORD

.code
; ---- DLL entry point (the linker uses it through "END DllMain") ----
DllMain PROC, hInst:DWORD, reason:DWORD, reserved:DWORD
    mov eax, 1                      ; TRUE: load succeeded
    ret
DllMain ENDP

; ---- startup / game control ----------------------------------
Game_Init PROC                      ; seed the generator, load best score
    call InitRandom
    call LoadBestScore
    mov eax, 1
    ret
Game_Init ENDP

Game_New PROC, n:DWORD              ; new game of size n (3..8); EAX = 1 ok
    mov eax, n
    cmp eax, MIN_N
    jl  badSize
    cmp eax, MAX_N
    jg  badSize
    mov boardN, eax
    call SetTarget
    call RestartGame
    mov eax, 1
    ret
badSize:
    xor eax, eax
    ret
Game_New ENDP

Game_Restart PROC                   ; same size, fresh board
    call RestartGame
    mov eax, 1
    ret
Game_Restart ENDP

Game_Move PROC, dir:DWORD           ; EAX = 1 if the board changed
    cmp dir, DIR_DOWN
    ja  badDir
    INVOKE ApplyMove, dir
    ret
badDir:
    xor eax, eax
    ret
Game_Move ENDP

Game_Undo PROC                      ; EAX = 1 if a move was undone
    call UndoMove
    ret
Game_Undo ENDP

Game_Save PROC                      ; write best2048.dat
    call SaveBestScore
    mov eax, 1
    ret
Game_Save ENDP

; ---- state queries -------------------------------------------
Game_Cell PROC USES ecx, idx:DWORD  ; tile value at cell idx = row*N + col
    mov ecx, boardN
    imul ecx, boardN
    mov eax, idx
    cmp eax, ecx
    jae outOfRange
    mov eax, board[eax * 4]
    ret
outOfRange:
    xor eax, eax
    ret
Game_Cell ENDP

Game_Size PROC
    mov eax, boardN
    ret
Game_Size ENDP

Game_Score PROC
    mov eax, score
    ret
Game_Score ENDP

Game_Best PROC
    mov eax, bestScore
    ret
Game_Best ENDP

Game_Target PROC
    mov eax, target
    ret
Game_Target ENDP

Game_CanUndo PROC
    mov eax, canUndo
    ret
Game_CanUndo ENDP

Game_IsOver PROC                    ; EAX = 1 if no move is possible
    call IsGameOver
    ret
Game_IsOver ENDP

Game_CheckWin PROC                  ; EAX = 1 ONCE per game, when target is reached
    cmp hasWon, 0
    jne noWin
    call CheckWin
    test eax, eax
    jz  noWin
    mov hasWon, 1
    mov eax, 1
    ret
noWin:
    xor eax, eax
    ret
Game_CheckWin ENDP

END DllMain
