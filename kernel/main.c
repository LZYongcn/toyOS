#include "asm/gate.h"
#include "asm/trap.h"
#include "lib.h"
#include "printk.h"

void init_screen_param(void) {
  g_cursor.XResolution = 1440;
  g_cursor.YResolution = 900;

  g_cursor.XPosition = 0;
  g_cursor.YPosition = 0;

  g_cursor.XCharSize = 8;
  g_cursor.YCharSize = 16;

  g_cursor.FB_addr = (unsigned int*)0xffff800000a00000;
  g_cursor.FB_length = (g_cursor.XResolution * g_cursor.YResolution * 4);
}

void start_kernel(void) {
  init_screen_param();
  set_tss64(
    0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00,
    0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00, 0xffff800000007c00);
  sys_vector_init();
  
  color_printfk(YELLOW, BLACK, "Hello World! %d\n", 1024);
  while (1) {};
}
