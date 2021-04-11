[org 0x10_0000]

[BITS 16]

_start
    mov cx, kernelMsgEnd - kernelMsg
    mov bp, kernelMsg
    call _printLine

.end
    hlt


;=== message 
kernelMsg: db 'start kernel'
kernelMsgEnd

;--- function display message
; cx: number of chars in string
; ES:BP: address of string
_printLine:
    pusha
    mov bx, 0x000f  ; bh = page number, bl = char color
    push cx
    mov ah, 0x03    ; ah 03: get cursor position
    int 0x10        ; return: dh = row, dl = column
    pop cx

    mov ax, 0x1301   ; ah 13, write string; al=01, write mode: char attribute in bl, cursor move to end of string
    ; dh = row, dl = column; cx: num of chars
    int 0x10

    mov ah, 0x02     ; new line
    inc dh
    mov dl, 0x00
    int 0x10

    popa
    ret