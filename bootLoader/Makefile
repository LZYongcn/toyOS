SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.bin,$(SRC))

all: $(OBJ) install

install:
	dd if=$(TARGET_DIR)/boot.bin of=$(PREFIX)/boot.img count=1 bs=512 conv=notrunc
	hdiutil attach -mountroot $(PREFIX)/media $(PREFIX)/boot.img
	cp $(TARGET_DIR)/loader.bin $(PREFIX)/media/boot/loader.bin

$(TARGET_DIR)/%.bin : %.asm %.inc fat12.inc common.inc
	$(AS) $< -o $@

$(TARGET_DIR)/%.bin : %.asm
	$(AS) $< -o $@
