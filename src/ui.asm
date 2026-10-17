; =========================================================================
; src/ui.asm
; =========================================================================
INCLUDE Irvine32.inc
INCLUDE macros.inc
INCLUDE module.inc

.data
testMsg BYTE "Project Scaffolding is working! Team can start coding.", 0

.code
DrawScreen PROC
    ; Move cursor to top-left (x=0, y=0) so it doesn't print endlessly down the screen
    mov dl, 0
    mov dh, 0
    call Gotoxy

    ; Print the test message
    mov edx, OFFSET testMsg
    call WriteString
    
    ret
DrawScreen ENDP
END