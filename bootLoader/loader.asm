%include "loader.inc"

[org LinearAdreesOfLoader]
jmp _start

[section .GDT]

GDT_DESC_EMPTY: dd 0,0
GDT_DESC_CODE32: dd 0x0000FFFF, 0x00CF9A00
GDT_DESC_DATA32: dd 0x0000FFFF, 0x00CF9200

GDT_LEN equ $ - GDT_DESC_EMPTY
GDT_PTR:    dw GDT_LEN - 1
            dd GDT_DESC_EMPTY

SelectorCode32 equ GDT_DESC_CODE32 - GDT_DESC_EMPTY
SelectorData32 equ GDT_DESC_DATA32 - GDT_DESC_EMPTY

[section .GDT64]

GDT64_START:
GDT64_DESC_EMPTY: dq 0x0000000000000000
GDT64_DESC_CODE64: dq 0x0020980000000000
GDT64_DESC_DATA64: dq 0x0000920000000000

GDT64_LEN equ $ - GDT64_DESC_EMPTY
GDT64_PTR:  dw GDT64_LEN - 1
            dd GDT64_DESC_EMPTY

SelectorCode64 equ GDT64_DESC_CODE64 - GDT64_DESC_EMPTY
SelectorData64 equ GDT64_DESC_DATA64 - GDT64_DESC_EMPTY

[section .bits16]
[BITS 16]

_start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

    ; hide cursor
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    mov cx, loaderMsgEnd - loaderMsg
    mov bp, loaderMsg
    call _rPrintLine

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

    ; disable protection mode
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
    call _rPrintLine
    pop ax

    call _copyKernel
    call _rNewline
    call _getSVGAInfo
    call _rNewline
    call _getMemInfo
    jc .error

    call _rNewline
    mov cx, getMemInfoDoneMsgEnd - getMemInfoDoneMsg
    mov bp, getMemInfoDoneMsg
    call _rPrintLine

    mov [Cursor_row], dh
    mov [Cursor_col], dl

    mov ax, 0x100
    mov cx, 10
    call _rPrintInt

    jmp _goToProtectionMode

.end:
    jmp $

.error:
    mov cx, errorMsgEnd - errorMsg
    mov bp, errorMsg
    call _rPrintLine
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
StartGetSVGAModeInfoMsg: db "Start Get SVGA Mode Info"
StartGetSVGAModeInfoMsgEnd:
GetSVGAErrorInfoMsg: db 'Get SVGA VBE Info ERROR'
GetSVGAErrorInfoMsgEnd:
kernelFileName: db 'KERNEL  BIN'

Cursor_row db 0
Cursor_col db 0

;--- function get memory info
; carry if error
_getMemInfo:
    pusha

    mov cx, getMemInfoMsgEnd - getMemInfoMsg
    mov bp, getMemInfoMsg
    call _rPrintLine

    and word [AddressOfARDSCnt], 0
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
    add word [AddressOfARDSCnt], 1
    cmp ebx, 0
    jnz .getMemBegin
    jmp .getMemEnd

.getMemFail:
    mov cx, getMemInfosearchErrorMsgEnd - getMemInfosearchErrorMsg
    mov bp, getMemInfosearchErrorMsg
    call _rPrintLine

    xor ax, ax
    cmp ax, 1
.getMemEnd:
    popa
    ret

;---
_getSVGAInfo:
    pusha
    mov cx, StartGetSVGAModeInfoMsgEnd - StartGetSVGAModeInfoMsg
    mov bp, StartGetSVGAModeInfoMsg
    call _rPrintLine

    ; get vbeInfoBlock
    mov ax, 0x00
    mov es, ax
    mov di, TmpBufferAddress
    mov ax, 4F00h
    int 10h

    cmp ax, 004Fh
    jz  .sucess

.failed:
    mov cx, GetSVGAErrorInfoMsgEnd - GetSVGAErrorInfoMsg
    mov bp, GetSVGAErrorInfoMsg
    call _rPrintLine
    jmp $

.sucess:
    mov si, TmpBufferAddress + 0x0e
    mov esi, dword [es:si]
    mov di, TmpBufferAddress + 0x200

.getModeInfoBlock:
    mov ax, [es:si]
    cmp ax, 0xffff
    jz .setVBEMode

    push ax
    mov cx, 16
    call _rPrintInt

    mov ah, 0x0e
    mov bx, 0x0000
    mov al, ' '
    int 0x10
    
    pop cx
    mov ax, 0x4f01
    int 0x10
    cmp ax, 0x004f
    jnz .failed

    add si, 2
    add di, 0x100

    jmp .getModeInfoBlock

.setVBEMode:
    mov ax, 0x4F02
    mov bx, 0x4180 ; mode: 180
    int     0x10
    cmp ax, 0x004F
    jnz .failed

.finish:
    popa
    ret

;--- function copy kernel
; ax: cluster number
_copyKernel:
    pusha
.copyBegin:
    push ax
    mov ah, 0x0e
    mov al, '#'
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

    push ax
    mov cx, 11   ; cx = number of chars in string
    mov bp, di ; ES:BP address of string
    call _rPrintLine
    pop ax
    ret

.loaderNotFound:
    mov cx, searchErrorMsgEnd - searchErrorMsg
    mov bp, searchErrorMsg
    call _rPrintLine

    mov ax, 0; return 0 when not found
    ret

