%include "fat12.inc"
%include "ards.inc"

OffsetOfKernel equ 0x10_0000
BaseOfKernel equ 0x0000

BaseOfStack equ 0x8000

TmpBufferAddress equ 0x8000

;=== segment descriptor 