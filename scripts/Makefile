ROOT := $(abspath ..)
BUILD := $(ROOT)/build
XVLOG ?= xvlog
XELAB ?= xelab
XSIM ?= xsim
VIVADO ?= vivado

.PHONY: all compile sim project clean check-tools
all: compile

check-compile-tools:
	@command -v $(XVLOG) >/dev/null || { echo "Missing $(XVLOG); source Vivado settings64.sh"; exit 1; }

check-sim-tools: check-compile-tools
	@command -v $(XELAB) >/dev/null || { echo "Missing $(XELAB); source Vivado settings64.sh"; exit 1; }
	@command -v $(XSIM) >/dev/null || { echo "Missing $(XSIM); source Vivado settings64.sh"; exit 1; }

compile: check-compile-tools
	@mkdir -p $(BUILD)
	@cd $(BUILD) && $(XVLOG) -sv -work work -f ../scripts/filelist_sv.f

# Add your authored testbench to scripts/filelist_tb.f and set TB_TOP to use this target.
TB_TOP ?=
sim: compile check-sim-tools
	@test -n "$(TB_TOP)" || { echo "Set TB_TOP to your testbench module after adding it to filelist_tb.f"; exit 2; }
	@cd $(BUILD) && $(XVLOG) -sv -work work -f ../scripts/filelist_tb.f
	@cd $(BUILD) && $(XELAB) -debug typical work.$(TB_TOP) -s $(TB_TOP)
	@cd $(BUILD) && $(XSIM) $(TB_TOP) -runall

project:
	@command -v $(VIVADO) >/dev/null || { echo "Missing $(VIVADO); source Vivado settings64.sh"; exit 1; }
	@$(VIVADO) -mode batch -source $(ROOT)/scripts/create_project.tcl

clean:
	rm -rf $(BUILD) $(ROOT)/vivado .Xil
