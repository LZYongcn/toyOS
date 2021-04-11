%include "fat12.inc"
%include "ards.inc"

OffsetOfKernel equ 0x10_0000
BaseOfKernel equ 0x0000

TmpBufferAddress equ 0x8000

abc equ 0000_0001b
bbc equ abc | 0000_0000b