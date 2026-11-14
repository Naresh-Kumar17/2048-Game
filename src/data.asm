; ============================================================
; data.asm - all shared variables
; Every other file reaches these through EXTERN, so the names
; must stay exactly as written here.
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc

PUBLIC boardN, target, board, score, bestScore
PUBLIC backupBoard, backupScore, scratchBoard
PUBLIC canUndo, hasWon

.data
boardN       DWORD 4                    ; side length 3..8 (AskBoardSize)
target       DWORD 2048                 ; target tile (SetTarget)
board        DWORD MAX_CELLS DUP(0)     ; flat row-major board: row*N + col
score        DWORD 0
bestScore    DWORD 0                    ; whole session, saved to best2048.dat
backupBoard  DWORD MAX_CELLS DUP(0)     ; one-level undo copy (M9)
backupScore  DWORD 0                    ; score before the last move (M9)
scratchBoard DWORD MAX_CELLS DUP(0)     ; temp copy: undo snapshot, game-over test
canUndo      DWORD 0                    ; 1 when backupBoard holds a valid move
hasWon       DWORD 0                    ; 1 once the win message was shown

END
