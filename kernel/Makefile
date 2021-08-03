SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.o,$(SRC))
CSRC := $(wildcard *.c)
COBJ := $(patsubst %.c,$(TARGET_DIR)/%.co,$(CSRC))

ASFLAG := -f elf64
LDFLAG := -b elf -T kernel.lds

all: system install

system: $(OBJ) $(COBJ)
	$(LD) $(LDFLAG) -o $(TARGET_DIR)/system $^

install:
	hdiutil attach -mountroot $(PREFIX)/media $(PREFIX)/boot.img
	llvm-objcopy -S -R ".eh_frame" -R ".comment" -O binary $(TARGET_DIR)/system $(TARGET_DIR)/kernel.bin
	cp $(TARGET_DIR)/kernel.bin $(PREFIX)/media/boot/kernel.bin
ifneq ($(u),1)
	hdiutil detach $(PREFIX)/media/boot
endif

$(TARGET_DIR)/%.co : %.c
	$(CC) $(CFLAG) $< -o $@

# $(TARGET_DIR)/%.o : %.asm %.inc fat12.inc
# 	$(AS) -f macho64 $(ASFLAG) $< -o $@

$(TARGET_DIR)/%.o : %.asm
	$(AS) $(ASFLAG) $< -o $@