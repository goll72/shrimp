GHDL ?= ghdl

GHDLFLAGS ?= 
BASEGHDLFLAGS = --std=08 -fpsl --workdir=$(WORK) $(GHDLFLAGS)

OUT = $(patsubst %.vhdl,$(WORK)/%.stamp,$(SRC))
DEPS = $(patsubst %.stamp,%.d,$(OUT))

all: $(WORK) $(OUT)

run: $(DEPS)
	$(GHDL) elab-run $(BASEGHDLFLAGS) $(TOP)

yosys: $(WORK) $(OUT)
	yosys -m ghdl -p "$(CMD)"

$(WORK):
	@mkdir -p $(WORK)

# If ghdl can't tell the dependencies for a given file (because it does 
# not correspond to an entity, e.g. files containing packages), then we 
# pretend that the file depends on all other files.
#
# This reduces the chance of build failures due to stale object
# files but increases the chances of circular dependencies.
#
# A better solution would be to depend on all files that come before the
# given file in SRC, since the files in SRC are listed in dependency order.
$(WORK)/%.stamp: %.vhdl
	@mkdir -p `dirname $@`
	$(GHDL) analyze $(BASEGHDLFLAGS) $< && touch $@
	@OUT=$@ && NAME=`basename $${OUT}` && UNIT=$${NAME%.stamp} && {           \
		if D=$$($(GHDL) gen-depends $(BASEGHDLFLAGS) $${UNIT} 2>/dev/null); then  \
			echo "$$D" | sed "s:$(WORK)/$${UNIT}.o:$@:g";                     \
		else                                                                  \
			echo "$@: $(SRC)";                                                \
		fi;                                                                   \
	} > $${OUT%.stamp}.d

.PHONY: yosys
