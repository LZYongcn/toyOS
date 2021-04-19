%include "boot.inc"
[org 0x7c00]

;=== Boot sector
    jmp short _start
    nop ; offset 0, 3 bytes

    BS_OEM_NAME db OemName   ; offset 3; 8 bytes
    times 8 - ($ - BS_OEM_NAME) db 0x00
    BS_BYTE_PER_SEC dw  BytePerSec  ; offset 11;    2 bytes
    BS_SEC_PER_CLUS db  SecPerClus  ; offset 13;    1 byte
    BS_RESVD_SEC    dw  ReservedSec    ; offset 14;    2 bytes
    BS_FATS_CNT     db  FatsCnt     ; offset 16;    1 bytes
    BS_ROOT_ENTRY_CNT    dw  RootEntryCnt   ; offset 17;    2 bytes
    BS_SEC_CNT16    dw  SecCnt16    ; offset 19;    2 bytes
    BS_MEDIA_DSCRB  db  MediaDscrb  ; offset 21; 1 byte
    BS_SEC_PER_FAT  dw  SecPerFat   ; offset 22; 2 bytes
    BS_SEC_PER_TRACK    dw  SecPerTrack ; offset 24; 2 bytes
    BS_HEAD_CNT     dw  HeadCnt     ; offset 26; 2 bytes
    BS_HID_SEC      dd  HidSec      ; offset 28; 4 bytes
    BS_SEC_CNT32    dd  SecCnt32    ; offset 32; 4 bytes
    BS_DRIVE_NO    db  DriveNo    ; offset 36; 1 byte
    BS_RESERVED    db  Reserved     ; offset 37; 1 byte
    BS_BOOT_SIG     db  BootSig     ; offset 38; 1 byte
    BS_VOLUME_ID    dd  VolumeId    ; offset 39; 4 bytes
    BS_VOLUME_LABEL db  VolumeLabel ; offset 43; 11 bytes
    times 11 - ($ - BS_VOLUME_LABEL) db 0x00
    BS_FS_TYPE      db  FsType      ; offset 54; 8 bytes
    times 8 - ($ - BS_FS_TYPE) db 0x00

_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

    ; clear screen
    mov ax, 0x0600   ; ah 06: scroll screen up; al=00: lines to scroll, 0 means clear screen
    mov bx, 0x0700   ; bh: set background color and forground color
    mov cx, 0x0000   ; ch = upper row number, cl = left column number
    mov dx, 0x184f   ; dh = lower row number, dl = right column number; screen = 80 cols x 25 rows
    int 0x10

    ; set cursor position
    mov ah, 0x02     ; ah 02, set cursor position
    mov bh, 0x00     ; page number
    mov dx, 0x0000   ; ah: row; al: column
    int 0x10

    mov cx, bootMsgMsgEnd - bootMsgMsg   ; cx = number of chars in string
    mov bp, bootMsgMsg ; ES:BP address of string
    call _printLine

    call _searchloader
    cmp ax, 0
    jz .searchError

    call _copyLoader

    mov bx, 0x000f  ; bh = page number, bl = char color
    mov ah, 0x03    ; ah 03: get cursor position
    int 0x10        ; return: dh = row, dl = column

    mov ah, 0x02     ; new line
    inc dh
    mov dl, 0x00
    int 0x10

    jmp .end

.searchError:
    mov cx, errorMsgEnd - errorMsg   ; cx = number of chars in string
    mov bp, errorMsg ; ES:BP address of string
    call _printLine
.end:
    jmp BaseOfLoader : OffsetOfLoader

;--- function copy loader
; ax: cluster number
_copyLoader:
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
    
    cld

    mov ax, BaseOfLoader
    mov es, ax

    mov cx, 256
    mov si, TmpBufferAddress
    mov di, [copiedLoaderBytes]
    add di, OffsetOfLoader
    rep movsw

    mov ax, 0
    mov es, ax

    add word [copiedLoaderBytes], 512

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

;--- function search loader
_searchloader:
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
    mov si, loaderFileName

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

    mov ah, 0x02     ; new line
    inc dh
    mov dl, 0x00
    int 0x10

    popa
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

;=== message
    errorMsg: db 'ERR:no loader...'
    errorMsgEnd:
    bootMsgMsg: db 'start boot'
    bootMsgMsgEnd:
    loaderFileName: db 'LOADER  BIN'

;=== variable
    sectorNo dw SectorNoOfRootDir
    rootDirLoopCount dw RootDirSectors
    copiedLoaderBytes dw 0

;=== fill whole sector with 0
    times 510 - ($ - $$) db 0
;=== magic num 0xaa55
    dw 0xaa55
