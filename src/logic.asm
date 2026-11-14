; ============================================================
; logic.asm - Core logic   Owner: Syed Burhan Hussain Shah
;   Module 2 (board config): SetTarget, AskBoardSize, InitBoard
;   Module 5 (SlideLine) and Module 6 (MoveBoard, GetDirParams) follow.
; Keep your own first lines if they differ (.386 / .model / INCLUDE).
; ============================================================
INCLUDE Irvine32.inc
INCLUDE game_macros.inc
INCLUDE module.inc

PUBLIC AskBoardSize, SetTarget, InitBoard
PUBLIC SlideLine, GetDirParams, MoveBoard
EXTERN boardN:DWORD, target:DWORD, board:DWORD, score:DWORD

.data
sAskN   BYTE "Enter board size N (3 to 8): ",0
sBadN   BYTE "Invalid size. Enter a whole number from 3 to 8.",0Dh,0Ah,0

.code
; ============================================================
; M2-P1  SetTarget
; Target tile rule: 512 on a 3x3 board, 2048 on every other size.
; Reads boardN, writes target.
; ============================================================
SetTarget PROC
    mov target, TARGET_DEFAULT      ; 2048
    cmp boardN, 3
    jne done
    mov target, TARGET_3X3          ; 512
done:
    ret
SetTarget ENDP

; ============================================================
; M2-P1  AskBoardSize
; Prompts until the player types a whole number MIN_N..MAX_N.
; Rejects letters, empty input, negatives, 0, 1, 2 and 9 or more.
; Stores the result in boardN, sets target through SetTarget.
; Returns: EAX = chosen N
; ============================================================
AskBoardSize PROC USES edx
askAgain:
    mov edx, OFFSET sAskN
    call WriteString
    call ReadInt                    ; OF=1 if the text is not a valid integer
    jo  badSize
    cmp eax, MIN_N                  ; signed compare also rejects negatives
    jl  badSize
    cmp eax, MAX_N
    jg  badSize

    mov boardN, eax
    call SetTarget
    ret

badSize:
    mov edx, OFFSET sBadN
    call WriteString
    jmp askAgain
AskBoardSize ENDP

; ============================================================
; M2-P2  InitBoard
; Clears the N x N cells of the board with REP STOSD and resets
; the score to 0.  bestScore is kept (it lives for the session).
; Cells beyond N*N are never read, so they are left alone.
; Also used by Restart (M9), which keeps the same boardN.
; ============================================================
InitBoard PROC USES eax ecx edi
    cld                             ; STOSD must count upward
    mov edi, OFFSET board           ; destination
    mov ecx, boardN                 ; count = N * N DWORDs
    imul ecx, boardN
    xor eax, eax                    ; value 0
    rep stosd
    mov score, 0
    ret
InitBoard ENDP

; ============================================================
; Module 5 - SlideLine(lineStart, lineStep, lineLen)
; Owner : Syed Burhan Hussain Shah (25K-2518)
; Branch: feature/m5-slideline
;
; Slides and merges ONE line of the board toward its start.
;   lineStart : ADDRESS (bytes) of the first cell in travel order
;   lineStep  : signed BYTE step to the next cell in the line
;               (+4 / -4 for rows, +4N / -4N for columns)
;   lineLen   : number of cells in the line (= N)
; Returns: EAX = score gained, EDX = 1 if any cell changed else 0
;
; Phases: M5-P1 pack tiles into a LOCAL buffer in travel order
;         M5-P2 merge equal neighbours once per move (SHL)
;         M5-P3 write back zero-padded, set the moved flag
; ============================================================
SlideLine PROC USES ebx ecx esi edi, lineStart:DWORD, lineStep:SDWORD, lineLen:DWORD
    LOCAL buf[MAX_N]:DWORD
    LOCAL tileCnt:DWORD, outCnt:DWORD, gained:DWORD, moved:DWORD

    mov gained, 0
    mov moved, 0
    lea edi, buf                    ; EDI = packed buffer

    ; ---- M5-P1: pack non-zero tiles, in travel order ----
    mov esi, lineStart
    mov ecx, lineLen
    xor ebx, ebx                    ; EBX = tiles packed so far
packLoop:
    mov eax, [esi]
    test eax, eax
    jz  packNext
    mov [edi + ebx * 4], eax
    inc ebx
packNext:
    add esi, lineStep               ; negative step walks backwards
    loop packLoop
    mov tileCnt, ebx

    ; ---- M5-P2: merge equal neighbours, each tile at most once ----
    xor eax, eax                    ; EAX = read index
    xor edx, edx                    ; EDX = write index (never ahead of read)
    mov ecx, tileCnt
