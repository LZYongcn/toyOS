OUTPUT_FORMAT("elf64-x86-64","elf64-x86-64","elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

SECTIONS
{
	. = 0xffff800000000000 + 0x100000;
	entry 0xffff800000000000 + 0x100000 :
	{
		entry;
	}
	.text :
	{
		_text = .;
		*(.text*)

		_etext = .;
	}
	. = ALIGN(8);
	.data :
	{
		_data = .;
		*(.data*)
		
		_edata = .;
	}
	.bss :
	{
		_bss = .;
		*(.bss)
		_ebss = .;
	}

	.eh_frame :
	{

	}

	_end = .;
}
