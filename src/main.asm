; ============================================================
; main.asm  -  Entry point and the complete game loop
; 2048 - Slide & Merge Puzzle: configurable N x N (x86 MASM, Irvine32)
; Owner : Aryaan Taimur (25K-2540)
;
; Flow:
;   start  -> InitRandom, LoadBestScore
;   menu   -> New Game / Help / Exit
;   new    -> AskBoardSize, RestartGame (clear, flags, 2 tiles)
;   loop   -> DrawBoard, GetInput
;             arrows/WASD -> ApplyMove, then game-over and win checks
;             U undo, R restart (same N), Q back to menu
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

EXTERN hasWon:DWORD

.code
main PROC
    call InitRandom                 ; seed the generator ONCE
    call LoadBestScore              ; optional best-score file

menuTop:
    call ShowMenu                   ; EAX = MENU_NEW / MENU_HELP / MENU_EXIT
    cmp eax, MENU_NEW
    je  newGame
    cmp eax, MENU_HELP
    je  helpScreen
    call SaveBestScore              ; MENU_EXIT
    INVOKE ExitProcess, 0

helpScreen:
    call ShowHelp
    jmp menuTop

newGame:
    call Clrscr
    call AskBoardSize               ; sets boardN and target
startGame:                          ; also reached by R (same boardN)
    call Clrscr
    call RestartGame                ; clear board, reset flags, 2 tiles

gameLoop:
    call DrawBoard
    call GetInput                   ; blocks until a recognised key
    cmp eax, DIR_DOWN               ; codes 0..3 are the four moves
    ja  notAMove

    INVOKE ApplyMove, eax           ; slide, backup, score, spawn
    test eax, eax
    jz  gameLoop                    ; nothing moved: nothing else to check
    call ClearStatus                ; old message goes away after a real move
    call IsGameOver
    test eax, eax
    jnz gameOver
    cmp hasWon, 0                   ; win message only once per game
    jne gameLoop
    call CheckWin
    test eax, eax
    jz  gameLoop
    mov hasWon, 1
    call ShowWin
    jmp gameLoop

notAMove:
    cmp eax, CMD_QUIT
    je  quitToMenu
    cmp eax, CMD_RESTART
    je  startGame
    call UndoMove                   ; CMD_UNDO
    test eax, eax
    jz  gameLoop                    ; nothing to undo
    call ClearStatus
    jmp gameLoop

gameOver:
    call DrawBoard                  ; show the final board
    call ShowGameOver
overLoop:                           ; only U, R, Q work now
    call GetInput
    cmp eax, CMD_QUIT
    je  quitToMenu
    cmp eax, CMD_RESTART
    je  startGame
    cmp eax, CMD_UNDO
    jne overLoop
    call UndoMove
    test eax, eax
    jz  overLoop
    call ClearStatus
    jmp gameLoop

quitToMenu:
    call SaveBestScore
    jmp menuTop
main ENDP

END main
