GHDL ?= ghdl

GHDLFLAGS = --std=08 -fpsl --workdir=$(WORK)

OUT = $(patsubst %.vhdl,$(WORK)/%.stamp,$(SRC))
DEPS = $(patsubst %.stamp,%.d,$(OUT))

all: $(WORK) $(OUT)

run: $(DEPS)
	$(GHDL) elab-run $(GHDLFLAGS) $(TOP)

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
	$(GHDL) analyze $(GHDLFLAGS) $< && touch $@
	@OUT=$@ && NAME=`basename $${OUT}` && UNIT=$${NAME%.stamp} && {           \
		if D=$$($(GHDL) gen-depends $(GHDLFLAGS) $${UNIT} 2>/dev/null); then  \
			echo "$$D" | sed "s:$(WORK)/$${UNIT}.o:$@:g";                     \
		else                                                                  \
			echo "$@: $(SRC)";                                                \
		fi;                                                                   \
	} > $${OUT%.stamp}.d
