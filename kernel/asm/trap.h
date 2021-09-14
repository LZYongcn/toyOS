#ifndef __TRAP_H__

#define __TRAP_H__

extern "C" void divide_error(void);
extern "C" void debug(void);
extern "C" void nmi(void);
extern "C" void int3(void);
extern "C" void overflow(void);
extern "C" void bounds(void);
extern "C" void undefined_opcode(void);
extern "C" void dev_not_available(void);
extern "C" void double_fault(void);
extern "C" void coprocessor_segment_overrun(void);
extern "C" void invalid_TSS(void);
extern "C" void segment_not_present(void);
extern "C" void stack_segment_fault(void);
extern "C" void general_protection(void);
extern "C" void page_fault(void);
extern "C" void x87_FPU_error(void);
extern "C" void alignment_check(void);
extern "C" void machine_check(void);
extern "C" void SIMD_exception(void);
extern "C" void virtualization_exception(void);

extern "C" void sys_vector_init(void);

#endif
