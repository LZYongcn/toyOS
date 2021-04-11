[org 0x9000]
jmp _start

%include "loader.inc"

[section .GDT]

GDT_START:
GDT_DESC_EMPTY: dd 0,0
GDT_DESC_CODE32: dd 0x0000FFFF, 0x00CF9A00
GDT_DESC_DATA32: dd 0x0000FFFF, 0x00CF9200

GDT_LEN equ $ - GDT_START
GDT_PTR:    dw GDT_LEN - 1
            dd GDT_START

SelectorCode32 equ GDT_DESC_CODE32 - GDT_START
SelectorData32 equ GDT_DESC_DATA32 - GDT_START

[section .bits16]
[BITS 16]

_start:
    mov cx, loaderMsgEnd - loaderMsg
    mov bp, loaderMsg
    call _printLine

    db 0x66
    lgdt [GDT_PTR]

    ; Expanded addressing capabilities, enter big real mode
    ; open address A20 by read 0xee port
    in al, 0xee

    cli

    ; enable protection mode
    mov eax, cr0
    or al, 1
    mov cr0, eax

    mov ax, SelectorData32
    mov fs, ax
    mov eax, cr0
    and al, 0xfe
    mov cr0, eax

    sti

    call _searchkernel
    cmp ax, 0
    jz .error

    push ax
    mov cx, successMsgEnd - successMsg
    mov bp, successMsg
    call _printLine
    pop ax

    call _copyKernel
    call _newline
    call _getMemInfo
    jc .error

    call _newline
    mov cx, getMemInfoDoneMsgEnd - getMemInfoDoneMsg
    mov bp, getMemInfoDoneMsg
    call _printLine

.end:
    jmp $

.error:
    mov cx, errorMsgEnd - errorMsg
    mov bp, errorMsg
    call _printLine
    jmp $

;=== variable
    sectorNo dw SectorNoOfRootDir
    rootDirLoopCount dw RootDirSectors
    copiedBytes dd 0

; === messages

loaderMsg: db 'start loader'
loaderMsgEnd:
errorMsg: db 'something went wrong'
errorMsgEnd:
searchErrorMsg: db 'kernel not found'
searchErrorMsgEnd:
successMsg: db 'start copy kernel'
successMsgEnd:
getMemInfoMsg: db 'start get memory info'
getMemInfoMsgEnd:
getMemInfoDoneMsg: db 'get memory info done'
getMemInfoDoneMsgEnd:
getMemInfosearchErrorMsg: db 'error when get mem info'
getMemInfosearchErrorMsgEnd:
kernelFileName: db 'KERNEL  BIN'


;--- function get memory info
; carry if error
_getMemInfo:
    pusha

    mov cx, getMemInfoMsgEnd - getMemInfoMsg
    mov bp, getMemInfoMsg
    call _printLine

    mov ebx, 0
    mov [AddressOffsetOfARDSCnt], ebx
    mov di, AddressOffsetOfARDSs

.getMemBegin:
    mov eax, 0xe820
    mov ecx, ARDS_sizePerDs
    mov edx, 0x534D4150 ; 'SMAP'
    int 0x15
    jc .getMemFail

    pusha
    mov ax, 0x0e23
    mov bx, 0x0000
    int 0x10
    popa
    add di, ARDS_sizePerDs
    add dword [AddressOffsetOfARDSCnt], 1
    cmp ebx, 0
    jnz .getMemBegin
    jmp .getMemEnd

.getMemFail:
    mov cx, getMemInfosearchErrorMsgEnd - getMemInfosearchErrorMsg
    mov bp, getMemInfosearchErrorMsg
    call _printLine

    mov ax, 0
    cmp ax, 1
.getMemEnd:
    popa
    ret

;--- function copy kernel
; ax: cluster number
_copyKernel:
    pusha
.copyBegin:
    push ax
    mov ax, 0x0e23
    mov bx, 0x0000
    int 0x10
    pop ax

    add ax, ClusterSecNoOffset
    mov cl, 1
    mov bx, TmpBufferAddress
    mov word [sectorNo], ax
    call _readSector

    mov cx, 0x200
    mov si, TmpBufferAddress
    mov edi, [copiedBytes]
    add edi, OffsetOfKernel

