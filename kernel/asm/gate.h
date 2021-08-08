#ifndef __GATE_H__
#define __GATE_H__

typedef struct
{
  unsigned char x[8];
} desc_struct;

typedef struct
{
  unsigned char x[16];
} gate_struct;

extern desc_struct GDT_Table[];
extern gate_struct IDT_Table[];
extern unsigned long TSS64_Table[26];

#define _set_gate(gate_selector_addr, attr, ist, code_addr)                                                  \
  do {                                                                                                       \
    unsigned long __d0, __d1;                                                                                \
    __asm__ __volatile__(                                                                                    \
      "movw %%dx, %%ax \n\t"                                                                                 \
      "shr $16, %%rdx \n\t"                                                                                  \
      "movw %%dx, %%cx \n\t"                                                                                 \
      "shlq $16, %%rcx \n\t"                                                                                 \
      "orq %3, %%rcx \n\t"                                                                                   \
      "orq %2, %%rcx \n\t"                                                                                   \
      "shlq $32, %%rcx \n\t"                                                                                 \
      "orq %%rcx, %%rax \n\t"                                                                                \
      "shrq $16, %%rdx \n\t"                                                                                 \
      "movq %%rax, %0 \n\t"                                                                                  \
      "movq %%rdx, %1 \n\t"                                                                                  \
      : "=m"(*((unsigned long*)gate_selector_addr)), "=m"(*((unsigned long*)(gate_selector_addr + 1)))       \
      : "r"((long)ist), "i"(attr << 8), "d"((unsigned long*)(code_addr)), "a"(0x08 << 16) \
      :"cx");                                                                                           \
  } while (0)

#define load_TR(n)                                                                                           \
  do {                                                                                                       \
    __asm__ __volatile__("ltr	ax" : : "a"(n << 3) : "memory");                                             \
  } while (0)

static inline void set_intr_gate(unsigned int n, unsigned char ist, void* addr) {
  _set_gate(IDT_Table + 2 * n, 0x8E, ist, addr); // P,DPL=0,TYPE=E
}

static inline void set_trap_gate(unsigned int n, unsigned char ist, void* addr) {
  _set_gate(IDT_Table + 2 * n, 0x8F, ist, addr); // P,DPL=0,TYPE=F
}

static inline void set_system_gate(unsigned int n, unsigned char ist, void* addr) {
  _set_gate(IDT_Table + 2 * n, 0xEF, ist, addr); // P,DPL=3,TYPE=F
}

static inline void set_system_intr_gate(unsigned int n, unsigned char ist, void* addr) // int3
{
  _set_gate(IDT_Table + 2 * n, 0xEE, ist, addr); // P,DPL=3,TYPE=E
}

static inline void set_tss64(
  unsigned long rsp0,
  unsigned long rsp1,
  unsigned long rsp2,
  unsigned long ist1,
  unsigned long ist2,
  unsigned long ist3,
  unsigned long ist4,
  unsigned long ist5,
  unsigned long ist6,
  unsigned long ist7) {
  *(unsigned long*)(TSS64_Table + 1) = rsp0;
  *(unsigned long*)(TSS64_Table + 3) = rsp1;
  *(unsigned long*)(TSS64_Table + 5) = rsp2;

  *(unsigned long*)(TSS64_Table + 9) = ist1;
  *(unsigned long*)(TSS64_Table + 11) = ist2;
  *(unsigned long*)(TSS64_Table + 13) = ist3;
  *(unsigned long*)(TSS64_Table + 15) = ist4;
  *(unsigned long*)(TSS64_Table + 17) = ist5;
  *(unsigned long*)(TSS64_Table + 19) = ist6;
  *(unsigned long*)(TSS64_Table + 21) = ist7;
}

#endif
