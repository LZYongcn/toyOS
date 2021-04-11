SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.o,$(SRC))

all: $(OBJ) install

install:
	hdiutil attach -mountroot $(PREFIX)/media $(PREFIX)/boot.img
	cp $(TARGET_DIR)/kernel.o $(PREFIX)/media/boot/kernel.bin
ifneq ($(u),1)
	hdiutil detach $(PREFIX)/media/boot
endif

$(TARGET_DIR)/%.o : %.asm %.inc fat12.inc
	$(AS) $< -o $@

$(TARGET_DIR)/%.o : %.asm
	$(AS) $< -o $@