_rPrintLine:
    call _rPrint
    call _rNewline
    ret
    
;--- function print
; cx: number of chars in string
; ES:BP: address of string
_rPrint:
    mov bx, 0x000f  ; bh = page number, bl = char color
    push cx
    mov ah, 0x03    ; ah 03: get cursor position
    int 0x10        ; return: dh = row, dl = column
    pop cx

    mov ax, 0x1301   ; ah 13, write string; al=01, write mode: char attribute in bl, cursor move to end of string
    ; dh = row, dl = column; cx: num of chars
    int 0x10

    ret

;--- 
; ax: int to print
; cx: base
intBuffer times 10 db 0x00
intLUT db '0123456789ABCDEF'
_rPrintInt:
    mov bx, 10
.hexToDecimalism:
    sub bx, 1
    xor dx, dx
    div cx
    push bx
    mov bx, dx
    mov dl, byte [intLUT + bx]
    pop bx
    mov byte [bx + intBuffer], dl
    cmp bx, 0
    jz .print
    cmp ax, 0
    jz .print
    jmp .hexToDecimalism
.print:
    mov cx, 10
    sub cx, bx
    mov bp, intBuffer
    add bp, bx
    call _rPrint
    ret

_rNewline:
    push cx
    mov bx, 0x0000
    mov ah, 0x03    ; ah 03: get cursor position
    int 0x10        ; return: dh = row, dl = column

    mov ah, 0x02     ; new line“
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


;==== protection mode message

gotoLongModeMsg: db 'ready to go to long mode', 0x0a, 0x00
initTempPageTableMsg: db 'init temporary page table', 0x0d, 0x00

_goToProtectionMode:
    cli
    
    db 0x66
    lgdt [GDT_PTR]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; udpate cs by far jmp
    jmp SelectorCode32:.p_start

[section .bits32]
[BITS 32]
.p_start:
    mov ax, SelectorData32
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, BaseOfStack

    call _checkLongMode
    test eax, eax
    jz .notSupport
    jmp .gotoLongMode

.notSupport:
    hlt

.gotoLongMode:
    call _pNewline
    mov ebp, gotoLongModeMsg
    call _putString

    mov ebp, initTempPageTableMsg
    call _putString

    ;init temporary page table 0x90000

    mov dword [0x90000], 0x91007
    mov dword [0x90004], 0x00000
    mov dword [0x90800], 0x91007
    mov dword [0x90804], 0x00000

    mov dword [0x91000], 0x92007
    mov dword [0x91004], 0x00000

    mov dword [0x92000], 0x000083
    mov dword [0x92004], 0x000000

    mov dword [0x92008], 0x200083
    mov dword [0x9200c], 0x000000

    mov dword [0x92010], 0x400083
    mov dword [0x92014], 0x000000

    mov dword [0x92018], 0x600083
    mov dword [0x9201c], 0x000000

    mov dword [0x92020], 0x800083
    mov dword [0x92024], 0x000000

    mov dword [0x92028], 0xa00083
    mov dword [0x9202c], 0x000000

    ; load GDTR
    lgdt [GDT64_PTR]
    mov ax, SelectorData64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, BaseOfStack

    ; open PAE
    mov eax, cr4
    bts eax, 5
    mov cr4, eax

    ; load cr3 (page table)
    mov eax, 0x90000
    mov cr3, eax

    ; enable long-mode
    mov ecx, 0C0000080h  ;IA32_EFER
    rdmsr
    bts eax, 8
    wrmsr

    ; open PE and paging
    mov eax, cr0
    bts eax, 0
    bts eax, 31
    mov cr0, eax

    jmp SelectorCode64:OffsetOfKernel


;---
; es:ebp string address
_putString:
    mov ah, [es:ebp]
    inc ebp
    cmp ah, 0x00
    jz .done
    call _putChar
    jmp _putString
.done:
    ret
    

;---
; ah: char to put screen
_putChar:
    pushad
    cmp ah, 0x0d
    jz .newline
    cmp ah, 0x0a
    jz .newline
    jmp .putOther
.newline:
    mov ah, 0x00
    mov [Cursor_col], ah
    call _pNewline
    jmp .end
.putOther:
    mov dh, ah
    xor eax, eax
    mov al, byte [Cursor_col]
    mov dl, al
    mov bh, 2
    mul bh
    push ax
    mov al, [Cursor_row]
    mov bl, 160
    mul bl
    pop bx
    add bx, ax
    mov ah, 0x0f
    mov al, dh
    mov [0xb8000 + ebx], ax

    xor eax, eax
    mov al, dl
    inc al
    mov bl, 80
    div bl
    mov [Cursor_col], ah
    cmp al, 0
    jz .end
    call _pNewline
.end:
    popad
    ret

;---
_pNewline:
    push eax
    push ebx
    push ecx
    xor eax, eax
    mov al, [Cursor_row]
    inc al
    mov bl,25
    div bl
    mov [Cursor_row], ah
    cmp al, 0
    jz .curpage
    mov ecx, 1000
.clearDWord:
    mov dword [ecx * 4 + 0xb8000 - 4], 0x0000
    loop .clearDWord
.curpage:
    pop ecx
    pop ebx
    pop eax
    ret


_checkLongMode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    setnb al 
    jb .checkLMDone
    mov eax, 0x80000001
    cpuid
    bt edx, 29
    setc al
.checkLMDone:
    movzx eax, al
    ret
