extern start_kernel
extern color_printk

%define ADVANCE_TO(X) times X - ($ - $$) db 0

BaseOfStack equ 0x7E00
BaseOfStack64 equ 0xffff_8000_0000_7E00
[BITS 64]
[section entry]
global _start
_start:
    mov ax, SelectorKernelData64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov esp, BaseOfStack
    
    lgdt [rel GDT_POINTER]
    lidt [rel IDT_POINTER]

    mov ax, SelectorKernelData64
    mov es, ax
    mov ss, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax
    mov rsp, BaseOfStack

    ; load cr3 (page table)
    mov rax, 0x10_1000
    mov cr3, rax

    mov rax, [rel _address64]
    push SelectorKernelCode64
    push rax
    ret

_address64:
    dq _goto64

_goto64:
    mov rax, SelectorKernelData64
    mov ds, rax
    mov es, rax
    mov gs, rax
    mov ss, rax
    mov rsp, BaseOfStack64

_setup_idt:
    lea rdx, [rel _unknown_int]
    mov rax, SelectorKernelCode64 << 16
    mov ax, dx
    shr rdx, 16
    mov cx, dx
    shl rcx, 16
    or  rcx, 0x8e00
    shl rcx, 32
    or  rax, rcx
    shr rdx, 16
    lea rdi, [rel IDT_Table]
    mov rcx, 256
.repeat:
    mov [rdi], rax
    mov [rdi + 8], rdx
    add rdi, 0x10
    dec rcx
    jne .repeat

    mov rax, [rel _address_kernel]
    push SelectorKernelCode64
    push rax
    ret

_setup_tss64:
    lea rdx, [rel TSS64_Table]
    xor rax, rax
    xor rcx, rcx
    mov rax, 0x89
    shl rax, 40
    mov ecx, edx

    shr ecx, 24
    shl rcx, 56
    add rax, rcx
    xor rcx, rcx
    mov edx, ecx

    and ecx, 0x00ffffff
    shl rcx, 16
    add rax, rcx
    add rax, 103
    lea rdi, [rel GDT_Table]

    mov [rdi + 64], rax
    shr rdx, 32
    mov [rdi + 72], rdx

    mov ax, 0x40
    ltr ax


_address_kernel:
    dq start_kernel

;--- default int handler
global _unknown_int
_unknown_int:
    cld
    push rax
    push rbx
    push rcx
    push rdx
    push rbp
    push rdi
    push rsi

    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    mov rcx, color_printk
    mov rdx, unknownIntMsg
    xor rax, rax
    mov rdi, 0x000000
    mov rsi, 0xff0000
    call rcx

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8

    pop rsi
    pop rdi
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    pop rax

    jmp $
    iret


unknownIntMsg: db 'Unknown interrupt or fault at RIP',`\n`, 0x00


ADVANCE_TO(0x1000)
;--- page table
__PML4E:
    dq 0x10_2007
    times 255 dq 0
    dq 0x10_2007
    times 255 dq 0

ADVANCE_TO(0x2000)
__PDPTE:
    dq 0x10_3003
    times 511 dq 0

ADVANCE_TO(0x3000)
__PDE:
	dq 0x0000_0083	
	dq 0x0020_0083
	dq 0x0040_0083
	dq 0x0060_0083
	dq 0x0080_0083
	dq 0xe000_0083		;0x a00000
	dq 0xe020_0083
	dq 0xe040_0083
	dq 0xe060_0083		;0x1000000
	dq 0xe080_0083
	dq 0xe0a0_0083
	dq 0xe0c0_0083
	dq 0xe0e0_0083
	times 499 dq 0

[section .data align=8]
;--- GDT_Table
global GDT_Table
GDT_Table:
GDT64_DESC_KERNEL_EMPTY64:   dq 0x0000_0000_0000_0000          ;0 NULL descriptor             00
GDT64_DESC_KERNEL_CODE64:    dq 0x0020_9800_0000_0000          ;1 KERNEL  Code    64-bit  Segment 08
GDT64_DESC_KERNEL_DATA64:    dq 0x0000_9200_0000_0000          ;2 KERNEL  Data    64-bit  Segment 10
GDT64_DESC_USER_DATA64:      dq 0x0020_f800_0000_0000          ;3 USER    Code    64-bit  Segment 18
GDT64_DESC_USER_CODE64:      dq 0x0000_f200_0000_0000          ;4 USER    Data    64-bit  Segment 20
GDT64_DESC_KERNEL_CODE32:    dq 0x00cf_9a00_0000_ffff          ;5 KERNEL  Code    32-bit  Segment 28
GDT64_DESC_KERNEL_DATA32:    dq 0x00cf_9200_0000_ffff          ;6 KERNEL  Data    32-bit  Segment 30
    times 10 dq 0                  ;8 ~ 9 TSS (jmp one segment <7>) in long-mode 128-bit 40
GDT_END:

SelectorKernelCode64 equ GDT64_DESC_KERNEL_CODE64 - GDT64_DESC_KERNEL_EMPTY64
SelectorKernelData64 equ GDT64_DESC_KERNEL_DATA64 - GDT64_DESC_KERNEL_EMPTY64

GDT_POINTER:
GDT_LIMIT:  dw  GDT_END - GDT_Table - 1
GDT_ADDR:   dq  GDT_Table  

;--- IDT_Table
global IDT_Table
IDT_Table: 
    times 512 dq 0
IDT_END:

IDT_POINTER:
IDT_LIMIT:  dw  IDT_END - IDT_Table
IDT_ADDR:   dq  IDT_Table

;--- TSS64_Table
global	TSS64_Table
TSS64_Table:
	times 13 dq 0
TSS64_END:

TSS64_POINTER:
TSS64_LIMIT:    dw	TSS64_END - TSS64_Table - 1
TSS64_BASE:     dq	TSS64_Table

