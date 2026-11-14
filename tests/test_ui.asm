; ============================================================
; test_ui.asm  -  Standalone harness for Modules 1, 3, 4
; Use in a SEPARATE test project with m1_menu.asm, m3_render.asm
; and m4_input.asm.  It defines its own copies of the shared
; globals, so do NOT add it to the main game project.
;
; What it checks:
;   - menu validation (press 4, x, Enter -> error, then 1/2/3 works)
;   - help screen and return to menu
;   - board drawn from a hand-filled array (all colours visible)
;   - every key code shown on the status row; Q returns to menu
;   - score panel (each key press adds 10 to the score)
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC boardN, board, score, bestScore, target

.data
boardN      DWORD 4
board       DWORD 64 DUP(0)
score       DWORD 0
bestScore   DWORD 5678
target      DWORD 2048
keyCode        DWORD ?
sKey        BYTE "Last input code: ",0
sSpaces     BYTE "   ",0

.code
main PROC
menuTop:
    call ShowMenu
    cmp eax, MENU_NEW
    je  newGame
    cmp eax, MENU_HELP
    je  showHelpScr
    INVOKE ExitProcess, 0

showHelpScr:
    call ShowHelp
    jmp menuTop

newGame:
    ; hand-fill 4x4 with 0,2,4,8 ... 8192 so every colour appears
    mov boardN, 4
    mov eax, 1
    mov ecx, 14
    xor esi, esi
fill:
    mov board[esi * 4], eax
    shl eax, 1
    inc esi
    loop fill
    mov board[0], 0                 ; first cell stays empty
    mov score, 0

    call Clrscr
gameLoop:
    call DrawBoard
    call GetInput
    mov keyCode, eax
    cmp eax, CMD_QUIT
    je  menuTop

    mGoto 0, STATUS_ROW
    mov edx, OFFSET sKey
    call WriteString
    mov eax, keyCode
    call WriteDec
    mov edx, OFFSET sSpaces
    call WriteString
    add score, 10
    jmp gameLoop
main ENDP
END main
