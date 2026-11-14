; ============================================================
; ui.asm - Menu (M1) + Renderer (M3)   Owner: Aryaan Taimur
; Keep your existing top lines (INCLUDE Irvine32.inc / module.inc /
; game_macros.inc) exactly as in your other files.
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC ShowMenu, ShowHelp, DrawBoard, DrawCell
PUBLIC ClearStatus, ShowWin, ShowGameOver
EXTERN boardN:DWORD, board:DWORD, score:DWORD, bestScore:DWORD, target:DWORD

; ---- Layout ------------------------------------------------------
BOARD_X     EQU 2                   ; left edge of the grid (column)
BOARD_Y     EQU 3                   ; top edge of the grid (row)
CELL_W      EQU 6                   ; characters inside one cell
MAX_COLOR_IDX EQU 12                ; highest log2 with its own colour

DEFAULT_ATTR EQU lightGray + (black * 16)
EMPTY_ATTR   EQU gray + (black * 16)


; ---------------- Module 1: menu & help ----------------
.data
; ---- M1-P1 strings ---------------------------------------------
sTitle      BYTE "==============================",0Dh,0Ah
            BYTE "   2048 - SLIDE & MERGE PUZZLE",0Dh,0Ah
            BYTE "   x86 Assembly (MASM, Irvine32)",0Dh,0Ah
            BYTE "==============================",0Dh,0Ah,0Dh,0Ah,0
sOptions    BYTE "   1.  New Game",0Dh,0Ah
            BYTE "   2.  Help",0Dh,0Ah
            BYTE "   3.  Exit",0Dh,0Ah,0Dh,0Ah,0
sPrompt     BYTE "   Choose an option (1-3): ",0
sBad        BYTE 0Dh,0Ah,"   Invalid choice. Enter 1, 2 or 3: ",0

; ---- M1-P2 strings ---------------------------------------------
sHelp       BYTE "HOW TO PLAY",0Dh,0Ah
            BYTE "-----------",0Dh,0Ah,0Dh,0Ah
            BYTE "GOAL",0Dh,0Ah
            BYTE "  Build the target tile: 2048 on boards 4x4 to 8x8,",0Dh,0Ah
            BYTE "  or 512 on the 3x3 board.",0Dh,0Ah,0Dh,0Ah
            BYTE "RULES",0Dh,0Ah
            BYTE "  - Every move slides ALL tiles as far as they can go.",0Dh,0Ah
            BYTE "  - Two equal tiles that collide merge into one tile of",0Dh,0Ah
            BYTE "    double value, and the score grows by that value.",0Dh,0Ah
            BYTE "  - A tile merges at most once per move.",0Dh,0Ah
            BYTE "  - After a move that changed the board, a new tile",0Dh,0Ah
            BYTE "    appears: 2 (90%) or 4 (10%).",0Dh,0Ah
            BYTE "  - Game over when the board is full and no move works.",0Dh,0Ah,0Dh,0Ah
            BYTE "CONTROLS",0Dh,0Ah
            BYTE "  Arrow keys / W A S D   slide tiles",0Dh,0Ah
            BYTE "  U                      undo last move",0Dh,0Ah
            BYTE "  R                      restart (same board size)",0Dh,0Ah
            BYTE "  Q                      back to main menu",0Dh,0Ah,0Dh,0Ah,0

.code
; ============================================================
; M1-P1  ShowMenu
; Draws the menu and loops until the player presses 1, 2 or 3.
; Any other key prints an error and asks again.
; Returns: EAX = MENU_NEW / MENU_HELP / MENU_EXIT
; ============================================================
ShowMenu PROC USES edx
    call Clrscr

    mov eax, yellow + (black * 16)
    call SetTextColor
    mov edx, OFFSET sTitle
    call WriteString

    mov eax, lightGray + (black * 16)
    call SetTextColor
    mov edx, OFFSET sOptions
    call WriteString
    mov edx, OFFSET sPrompt
    call WriteString

readChoice:
    call ReadChar                   ; AL = key pressed (no echo)
    cmp al, '1'
    jb  badKey
    cmp al, '3'
    ja  badKey
    movzx eax, al
    sub eax, '0'                    ; '1'..'3' -> 1..3
    ret

badKey:
    mov edx, OFFSET sBad
    call WriteString
    jmp readChoice
ShowMenu ENDP

; ============================================================
; M1-P2  ShowHelp
; Prints rules and controls, then waits for any key.
; ============================================================
ShowHelp PROC USES eax edx
    call Clrscr
    mov eax, lightCyan + (black * 16)
    call SetTextColor
    mov edx, OFFSET sHelp
    call WriteString
    mov eax, lightGray + (black * 16)
    call SetTextColor
    call WaitMsg                    ; "Press any key to continue..."
    ret
ShowHelp ENDP

