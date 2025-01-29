SRC = rtl/attrs.vhdl              \
      rtl/opcode.vhdl             \
      rtl/reg.vhdl                \
      rtl/reg_file.vhdl           \
      rtl/alu/barrel_shifter.vhdl \
      rtl/alu/adder.vhdl          \
      rtl/alu.vhdl                \
      rtl/cpu.vhdl                \
      rtl/memory.vhdl

WORK ?= work

include $(ENV).mk

clean:
	rm -rf $(WORK)

ifneq ($(wildcard $(DEPS)),)
include $(DEPS)
endif

.PHONY: all run clean
