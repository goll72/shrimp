GHDL ?= ghdl

GHDLFLAGS ?= 
BASEGHDLFLAGS = --std=08 -fpsl $(GHDLFLAGS)

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
	$(GHDL) import --workdir=$(WORK) $(BASEGHDLFLAGS) $(SRC)
	touch $@

run: all
	$(MAKE) $(WORK)/$(TOP).o
	cd $(WORK) && $(GHDL) elab-run --workdir=. $(BASEGHDLFLAGS) $(TOP)

yosys: all $(WORK)
	$(MAKE) $(WORK)/$(TOP).o
ifneq ($(TOP),)
	yosys -m ghdl -p "ghdl --workdir=$(WORK) $(BASEGHDLFLAGS) $(TOP); $(CMD)"
else
	yosys -m ghdl -p "$(CMD)"
endif

$(WORK):
	@mkdir -p $(WORK)

$(WORK)/%.d: %.vhdl | $(STAMP)
	@mkdir -p $(dir $@)
	$(GHDL) analyze --workdir=$(WORK) $(BASEGHDLFLAGS) $<
	-@$(GHDL) gen-depends --workdir=$(WORK) $(BASEGHDLFLAGS) $(notdir $*) > $@ 2>/dev/null
	@echo '$(WORK)/$(notdir $*).o: ; $$(GHDL) analyze --workdir=$$(WORK) $$(BASEGHDLFLAGS) $$<' >> $@
	@echo 'all: $(WORK)/$(notdir $*).o' >> $@

.PHONY: yosys
