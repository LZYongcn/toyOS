SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,$(TARGET_DIR)/%.o,$(SRC))
CSRC := $(wildcard *.c)
COBJ := $(patsubst %.c,$(TARGET_DIR)/%.o,$(CSRC))

ASFLAG += -f elf64

all: $(OBJ) $(COBJ)

$(TARGET_DIR)/%.o : %.c
	$(Q)$(CC) $(CFLAG) $< -o $@

$(TARGET_DIR)/%.o : %.asm
	$(Q)$(AS) $(ASFLAG) $< -o $@
