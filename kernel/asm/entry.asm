FUNC  equ  0x88
ERRCODE  equ  0x90
OLDRSP  equ  0xb0
OLDSS  equ  0xb8

%macro ENTRY 1
global %1
%1:
%endmacro


extern handle_divide_error
extern handle_debug
extern handle_nmi
extern handle_int3
extern handle_overflow
extern handle_bounds
extern handle_undefined_opcode
extern handle_dev_not_available
extern handle_double_fault
extern handle_coprocessor_segment_overrun
extern handle_invalid_TSS
extern handle_segment_not_present
extern handle_stack_segment_fault
extern handle_general_protection
extern handle_page_fault
extern handle_x87_FPU_error
extern handle_alignment_check
extern handle_machine_check
extern handle_SIMD_exception
extern handle_virtualization_exception


RESTORE_ALL:
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rbp
	pop rax
	mov ds, rax;
	pop rax
	mov es, rax;
	pop rax
	add rsp, 0x10
	iretq;

%macro GET_CURRENT 1
	mov	%1, -32768
	and	%1, rsp
%endmacro

ret_from_exception:
ENTRY ret_from_intr
	jmp	RESTORE_ALL	
	
ENTRY divide_error
	push 0
	push rax
	lea rax, [rel handle_divide_error]
	xchg [rsp], rax

error_code:
	push rax
	mov rax, es
	push rax
	mov rax, ds
	push rax
	xor rax, rax

	push rbp
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	
	cld
	mov rsi, [rsp + ERRCODE]
	mov rdx, [rsp + FUNC]

	mov rdi, 0x10
	mov ds, rdi
	mov es, rdi

	mov rdi, rsp
	;GET_CURRENT(ebx)

	call rdx

	jmp	ret_from_exception	

ENTRY debug
	push 0
	push rax
	lea rax, [rel handle_debug]
	xchg [rsp], rax
	jmp	error_code

ENTRY nmi
	push rax
	cld;			
	push rax;
	
	push rax
	mov rax, es
	push rax
	mov rax, ds
	push rax
	xor rax, rax
	
	push rbp;
	push rdi;
	push rsi;
	push rdx;
	push rcx;
	push rbx;
	push r8;
	push r9;
	push r10;
	push r11;
	push r12;
	push r13;
	push r14;
	push r15;
	
	mov rdx, 0x10;
	mov ds, rdx;
	mov es, rdx;
	
	mov rsi, 0
	mov rdi, rsp

	call handle_nmi

	jmp	RESTORE_ALL

ENTRY int3
	push 0
	push rax
	lea rax, [rel handle_int3]
	xchg [rsp], rax
	jmp	error_code

ENTRY overflow
	push 0
	push rax
	lea rax, [rel handle_overflow]
	xchg [rsp], rax
	jmp	error_code

ENTRY bounds
	push 0
	push rax
	lea rax, [rel handle_bounds]
	xchg [rsp], rax
	jmp	error_code

ENTRY undefined_opcode
	push 0
	push rax
	lea rax, [rel handle_undefined_opcode]
	xchg [rsp], rax
	jmp	error_code

ENTRY dev_not_available	
	push 0
	push rax
	lea rax, [rel handle_dev_not_available]
	xchg [rsp], rax
	jmp	error_code


ENTRY double_fault
	push rax
	lea rax, [rel handle_double_fault]
	xchg [rsp], rax
	jmp	error_code

ENTRY coprocessor_segment_overrun
	push 0
	push rax
	lea rax, [rel handle_coprocessor_segment_overrun]
	xchg [rsp], rax
	jmp	error_code

ENTRY invalid_TSS
	push rax
	lea rax, [rel handle_invalid_TSS]
	xchg [rsp], rax
	jmp	error_code

ENTRY segment_not_present
	push rax
	lea rax, [rel handle_segment_not_present]
	xchg [rsp], rax
	jmp	error_code

ENTRY stack_segment_fault
	push rax
	lea rax, [rel handle_stack_segment_fault]
	xchg [rsp], rax
	jmp	error_code

ENTRY general_protection
	push rax
	lea rax, [rel handle_general_protection]
	xchg [rsp], rax
	jmp	error_code

ENTRY page_fault
	push rax
	lea rax, [rel handle_page_fault]
	xchg [rsp], rax
	jmp	error_code

ENTRY x87_FPU_error
	push 0
	push rax
	lea rax, [rel handle_x87_FPU_error]
	xchg [rsp], rax
	jmp	error_code

ENTRY alignment_check
	push rax
	lea rax, [rel handle_alignment_check]
	xchg [rsp], rax
	jmp	error_code

ENTRY machine_check
	push 0
	push rax
	lea rax, [rel handle_machine_check]
	xchg [rsp], rax
	jmp	error_code

ENTRY SIMD_exception
	push 0
	push rax
	lea rax, [rel handle_SIMD_exception]
	xchg [rsp], rax
	jmp	error_code

ENTRY virtualization_exception
	push 0
	push rax
	lea rax, [rel handle_virtualization_exception]
	xchg [rsp], rax
	jmp	error_code


