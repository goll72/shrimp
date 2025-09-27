SRC = rtl/attrs.vhdl              \
      rtl/opcode.vhdl             \
      rtl/reg.vhdl                \
      rtl/flags.vhdl              \
      rtl/reg_file.vhdl           \
      rtl/alu/barrel_shifter.vhdl \
      rtl/alu/adder.vhdl          \
      rtl/alu/subtractor.vhdl     \
      rtl/alu/magnitude.vhdl      \
      rtl/alu/multiplier.vhdl     \
      rtl/alu/divider.vhdl        \
      rtl/alu.vhdl                \
      rtl/irc.vhdl                \
      rtl/control.vhdl            \
      rtl/memory.vhdl             \
      rtl/memioc.vhdl             \
      rtl/cpu.vhdl

WORK ?= work

include $(ENV).mk

clean:
	rm -rf $(WORK)

ifneq ($(wildcard $(DEPS)),)
include $(DEPS)
endif

.PHONY: all run clean
