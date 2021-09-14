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

#define mms memory_management_struct

unsigned long page_init(struct Page* page, unsigned long flags) {
  if (!page->attribute) {
    *(mms.bits_map + ((page->PHY_address >> PAGE_2M_SHIFT) >> 6)) |=
      1UL << (page->PHY_address >> PAGE_2M_SHIFT) % 64;
    page->attribute = flags;
    page->reference_count++;
    page->zone_struct->page_using_count++;
    page->zone_struct->page_free_count--;
    page->zone_struct->total_pages_link++;
  } else if (
    (page->attribute & PG_Referenced) || (page->attribute & PG_K_Share_To_U) || (flags & PG_Referenced) ||
    (flags & PG_K_Share_To_U)) {
    page->attribute |= flags;
    page->reference_count++;
    page->zone_struct->total_pages_link++;
  } else {
    *(mms.bits_map + ((page->PHY_address >> PAGE_2M_SHIFT) >> 6)) |=
      1UL << (page->PHY_address >> PAGE_2M_SHIFT) % 64;
    page->attribute |= flags;
  }
  return 0;
}

extern "C" void init_memory(void) {
  unsigned long totoal_mem = 0;
  unsigned long pages_2m = 0;
  unsigned short num_of_ards = *((unsigned short*)0xffff800000007e00);
  struct E820* p = NULL;

  color_printfk(
    YELLOW, BLACK,
    "Display Physics Address MAP,Type(1:RAM,2:ROM or Reserved,3:ACPI Reclaim Memory,4:ACPI NVS "
    "Memory,Others:Undefine)\n");

  printf("ards count: %d\n", num_of_ards);
  p = (struct E820*)0xffff800000007e04;

  mms.start_code = (unsigned long)(&_text);
  mms.end_code = (unsigned long)(&_etext);
  mms.end_data = (unsigned long)(&_edata);
  mms.end_brk = (unsigned long)(&_end);

  totoal_mem = (p + num_of_ards - 1)->address + (p + num_of_ards - 1)->length;

  // init bit map
  mms.bits_map = (unsigned long*)PAGE_4K_ALIGN(mms.end_brk);
  mms.bits_count = totoal_mem >> PAGE_2M_SHIFT;
  mms.bits_length = (((mms.bits_count + 7) >> 3) + 7) >> 3 << 3;

  color_printfk(YELLOW, BLACK, "count %lu length %lu total_mem %lu\n", mms.bits_count, mms.bits_length, totoal_mem / (1024 * 1024));

  memset(mms.bits_map, 0xff, mms.bits_length);

  // init page struct
  mms.pages_struct = (struct Page*)PAGE_4K_ALIGN((unsigned long)(mms.bits_map + mms.bits_length));
  mms.pages_count = mms.bits_count;
  mms.pages_length = (sizeof(struct Page) * mms.pages_count);

  memset(mms.pages_struct, 0x00, mms.pages_length);

  // init zone struct
  mms.zones_struct = (struct Zone*)PAGE_4K_ALIGN((unsigned long)(mms.pages_struct + mms.pages_length));
  mms.zones_count = 0;
  mms.zones_length = 0;

  totoal_mem = 0;
  unsigned long start, end;

  color_printfk(
    ORANGE, BLACK, "Page_struct:%#018lx\tZone_struct:%#018lx size p:%d size z:%d\n", mms.pages_struct,
    mms.zones_struct, sizeof(struct Page), sizeof(struct Zone));

  for (int i = 0; i < num_of_ards && i < MAX_E820S; i++) {
    color_printfk(
      ORANGE, BLACK, "Address:%#018lx\tLength:%#018lx\tType:%#010x\n", p->address, p->length, p->type);

    mms.e820[i] = *p;
    mms.e820_count = i + 1;

    if (p->type == 1) {
      totoal_mem += p->length;

      start = PAGE_2M_ALIGN(p->address);
      end = PAGE_2M_MASK(p->address + p->length);

      if (start < end) {
        int pages = (end - start) >> PAGE_2M_SHIFT;
        pages_2m += pages;

        struct Zone* zptr = mms.zones_struct + mms.zones_count;
        mms.zones_count++;
        mms.zones_length += sizeof(struct Zone);
        memset(zptr, 0x00, sizeof(struct Zone));

        zptr->zone_start_address = start;
        zptr->zone_end_address = end;
        zptr->zone_length = end - start;

        zptr->page_using_count = 0;
        zptr->page_free_count = pages;

        zptr->total_pages_link = 0;
        zptr->attribute = 0;
        zptr->GMD_struct = &mms;
        zptr->pages_count = pages;
        zptr->pages_group = (struct Page*)(mms.pages_struct + (start >> PAGE_2M_SHIFT));

        struct Page* pptr = zptr->pages_group;

        for (int j = 0; j < zptr->pages_count; j++, pptr++) {
          pptr->zone_struct = zptr;
          pptr->PHY_address = start + PAGE_2M_SIZE * j;
          pptr->reference_count = 0;
          pptr->age = 0;
          pptr->attribute = 0;
          int idx = pptr->PHY_address >> PAGE_2M_SHIFT;
          *(mms.bits_map + (idx >> 6)) ^= 1UL << (idx % 64);
        }
      }
    }

    p++;
  }

  mms.pages_struct->zone_struct = mms.zones_struct;
  mms.pages_struct->PHY_address = 0UL;
  mms.pages_struct->attribute = 0;
  mms.pages_struct->reference_count = 0;
  mms.pages_struct->age = 0;

  color_printfk(ORANGE, BLACK, "OS Can Used Total RAM:%dM\n", totoal_mem / (1024 * 1024));
  color_printfk(ORANGE, BLACK, "OS Can Used Total 2M PAGEs:%d\n", pages_2m);

  color_printfk(
    ORANGE, BLACK, "bits_map:%#018lx,bits_count:%lu,bits_length:%#018lx\n", mms.bits_map, mms.bits_count,
    mms.bits_length);

  color_printfk(
    ORANGE, BLACK, "pages_struct:%#018lx,pages_count:%lu,pages_length:%#018lx\n", mms.pages_struct,
    mms.pages_count, mms.pages_length);

  color_printfk(
    ORANGE, BLACK, "zones_struct:%#018lx,zones_count:%lu,zones_length:%#018lx\n", mms.zones_struct,
    mms.zones_count, mms.zones_length);

  for (int i = 0; i < mms.zones_count; i++) {
    struct Zone* z = mms.zones_struct + i;
    color_printfk(
      ORANGE, BLACK,
      "zone_start_address:%#018lx,zone_end_address:%#018lx,zone_length:%#018lx,pages_group:%#018lx,pages_"
      "length:%#018lx\n",
      z->zone_start_address, z->zone_end_address, z->zone_length, z->pages_group, z->pages_count);
  }

  mms.end_of_struct = PAGE_4K_ALIGN((unsigned long)(mms.zones_struct + mms.zones_length));

  int kernel_page = Virt_To_Phy(mms.end_of_struct) >> PAGE_2M_SHIFT;
  for (int j = 0; j < kernel_page; j++) {
    page_init(mms.pages_struct + j, PG_PTable_Maped | PG_Kernel_Init | PG_Active | PG_Kernel);
  }

  Global_CR3 = Get_pgd();

  color_printfk(
    ORANGE, BLACK,
    "start_code:%#018lx,end_code:%#018lx,end_data:%#018lx,end_brk:%#018lx,end_of_struct:%#018lx\n",
    mms.start_code, mms.end_code, mms.end_data, mms.end_brk, mms.end_of_struct);
  
  unsigned long dest_cr3 = *((unsigned long *)(Phy_To_Virt((unsigned long)Global_CR3) & (~0xfff)));
  color_printfk(INDIGO, BLACK, "Global_CR3\t:%#018lx\n", Global_CR3);
  color_printfk(INDIGO, BLACK, "*Global_CR3\t:%#018lx\n", dest_cr3);
  color_printfk(INDIGO, BLACK, "**Global_CR3\t:%#018lx\n", *((unsigned long *)(Phy_To_Virt(dest_cr3) & (~0xfff))));

  flush_tlb_all();
}

#undef mms