mergeLoop:
    cmp eax, ecx
    jae mergeDone
    mov ebx, [edi + eax * 4]        ; current tile
    lea esi, [eax + 1]              ; index of its right neighbour
    cmp esi, ecx
    jae keepTile                    ; no neighbour left
    cmp ebx, [edi + esi * 4]
    jne keepTile
    shl ebx, 1                      ; equal: double the first tile
    add gained, ebx                 ; score += merged value
    add eax, 2                      ; consume BOTH tiles (merge once)
    jmp storeTile
keepTile:
    inc eax
storeTile:
    mov [edi + edx * 4], ebx
    inc edx
    jmp mergeLoop
mergeDone:
    mov outCnt, edx                 ; tiles left after merging

    ; ---- M5-P3: write back zero-padded, detect change ----
    mov esi, lineStart
    xor ebx, ebx                    ; EBX = position in the line
writeLoop:
    xor eax, eax                    ; default new value = 0
    cmp ebx, outCnt
    jae haveValue
    mov eax, [edi + ebx * 4]
haveValue:
    cmp eax, [esi]
    je  sameCell
    mov [esi], eax
    mov moved, 1                    ; at least one cell changed
sameCell:
    add esi, lineStep
    inc ebx
    cmp ebx, lineLen
    jb  writeLoop

    mov eax, gained
    mov edx, moved
    ret
SlideLine ENDP

; ============================================================
; Module 6 - MoveBoard
; Branch: feature/m6-moveboard
; Phases: M6-P1 GetDirParams (direction table)
;         M6-P2 MoveBoard (loop of SlideLine calls)
;         M6-P3 test on N = 3, 4 and 8 (test_moveboard.asm)
; ============================================================

; ------------------------------------------------------------
; M6-P1  GetDirParams(dir, pStart, pStep, pNext)
; The direction table of Section 10, as code.  Writes through
; the three pointers:
;   *pStart = address of the first cell of line 0
;   *pStep  = byte step inside a line
;   *pNext  = byte step from one line to the next
;
;   dir     start of line 0     step in line   step to next line
;   LEFT    row 0, col 0        +4             +4N
;   RIGHT   row 0, col N-1      -4             +4N
;   UP      row 0, col 0        +4N            +4
;   DOWN    row N-1, col 0      -4N            +4
; (Any other dir value is treated as DOWN.)
; ------------------------------------------------------------
GetDirParams PROC USES eax ebx ecx edx esi, dir:DWORD, pStart:PTR DWORD, pStep:PTR SDWORD, pNext:PTR SDWORD
    mov ebx, boardN
    shl ebx, 2                      ; EBX = 4N (one row, in bytes)
    mov ecx, OFFSET board           ; ECX = start of line 0
    mov eax, dir
    cmp eax, DIR_LEFT
    je  dirLeft
    cmp eax, DIR_RIGHT
    je  dirRight
    cmp eax, DIR_UP
    je  dirUp

dirDown:
    mov eax, boardN
    dec eax
    imul eax, ebx                   ; (N-1) * 4N
    add ecx, eax                    ; start at row N-1
    mov edx, ebx
    neg edx                         ; step -4N
    mov esi, 4                      ; next line = next column
    jmp storeParams
dirLeft:
    mov edx, 4
    mov esi, ebx                    ; next line = next row
    jmp storeParams
dirRight:
    mov eax, boardN
    dec eax
    shl eax, 2
    add ecx, eax                    ; start at column N-1
    mov edx, -4
    mov esi, ebx
    jmp storeParams
dirUp:
    mov edx, ebx                    ; step +4N
    mov esi, 4
storeParams:
    mov eax, pStart
    mov [eax], ecx
    mov eax, pStep
    mov [eax], edx
    mov eax, pNext
    mov [eax], esi
    ret
GetDirParams ENDP

; ------------------------------------------------------------
; M6-P2  MoveBoard(dir)
; Slides the whole board in one direction by calling the SAME
; procedure SlideLine once per line.
; Returns: EAX = total score gained, EDX = 1 if any cell changed
; (does NOT change score, spawn tiles or redraw: that is M8)
; ------------------------------------------------------------
MoveBoard PROC USES ecx, dir:DWORD
    LOCAL lineStart:DWORD, stepIn:SDWORD, stepNext:SDWORD
    LOCAL totalGain:DWORD, anyMoved:DWORD

    INVOKE GetDirParams, dir, ADDR lineStart, ADDR stepIn, ADDR stepNext
    mov totalGain, 0
    mov anyMoved, 0
    mov ecx, boardN                 ; N lines
lineLoop:
    INVOKE SlideLine, lineStart, stepIn, boardN
    add totalGain, eax              ; accumulate score
    or  anyMoved, edx               ; accumulate moved flag
    mov eax, stepNext
    add lineStart, eax              ; go to the next line
    loop lineLoop

    mov eax, totalGain
    mov edx, anyMoved
    ret
MoveBoard ENDP

END