; ---------------- Module 3: renderer ----------------
.data
; ---- M3-P3: colour per tile, indexed by log2(value) -----------------
; idx: 1=2, 2=4, 3=8, 4=16 ... 11=2048, 12+=4096 and above
tileColors  DWORD gray + (black * 16)               ; 0  (unused, 1 is no tile)
            DWORD black + (lightGray * 16)          ; 1  = 2
            DWORD black + (cyan * 16)               ; 2  = 4
            DWORD white + (blue * 16)               ; 3  = 8
            DWORD black + (lightCyan * 16)          ; 4  = 16
            DWORD black + (green * 16)              ; 5  = 32
            DWORD black + (lightGreen * 16)         ; 6  = 64
            DWORD black + (yellow * 16)             ; 7  = 128
            DWORD white + (brown * 16)              ; 8  = 256
            DWORD white + (red * 16)                ; 9  = 512
            DWORD white + (magenta * 16)            ; 10 = 1024
            DWORD white + (lightMagenta * 16)       ; 11 = 2048
            DWORD black + (white * 16)              ; 12 = 4096+

sBoardTitle BYTE "2048  -  ",0
sScoreLbl   BYTE "SCORE : ",0
sBestLbl    BYTE "BEST  : ",0
sTargetLbl  BYTE "TARGET: ",0
sCtrlHdr    BYTE "CONTROLS",0
sCtrl1      BYTE "Arrows/WASD: move",0
sCtrl2      BYTE "U : undo",0
sCtrl3      BYTE "R : restart",0
sCtrl4      BYTE "Q : menu",0
sPad        BYTE "      ",0         ; wipes leftover digits after undo

.code
; ============================================================
; M3-P1  DrawBorder
; Draws one "+------+------+...+" line of the grid at row yPos.
; ============================================================
DrawBorder PROC USES eax ecx edx, yPos:DWORD
    mGoto BOARD_X, <BYTE PTR yPos>

    mov ecx, boardN                 ; one segment per column
colSegment:
    mov al, '+'
    call WriteChar
    push ecx
    mov ecx, CELL_W
dashes:
    mov al, '-'
    call WriteChar
    loop dashes
    pop ecx
    loop colSegment

    mov al, '+'                     ; closing corner
    call WriteChar
    ret
DrawBorder ENDP

; ============================================================
; M3-P2 / M3-P3  DrawCell
; Prints exactly CELL_W characters: blanks for 0, otherwise the
; number centred in the cell and coloured by its power of two.
; Restores the default colour afterwards.
; ============================================================
DrawCell PROC USES eax ebx ecx edx, value:DWORD
    LOCAL digits:DWORD, padL:DWORD

    mov eax, value
    test eax, eax
    jnz hasValue

    ; ---- empty cell: dark-grey blanks ----
    mov eax, EMPTY_ATTR
    call SetTextColor
    mov ecx, CELL_W
blanks:
    mov al, ' '
    call WriteChar
    loop blanks
    jmp finish

hasValue:
    ; ---- M3-P3: ECX = log2(value) using a SHR loop ----
    mov ebx, eax
    xor ecx, ecx
log2Loop:
    cmp ebx, 1
    jbe log2Done
    shr ebx, 1
    inc ecx
    jmp log2Loop
log2Done:
    cmp ecx, MAX_COLOR_IDX
    jbe colourIdxOk
    mov ecx, MAX_COLOR_IDX          ; clamp for very large tiles
colourIdxOk:
    mov eax, tileColors[ecx * 4]
    call SetTextColor

    ; ---- M3-P2: count decimal digits with DIV ----
    mov eax, value
    xor ebx, ebx
    mov ecx, 10
digitLoop:
    xor edx, edx
    div ecx                         ; EAX = EAX / 10
    inc ebx
    test eax, eax
    jnz digitLoop
    mov digits, ebx

    ; ---- padL = (CELL_W - digits) / 2  (DIV again) ----
    mov eax, CELL_W
    sub eax, ebx
    xor edx, edx
    mov ecx, 2
    div ecx
    mov padL, eax

    mov ecx, padL                   ; left padding
    jecxz printNumber
leftPad:
    mov al, ' '
    call WriteChar
    loop leftPad

printNumber:
    mov eax, value
    call WriteDec

    mov ecx, CELL_W                 ; right padding = W - digits - padL
    sub ecx, digits
    sub ecx, padL
    jecxz finish
rightPad:
    mov al, ' '
    call WriteChar
    loop rightPad

finish:
    mov eax, DEFAULT_ATTR
    call SetTextColor
    ret
DrawCell ENDP

