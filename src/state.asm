; ============================================================
; state.asm  -  Modules 8 and 9: score, win, game over, undo, restart
; Owner : Naresh Kumar (25K-2501)
;
; Week 2: M8-P1 UpdateScore        M8-P2 ApplyMove
; Week 3: M8-P3 CheckWin           M8-P4 IsGameOver (+ CopyCells)
;         M9-P1 undo backup in ApplyMove, UndoMove
;         M9-P2 RestartGame
;         optional: LoadBestScore / SaveBestScore (best2048.dat)
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC UpdateScore, CopyCells, ApplyMove, CheckWin, IsGameOver
PUBLIC UndoMove, RestartGame, LoadBestScore, SaveBestScore
EXTERN boardN:DWORD, target:DWORD, board:DWORD, score:DWORD, bestScore:DWORD
EXTERN backupBoard:DWORD, backupScore:DWORD, scratchBoard:DWORD
EXTERN canUndo:DWORD, hasWon:DWORD

.data
bestFileName BYTE "best2048.dat",0

.code
; ============================================================
; M8-P1  UpdateScore(gain)
; score += gain.  If score beats bestScore, bestScore = score.
; ============================================================
UpdateScore PROC USES eax, gain:DWORD
    mov eax, gain
    add score, eax
    mov eax, score
    cmp eax, bestScore
    jbe noNewBest
    mov bestScore, eax
noNewBest:
    ret
UpdateScore ENDP

; ============================================================
; M8-P4 / M9  CopyCells(src, dst)
; Copies the N*N cells of one board array to another (REP MOVSD).
; ============================================================
CopyCells PROC USES ecx esi edi, src:DWORD, dst:DWORD
    cld
    mov esi, src
    mov edi, dst
    mov ecx, boardN
    imul ecx, boardN
    rep movsd
    ret
CopyCells ENDP

; ============================================================
; M8-P2 + M9-P1  ApplyMove(dir)
; One full player turn for a direction key (dir = 0..3):
;   1. snapshot the board into scratchBoard (cheap, REP MOVSD)
;   2. MoveBoard slides and merges
;   3. nothing changed -> return 0: no score, no spawn, and the
;      previous undo backup is left untouched
;   4. changed -> commit the snapshot as the undo backup, add the
;      gain to the score, spawn one tile, return 1
; ============================================================
ApplyMove PROC USES ebx, dir:DWORD
    LOCAL oldScore:DWORD

    mov eax, score
    mov oldScore, eax
    INVOKE CopyCells, OFFSET board, OFFSET scratchBoard   ; M9-P1 snapshot

    INVOKE MoveBoard, dir           ; EAX = gain, EDX = moved flag
    test edx, edx
    jz  nothingMoved

    mov ebx, eax                    ; keep the gain
    INVOKE CopyCells, OFFSET scratchBoard, OFFSET backupBoard
    mov eax, oldScore
    mov backupScore, eax
    mov canUndo, 1                  ; one-level undo is now available

    INVOKE UpdateScore, ebx         ; M8-P1
    call SpawnTile                  ; M7
    mov eax, 1
    ret

nothingMoved:
    xor eax, eax
    ret
ApplyMove ENDP

; ============================================================
; M8-P3  CheckWin
; Returns EAX = 1 if any cell holds a tile >= target, else 0.
; ============================================================
CheckWin PROC USES ecx esi
    mov ecx, boardN
    imul ecx, boardN
    xor esi, esi
winScan:
    cmp esi, ecx
    jae noWin
    mov eax, board[esi * 4]
    cmp eax, target
    jae isWin
    inc esi
    jmp winScan
isWin:
    mov eax, 1
    ret
noWin:
    xor eax, eax
    ret
CheckWin ENDP

; ============================================================
; M8-P4  IsGameOver
; The game is over when NO direction changes the board.
; The real board is saved in scratchBoard, each direction is tried
; with MoveBoard (the same SlideLine code), and the board is
; restored from scratchBoard after every try.
; Returns EAX = 1 game over, 0 a move is still possible.
; The board and the score are left exactly as they were.
; ============================================================
IsGameOver PROC USES ebx
    INVOKE CopyCells, OFFSET board, OFFSET scratchBoard
    mov ebx, DIR_LEFT
tryDir:
    INVOKE MoveBoard, ebx           ; EDX = moved flag
    push edx
    INVOKE CopyCells, OFFSET scratchBoard, OFFSET board   ; restore
    pop edx
    test edx, edx
    jnz stillPlayable
    inc ebx
    cmp ebx, DIR_DOWN
    jbe tryDir
    mov eax, 1                      ; none of the four moved anything
    ret
stillPlayable:
    xor eax, eax
    ret
IsGameOver ENDP

; ============================================================
; M9-P1  UndoMove
; Restores board and score from before the last real move.
; One level only: a second call does nothing.
; Returns EAX = 1 if undone, 0 if there was nothing to undo.
; ============================================================
UndoMove PROC
    cmp canUndo, 0
    je  nothingToUndo
    INVOKE CopyCells, OFFSET backupBoard, OFFSET board
    mov eax, backupScore
    mov score, eax
    mov canUndo, 0
    mov eax, 1
    ret
nothingToUndo:
    xor eax, eax
    ret
UndoMove ENDP

; ============================================================
; M9-P2  RestartGame
; Fresh game with the SAME board size: clears the board, score = 0,
; clears the undo and win flags, places two starting tiles.
; bestScore is kept.  Also used by New Game after AskBoardSize.
; ============================================================
RestartGame PROC
    call InitBoard                  ; M2: N*N cells = 0, score = 0
    mov canUndo, 0
    mov hasWon, 0
    call SpawnTile
    call SpawnTile
    ret
RestartGame ENDP

; ============================================================
; Optional: best score file (4 bytes, best2048.dat)
; Both procedures silently do nothing if the file cannot be
; opened or created, so the game never fails because of the file.
; ============================================================
LoadBestScore PROC USES eax ebx ecx edx
    mov edx, OFFSET bestFileName
    call OpenInputFile              ; EAX = handle or INVALID_HANDLE_VALUE
    cmp eax, INVALID_HANDLE_VALUE
    je  noFile
    mov ebx, eax                    ; keep the handle
    mov edx, OFFSET bestScore
    mov ecx, 4
    call ReadFromFile               ; EAX = bytes read; CF = 1 on error
    jc  badRead
    cmp eax, 4
    jne badRead
    jmp closeLoad
badRead:
    mov bestScore, 0
closeLoad:
    mov eax, ebx
    call CloseFile
noFile:
    ret
LoadBestScore ENDP

SaveBestScore PROC USES eax ebx ecx edx
    mov edx, OFFSET bestFileName
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je  noSave
    mov ebx, eax
    mov edx, OFFSET bestScore
    mov ecx, 4
    call WriteToFile                ; EAX = handle
    mov eax, ebx
    call CloseFile
noSave:
    ret
SaveBestScore ENDP

END
