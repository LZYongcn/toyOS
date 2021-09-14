#include "memory.h"

#include "../lib.h"
#include "../printk.h"

extern char _text;
extern char _etext;
extern char _data;
extern char _edata;
extern char _rodata;
extern char _erodata;
extern char _bss;
extern char _ebss;
extern char _end;

extern "C" void init_memory(void) {
  int i;
  unsigned long totoal_mem = 0;
  unsigned long pages_2m = 0;
  unsigned short num_of_ards = *((unsigned short*)0xffff800000007e00);
  struct E820* p = NULL;
  
  color_printk(
    YELLOW, BLACK,
    "Display Physics Address MAP,Type(1:RAM,2:ROM or Reserved,3:ACPI Reclaim Memory,4:ACPI NVS "
    "Memory,Others:Undefine)\n");

  printf("ards count: %d\n", num_of_ards);
  p = (struct E820*)0xffff800000007e04;
  
#define mms memory_management_struct
  
  mms.start_code = (unsigned long)(&_text);
  mms.end_code = (unsigned long)(&_etext);
  mms.end_data = (unsigned long)(&_edata);
  mms.end_brk = (unsigned long)(&_end);
  
  unsigned long start, end;
  for (i = 0; i < num_of_ards; i++) {
    color_printfk(
      ORANGE, BLACK, "Address:%#018lx\tLength:%#018lx\tType:%#010x\n", p->address, p->length, p->type);

    if (p->type == 1) {
      totoal_mem += p->length;
      
      start = PAGE_2M_ALIGN(p->address);
      end = PAGE_2M_MASK(p->address + p->length);
      
      if (start < end) {
        pages_2m += (end - start) >> PAGE_2M_SHIFT;
      }
    }

    p++;
  }
  color_printfk(ORANGE, BLACK, "Kernel start: %#018lx end: %#018lx\n", mms.start_code, mms.end_brk);
  color_printfk(ORANGE, BLACK, "OS Can Used Total RAM:%dM\n", totoal_mem / (1024 * 1024));
  color_printfk(ORANGE, BLACK, "OS Can Used Total 2M PAGEs:%d\n", pages_2m);
  
#undef mms
}
