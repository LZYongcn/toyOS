#include "lib.h"
#include "printk.h"

void init_screen_param() {
  g_cursor.XResolution = 1440;
  g_cursor.YResolution = 900;

  g_cursor.XPosition = 0;
  g_cursor.YPosition = 0;

  g_cursor.XCharSize = 8;
  g_cursor.YCharSize = 16;

  g_cursor.FB_addr = (unsigned int*)0xffff800000a00000;
  g_cursor.FB_length = (g_cursor.XResolution * g_cursor.YResolution * 4);
}

void start_kernel() {
  init_screen_param();
  color_printk(YELLOW, BLACK, "Hello World!", 1024);
  while (1) {};
}
