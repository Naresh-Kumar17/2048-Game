; =========================================================================
; src/main.asm
; =========================================================================
INCLUDE Irvine32.inc
INCLUDE macros.inc
INCLUDE module.inc

; Pull in the data segment
INCLUDE data.asm
.code
main PROC

GameLoop:
    cmp gameActive, 0
    je QuitGame

    ; Call the modules your team will build
    call HandleInput
    call UpdateLogic
    call DrawScreen
    
    ; Add a small delay so the loop doesn't max out the CPU
    mov eax, 50
    call Delay
    
    jmp GameLoop

QuitGame:
    exit
main ENDP
END main