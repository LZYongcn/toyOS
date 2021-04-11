ifneq ($(sub_make), 1)
export Q:=@
ifeq ($(origin v),command line)
$(info verbose info)
Q:=
endif
export BUILD_DIR := $(abspath build)
$(shell mkdir -p $(BUILD_DIR))
export ROOT_MAKE := $(abspath $(lastword $(MAKEFILE_LIST)))
export ROOT_DIR := $(dir $(ROOT_MAKE))
export PREFIX := $(abspath $(ROOT_DIR)/..)
ROOT_DIR := $(patsubst %/,%,$(ROOT_DIR))
$(shell cd $(ROOT_DIR))
INSTALL_PATH := "../boot.img"
export AS := nasm
endif

CUR_DIR := $(shell pwd)
CUR_DIR := $(patsubst %/,%,$(CUR_DIR))

TARGET_DIR := $(BUILD_DIR)$(subst $(ROOT_DIR),,$(CUR_DIR))
TARGET_DIR := $(patsubst %/,%,$(TARGET_DIR))

BUILT_IN_OBJ := 
OBJ := $(wildcard $(TARGET_DIR)/*.o)
SUB_DIRS := $(shell find . -maxdepth 1 -type d)
SUB_DIRS := $(filter-out ./ . ../, $(SUB_DIRS))
SUB_DIRS := $(foreach subdir, $(SUB_DIRS), $(dir $(firstword $(wildcard $(subdir)/makefile $(subdir)/Makefile))))
SUB_DIRS := $(patsubst ./%,%,$(SUB_DIRS))
SUB_DIRS := $(patsubst %/,%,$(SUB_DIRS))

BUILT_IN_NAME := built_in.a
BUILT_IN_TARGET := $(TARGET_DIR)/$(BUILT_IN_NAME)

BUILT_IN_OBJ += $(foreach dir,$(SUB_DIRS),$(TARGET_DIR)/$(dir)/$(BUILT_IN_NAME))

.PHONY: all, install, clean, __FORCE

ifneq ($(sub_make), 1)
all: __all install
else
all: __all
endif

export sub_make := 1

__all: $(BUILT_IN_TARGET)
__FORCE:

$(SUB_DIRS): __FORCE
	$(Q)mkdir -p $(TARGET_DIR)/$@
	$(Q)$(MAKE) -C $@ TARGET_DIR=$(TARGET_DIR)/$@
	$(Q)$(MAKE) -C $@ -f $(ROOT_MAKE)

$(BUILT_IN_OBJ): $(SUB_DIRS)

$(BUILT_IN_TARGET): $(BUILT_IN_OBJ) $(OBJ)

install:
ifneq ($(u), 1)
	bash -ic 'cdbox;bochs'
endif
	$(Q):

clean:
	$(Q)rm -rf $(BUILD_DIR)