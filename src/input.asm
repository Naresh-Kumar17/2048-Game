; ============================================================
; input.asm - Input handler (M4)   Owner: Aryaan Taimur
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC GetInput

; Windows virtual-key codes for the arrow keys
KEY_LEFT    EQU 25h
KEY_UP      EQU 26h
KEY_RIGHT   EQU 27h
KEY_DOWN    EQU 28h

.code
; ============================================================
; GetInput
; Blocks until a recognised key is pressed.
; Returns EAX =
;   DIR_LEFT 0 / DIR_RIGHT 1 / DIR_UP 2 / DIR_DOWN 3   (arrows, WASD)
;   CMD_UNDO 4 (U) / CMD_RESTART 5 (R) / CMD_QUIT 6 (Q)
; All other keys are ignored.
; ============================================================
GetInput PROC USES ebx edx
waitKey:
    mov eax, 10                     ; short sleep so we don't spin the CPU
    call Delay
    call ReadKey                    ; ZF=1 -> no key; DX = virtual key, AL = ASCII
    jz  waitKey

    ; ---- M4-P1: arrow keys (virtual-key code in DX) ----
    cmp dx, KEY_LEFT
    je  isLeft
    cmp dx, KEY_RIGHT
    je  isRight
    cmp dx, KEY_UP
    je  isUp
    cmp dx, KEY_DOWN
    je  isDown

    ; ---- M4-P1 / M4-P2: letters, case-insensitive ----
    and al, 0DFh                    ; 'a'..'z' -> 'A'..'Z'
    cmp al, 'A'
    je  isLeft
    cmp al, 'D'
    je  isRight
    cmp al, 'W'
    je  isUp
    cmp al, 'S'
    je  isDown
    cmp al, 'U'
    je  isUndo
    cmp al, 'R'
    je  isRestart
    cmp al, 'Q'
    je  isQuit
    jmp waitKey                     ; unknown key: ignore it

isLeft:
    mov eax, DIR_LEFT
    ret
isRight:
    mov eax, DIR_RIGHT
    ret
isUp:
    mov eax, DIR_UP
    ret
isDown:
    mov eax, DIR_DOWN
    ret
isUndo:
    mov eax, CMD_UNDO
    ret
isRestart:
    mov eax, CMD_RESTART
    ret
isQuit:
    mov eax, CMD_QUIT
    ret
GetInput ENDP

END
