NVC ?= nvc

NVCFLAGS ?= 

AFLAGS ?= --check-synthesis --psl
EFLAGS ?= -j
RFLAGS ?=

DEPS = $(WORK)/deps.d
STAMP = $(WORK)/done

all: $(DEPS)

$(STAMP): Makefile
	for i in $(SRC); do $(NVC) $(NVCFLAGS) --work=$(WORK) -a $(AFLAGS) $$i; done
	touch $@

# We need to run make recursively since the current run of make might be generating the depfile
# with the info we need, and if we've reached that point we've already included the old depfile.
#
# NOTE: nvc uses absolute pathnames for the targets.
run: all
	$(MAKE) $(realpath $(WORK))/WORK.$(shell echo $(TOP) | tr a-z A-Z)
	$(NVC) $(NVCFLAGS) --work=$(WORK) -e $(EFLAGS) $(TOP)
	$(NVC) $(NVCFLAGS) --work=$(WORK) -r $(RFLAGS) $(TOP)

WORKPAT = $(subst /,\/,$(realpath $(WORK))/WORK.[A-Z0-9_]+:)

$(DEPS): $(STAMP) $(SRC)
	$(NVC) $(NVCFLAGS) --work=$(WORK) --print-deps | awk '/$(WORKPAT)/ { s = $$1; sub(":", "", s); deps = deps s " "; print $$0 " ; $$(NVC) $$(NVCFLAGS) --work=$$(WORK) -a $$(AFLAGS) $$<"; next } 1; END { print "all: " deps }' > $@
