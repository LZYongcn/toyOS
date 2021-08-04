SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.o,$(SRC))

all: $(OBJ) install

install:
	$(Q)dd if=$(TARGET_DIR)/boot.o of=$(PREFIX)/boot.img count=1 bs=512 conv=notrunc
	$(Q)hdiutil attach -mountroot $(PREFIX)/media $(PREFIX)/boot.img
	$(Q)cp $(TARGET_DIR)/loader.o $(PREFIX)/media/boot/loader.bin

$(TARGET_DIR)/%.o : %.asm %.inc fat12.inc common.inc
	$(Q)$(AS) $< -o $@

$(TARGET_DIR)/%.o : %.asm
	$(Q)$(AS) $< -o $@
