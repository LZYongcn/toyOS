%include "ards.inc"
%include "common.inc"
%include "fat12.inc"

OffsetOfKernel equ 0x10_0000
BaseOfKernel equ 0x0000

BaseOfStack equ 0x3000

TmpBufferAddress equ 0x3000

;=== segment descriptor 