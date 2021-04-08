SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.o,$(SRC))

all: $(OBJ) install

install:
	dd if=$(TARGET_DIR)/boot.o of=$(PREFIX)/boot.img count=1 bs=512 conv=notrunc
	hdiutil attach -mountroot $(PREFIX)/media $(PREFIX)/boot.img
	cp $(TARGET_DIR)/loader.o $(PREFIX)/media/boot/loader.bin
ifneq ($(u),1)
	hdiutil detach $(PREFIX)/media/boot
endif

$(TARGET_DIR)/%.o : %.asm %.inc
	$(AS) $< -o $@

$(TARGET_DIR)/%.o : %.asm
	$(AS) $< -o $@