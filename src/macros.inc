; =========================================================================
; src/macros.inc
; =========================================================================

; Sets the console text color
mSetColor MACRO color
    push eax
    mov eax, color
    call SetTextColor
    pop eax
ENDM

; Calculates 1D offset from 2D grid: offset = (row * rowSize) + col
; Returns offset in EAX
mCellAddr MACRO row, col, rowSize
    push ebx
    mov eax, row
    mov ebx, rowSize
    mul ebx             ; eax = row * rowSize
    add eax, col        ; eax = (row * rowSize) + col
    pop ebx
ENDM