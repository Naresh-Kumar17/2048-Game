; ============================================================
; module.inc - PROTOs of every procedure shared between files
; Include AFTER Irvine32.inc and game_macros.inc.
; ============================================================
IFNDEF MODULE_INC_
MODULE_INC_ EQU 1

; ---- Aryaan: ui.asm (M1 menu, M3 renderer, messages), input.asm (M4)
ShowMenu      PROTO                     ; EAX = MENU_NEW / MENU_HELP / MENU_EXIT
ShowHelp      PROTO                     ; shows rules, waits for a key
DrawBoard     PROTO                     ; draws the board and score panel
DrawCell      PROTO, value:DWORD        ; one coloured 6-character cell
ClearStatus   PROTO                     ; blanks the status row
ShowWin       PROTO                     ; win message on the status row
ShowGameOver  PROTO                     ; game-over message with final score
GetInput      PROTO                     ; EAX = DIR_* / CMD_*

; ---- Burhan: logic.asm (M2 board config, M5 SlideLine, M6 MoveBoard)
AskBoardSize  PROTO                     ; EAX = chosen N (3..8)
SetTarget     PROTO                     ; target = 512 for 3x3, else 2048
InitBoard     PROTO                     ; clears N*N cells, score = 0
SlideLine     PROTO, lineStart:DWORD, lineStep:SDWORD, lineLen:DWORD
                                        ; EAX = score gained, EDX = moved flag
GetDirParams  PROTO, dir:DWORD, pStart:PTR DWORD, pStep:PTR SDWORD, pNext:PTR SDWORD
MoveBoard     PROTO, dir:DWORD          ; EAX = total gain, EDX = moved flag

; ---- Naresh: spawn.asm (M7), state.asm (M8, M9)
InitRandom    PROTO                     ; call once at startup
CountEmpty    PROTO                     ; EAX = number of empty cells
FindNthEmpty  PROTO, n:DWORD            ; EAX = cell index, or -1
SpawnTile     PROTO                     ; EAX = 1 placed, 0 board full
UpdateScore   PROTO, gain:DWORD         ; score += gain, updates bestScore
CopyCells     PROTO, src:DWORD, dst:DWORD   ; copies N*N DWORDs (REP MOVSD)
ApplyMove     PROTO, dir:DWORD          ; EAX = 1 board changed, 0 not
CheckWin      PROTO                     ; EAX = 1 if any tile >= target
IsGameOver    PROTO                     ; EAX = 1 if no direction changes the board
UndoMove      PROTO                     ; EAX = 1 undone, 0 nothing to undo
RestartGame   PROTO                     ; same N: clear, reset flags, 2 tiles
LoadBestScore PROTO                     ; reads best2048.dat (optional file)
SaveBestScore PROTO                     ; writes best2048.dat

ENDIF