; ============================================================
; M3-P3  DrawPanel
; Score, best score, target and controls to the right of the grid.
; ============================================================
DrawPanel PROC USES eax edx
    LOCAL px:DWORD

    mov eax, boardN                 ; px = BOARD_X + N*(CELL_W+1) + 4
    imul eax, CELL_W + 1
    add eax, BOARD_X + 4
    mov px, eax

    mov eax, lightCyan + (black * 16)
    call SetTextColor

    mGoto <BYTE PTR px>, BOARD_Y
    mov edx, OFFSET sScoreLbl
    call WriteString
    mov eax, score
    call WriteDec
    mov edx, OFFSET sPad
    call WriteString

    mGoto <BYTE PTR px>, <BOARD_Y + 2>
    mov edx, OFFSET sBestLbl
    call WriteString
    mov eax, bestScore
    call WriteDec
    mov edx, OFFSET sPad
    call WriteString

    mGoto <BYTE PTR px>, <BOARD_Y + 4>
    mov edx, OFFSET sTargetLbl
    call WriteString
    mov eax, target
    call WriteDec

    mov eax, DEFAULT_ATTR
    call SetTextColor
    mGoto <BYTE PTR px>, <BOARD_Y + 7>
    mov edx, OFFSET sCtrlHdr
    call WriteString
    mGoto <BYTE PTR px>, <BOARD_Y + 8>
    mov edx, OFFSET sCtrl1
    call WriteString
    mGoto <BYTE PTR px>, <BOARD_Y + 9>
    mov edx, OFFSET sCtrl2
    call WriteString
    mGoto <BYTE PTR px>, <BOARD_Y + 10>
    mov edx, OFFSET sCtrl3
    call WriteString
    mGoto <BYTE PTR px>, <BOARD_Y + 11>
    mov edx, OFFSET sCtrl4
    call WriteString
    ret
DrawPanel ENDP

; ============================================================
; M3-P1 .. P3  DrawBoard
; Redraws the whole screen area in place (no Clrscr, so no flicker).
; Call Clrscr once when a game starts or the board size changes.
;
; Layout per row r (y = BOARD_Y + 2r):
;     y     +------+------+      border
;     y+1   |  2   |      |      content
; ============================================================
DrawBoard PROC USES eax ebx ecx edx esi edi
    mov eax, DEFAULT_ATTR
    call SetTextColor

    ; ---- title: "2048  -  NxN" ----
    mGoto BOARD_X, 1
    mov edx, OFFSET sBoardTitle
    call WriteString
    mov eax, boardN
    call WriteDec
    mov al, 'x'
    call WriteChar
    mov eax, boardN
    call WriteDec

    xor esi, esi                    ; ESI = row
rowLoop:
    cmp esi, boardN
    jae lastBorder

    mov eax, esi                    ; border at y = BOARD_Y + 2*row
    shl eax, 1
    add eax, BOARD_Y
    INVOKE DrawBorder, eax

    inc eax                         ; content line is one row below
    mGoto BOARD_X, al

    xor edi, edi                    ; EDI = column
colLoop:
    cmp edi, boardN
    jae endRow

    mov eax, DEFAULT_ATTR
    call SetTextColor
    mov al, '|'
    call WriteChar

    mov eax, esi                    ; index = row*N + col
    imul eax, boardN
    add eax, edi
    mov eax, board[eax * 4]         ; value of this cell
    INVOKE DrawCell, eax

    inc edi
    jmp colLoop

endRow:
    mov eax, DEFAULT_ATTR
    call SetTextColor
    mov al, '|'
    call WriteChar
    inc esi
    jmp rowLoop

lastBorder:
    mov eax, boardN                 ; bottom border at BOARD_Y + 2N
    shl eax, 1
    add eax, BOARD_Y
    INVOKE DrawBorder, eax

    call DrawPanel
    ret
DrawBoard ENDP

; ============================================================
; Status row messages (week 3)  -  Aryaan
; All three write on STATUS_ROW, below the board.
; ============================================================
.data
sWinMsg     BYTE "YOU WIN! You reached the target tile. Keep playing, or R = restart, Q = menu",0
sOverMsgA   BYTE "GAME OVER   Final score: ",0
sOverMsgB   BYTE "   U = undo, R = restart, Q = menu",0

.code
; ClearStatus: blanks the status row (80 characters)
ClearStatus PROC USES eax ecx edx
    mGoto 0, STATUS_ROW
    mov eax, DEFAULT_ATTR
    call SetTextColor
    mov ecx, 80
blankLoop:
    mov al, ' '
    call WriteChar
    loop blankLoop
    ret
ClearStatus ENDP

; ShowWin: shown once per game when the target tile is reached
ShowWin PROC USES eax edx
    call ClearStatus
    mGoto 0, STATUS_ROW
    mov eax, yellow + (black * 16)
    call SetTextColor
    mov edx, OFFSET sWinMsg
    call WriteString
    mov eax, DEFAULT_ATTR
    call SetTextColor
    ret
ShowWin ENDP

; ShowGameOver: "GAME OVER   Final score: N   U = undo, R = restart, Q = menu"
ShowGameOver PROC USES eax edx
    call ClearStatus
    mGoto 0, STATUS_ROW
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov edx, OFFSET sOverMsgA
    call WriteString
    mov eax, score
    call WriteDec
    mov edx, OFFSET sOverMsgB
    call WriteString
    mov eax, DEFAULT_ATTR
    call SetTextColor
    ret
ShowGameOver ENDP

END