.copyOneWord:
    mov al, [ds:si]
    mov [fs:edi], al

    inc si
    inc edi

    loop .copyOneWord


    add dword [copiedBytes], 0x200

    mov ax, [sectorNo]
    sub ax, ClusterSecNoOffset
    call _getNextClusterNo

    cmp ax, 0x0fff
    jnz .copyBegin
    popa
    ret

;--- function get next entry
; ax: current cluster nomber
_getNextClusterNo:
    push bx
    push cx
    push dx

    mov bx, 3
    mul bx 
    mov bx, 2
    div bx
    push dx
    mov bx, BytePerSec
    xor dx, dx
    div bx
    mov bx, dx
    push bx
    add ax, word SectorNoOfFAT1
    mov cl, 2
    mov bx, TmpBufferAddress
    
    call _readSector

    pop bx
    mov ax, [bx + TmpBufferAddress]

    pop dx
    cmp dx, 0
    jz .clusterEven
    
    shr ax, 4
    jmp .sectorEnd

.clusterEven:
    and ax, 0x0fff
.sectorEnd:
    pop dx
    pop cx
    pop bx
    ret

;--- function search kernel
_searchkernel:
    mov word [rootDirLoopCount], RootDirSectors
.searchNextSector:
    cmp word [rootDirLoopCount], 0
    jz .loaderNotFound
    dec word [rootDirLoopCount]

    ; read one sector of root dir to 0x8000
    mov bx, TmpBufferAddress
    mov ax, [sectorNo]
    mov cl, 1
    call _readSector

    add word [sectorNo], 1

    mov di, TmpBufferAddress
    sub di, 0x0020
    mov dx, 16        ; 16 entries per sector

.searchNextEntry:
    and di, 0xffe0
    add di, 0x0020
    mov si, kernelFileName

    cmp dx, 0
    jz .searchNextSector
    dec dx

    mov ax, [es:di + DIR_firstClusterNoOffset] ; check cluster Number
    cmp ax, 0
    jz .searchNextEntry

    mov cx, 11
.cmpFileName:
    cmp cx, 0
    jz .loaderFound
    dec cx
    lodsb
    cmp al, byte [es:di]
    jz .goOnCmp
    jmp .searchNextEntry

.goOnCmp:
    inc di
    jmp .cmpFileName

.loaderFound:
    and di, 0xffe0
    mov ax, [es:di + DIR_firstClusterNoOffset] ; return cluster Number if found

    mov cx, 11   ; cx = number of chars in string
    mov bp, di ; ES:BP address of string
    call _printLine
    ret

.loaderNotFound:
    mov cx, searchErrorMsgEnd - searchErrorMsg
    mov bp, searchErrorMsg
    call _printLine

    mov ax, 0; return 0 when not found
    ret

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

    call _newline

    popa
    ret

_newline:
    push cx
    mov bx, 0x0000
    mov ah, 0x03    ; ah 03: get cursor position
    int 0x10        ; return: dh = row, dl = column

    mov ah, 0x02     ; new line
    inc dh
    mov dl, 0x00
    int 0x10
    pop cx
    ret


;=== read data from floppy

;--- function: readSector
; ax: sector no
; cl: sectors to read
; es:bx buffer address write to
_readSector:
    ; int 13h call;Drive=>dl; sectors to read=>al; sub function no(02h)=>ah; buffer addres=> es:bx
    ; calculate CHS; cylinder=>ch; head=>dh; sector=>cl; 
    pusha
    mov bp, sp
    sub sp, 2
    mov byte [bp - 2], cl
    push bx
    mov bl, SecPerTrack
    div bl
    pop bx
    inc ah
    mov cl, ah
    mov ch, al
    shr ch, 1
    mov dl, DriveNo
    mov dh, al
    and dh, 1
    ; call int 13h
.retry:
    mov ah, 0x02
    mov al, [bp - 2]
    int 0x13
    jc .retry

    add sp, 2
    popa
    ret