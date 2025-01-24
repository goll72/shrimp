NVC ?= nvc

NVCFLAGS ?= 

AFLAGS ?= --check-synthesis --psl
EFLAGS ?= -j
RFLAGS ?=

OUT = $(patsubst %.vhdl,$(WORK)/%.stamp,$(SRC))
DEPS = $(WORK)/deps.d

all: $(DEPS)

run: $(DEPS)
	$(NVC) $(NVCFLAGS) -e $(EFLAGS) $(TOP)
	$(NVC) $(NVCFLAGS) -r $(RFLAGS) $(TOP)

# Make the stamp (out) files depend on the files nvc generates
$(DEPS): $(OUT) Makefile
	@$(NVC) $(NVCFLAGS) --work=$(WORK) --print-deps | awk '/.*:/ { split($$0, v, /: | /); out = v[1]; stamp = v[2]; sub(/\.vhdl/, ".stamp", stamp); print "$(WORK)/" stamp ": " out }; /.*/' > $@.tmp
	@[ -s $@.tmp ] && mv $@.tmp $@

$(WORK)/%.stamp: %.vhdl
	@mkdir -p `dirname $@`
	$(NVC) $(NVCFLAGS) --work=$(WORK) -a $(AFLAGS) $< && touch $@
