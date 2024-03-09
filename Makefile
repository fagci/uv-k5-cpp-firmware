SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin

TARGET = $(BIN_DIR)/firmware

SRC = $(wildcard $(SRC_DIR)/driver/*.cpp)
SRC += $(wildcard $(SRC_DIR)/*.cpp)

OBJS = $(OBJ_DIR)/printf.o
OBJS += $(OBJ_DIR)/init.o
OBJS += $(OBJ_DIR)/main.o
OBJS += $(OBJ_DIR)/start.o
OBJS += $(SRC:$(SRC_DIR)/%.cpp=$(OBJ_DIR)/%.o)

# BSP_DEFINITIONS := $(wildcard hardware/*/*.def)
# BSP_HEADERS := $(patsubst hardware/%,inc/%,$(BSP_DEFINITIONS))
# BSP_HEADERS := $(patsubst %.def,%.h,$(BSP_HEADERS))

AS = arm-none-eabi-g++
CC = arm-none-eabi-g++
LD = arm-none-eabi-g++
OBJCOPY = arm-none-eabi-objcopy
SIZE = arm-none-eabi-size

GIT_HASH := $(shell git rev-parse --short HEAD)

ASFLAGS = -c -mcpu=cortex-m0
CFLAGS = -Os -Wall -Wno-error -mcpu=cortex-m0 -fno-builtin -fshort-enums -fno-delete-null-pointer-checks -std=c++17 -MMD -flto=auto -Wextra


CFLAGS += -DPRINTF_USER_DEFINED_PUTCHAR
# CFLAGS += -DPRINTF_INCLUDE_CONFIG_H
CFLAGS += -DGIT_HASH=\"$(GIT_HASH)\"
LDFLAGS = -mcpu=cortex-m0 -nostartfiles -Wl,-T,firmware.ld

INC =
INC += -I ./src
# INC += -I ./src/external/CMSIS_5/CMSIS/Core/Include/
# INC += -I ./src/external/CMSIS_5/Device/ARM/ARMCM0/Include

DEPS = $(OBJS:.o=.d)

.PHONY: all clean

all: $(TARGET)
	$(OBJCOPY) -O binary $< $<.bin
	-python fw-pack.py $<.bin $(GIT_HASH) $<.packed.bin
	-python3 fw-pack.py $<.bin $(GIT_HASH) $<.packed.bin
	$(SIZE) $<

version.o: .FORCE

$(TARGET): $(OBJS) | $(BIN_DIR)
	$(LD) $(LDFLAGS) $^ -o $@

inc/dp32g030/%.h: hardware/dp32g030/%.def

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BSP_HEADERS) $(OBJ_DIR)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(INC) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S | $(OBJ_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

.FORCE:

-include $(DEPS)

clean:
	rm -f $(TARGET).bin $(TARGET).packed.bin $(TARGET) $(OBJS) $(DEPS)
