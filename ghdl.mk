GHDL ?= ghdl

GHDLFLAGS ?= 
BASEGHDLFLAGS = --std=08 -fpsl --workdir=$(WORK) $(GHDLFLAGS)

DEPS = $(patsubst %.vhdl,$(WORK)/%.d,$(SRC))
STAMP = $(WORK)/ghdl.done

ifneq ($(wildcard $(WORK)/*.done),)
ifeq ($(wildcard $(STAMP)),)
$(error Wrong work directory)
endif
endif

ifeq ($(wildcard $(DEPS)),)
all: $(DEPS)
else
all:
endif

$(STAMP): | $(WORK)
	$(GHDL) import $(BASEGHDLFLAGS) $(SRC)
	touch $@

run: all $(WORK)/$(TOP).o
	$(GHDL) elab-run $(BASEGHDLFLAGS) $(TOP)

yosys: $(WORK) $(OUT)
	@if ! [ -z $(TOP) ]; then \
		yosys -m ghdl -p "ghdl $(BASEGHDLFLAGS) $(TOP); $(CMD)"; \
	else \
		yosys -m ghdl -p "$(CMD)"; \
	fi

$(WORK):
	@mkdir -p $(WORK)

$(WORK)/%.d: %.vhdl | $(STAMP)
	@mkdir -p $(dir $@)
	$(GHDL) analyze $(BASEGHDLFLAGS) $<
	-@$(GHDL) gen-depends $(BASEGHDLFLAGS) $(notdir $*) > $@ 2>/dev/null
	@echo '$(WORK)/$(notdir $*).o: ; $$(GHDL) analyze $$(BASEGHDLFLAGS) $$<' >> $@
	@echo 'all: $(WORK)/$(notdir $*).o' >> $@

.PHONY: yosys
