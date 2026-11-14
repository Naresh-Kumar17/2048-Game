; ============================================================
; game_macros.inc - constants and macros shared by every module
; 2048 - Slide & Merge (x86 MASM, Irvine32)
; ============================================================
IFNDEF MACROS_INC_
MACROS_INC_ EQU 1

; ---- Board (M2) ------------------------------------------------
MIN_N           EQU 3
MAX_N           EQU 8
MAX_CELLS       EQU MAX_N * MAX_N       ; 64 DWORDs
TARGET_3X3      EQU 512
TARGET_DEFAULT  EQU 2048

; ---- GetInput return codes (M4) --------------------------------
; 0-3 follow the direction table of Section 10: Left, Right, Up, Down
DIR_LEFT        EQU 0
DIR_RIGHT       EQU 1
DIR_UP          EQU 2
DIR_DOWN        EQU 3
CMD_UNDO        EQU 4
CMD_RESTART     EQU 5
CMD_QUIT        EQU 6

; ---- ShowMenu return codes (M1) --------------------------------
MENU_NEW        EQU 1
MENU_HELP       EQU 2
MENU_EXIT       EQU 3

; ---- Screen row reserved for messages (win / game over / errors)
STATUS_ROW      EQU 22

; ---- Move the cursor: x = column, y = row ----------------------
mGoto MACRO xx, yy
    mov dl, xx
    mov dh, yy
    call Gotoxy
ENDM

ENDIF
