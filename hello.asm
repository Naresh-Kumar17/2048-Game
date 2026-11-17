INCLUDE Irvine32.inc
.code
main PROC
    mov edx, OFFSET msg
    call WriteString
    exit
main ENDP
.data
msg BYTE "Hello",0Dh,0Ah,0
END main