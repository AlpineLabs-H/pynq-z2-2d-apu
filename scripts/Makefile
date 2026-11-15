ROOT := $(abspath ..)
BUILD := $(ROOT)/build
XVLOG ?= xvlog
XELAB ?= xelab
XSIM ?= xsim
VIVADO ?= vivado

.PHONY: all compile sim project clean check-tools check-compile-tools check-sim-tools
all: compile

check-compile-tools:
	@command -v $(XVLOG) >/dev/null || { echo "Missing $(XVLOG); source Vivado settings64.sh"; exit 1; }

check-sim-tools: check-compile-tools
	@command -v $(XELAB) >/dev/null || { echo "Missing $(XELAB); source Vivado settings64.sh"; exit 1; }
	@command -v $(XSIM) >/dev/null || { echo "Missing $(XSIM); source Vivado settings64.sh"; exit 1; }

compile: check-compile-tools
	@mkdir -p $(BUILD)
	@cd $(BUILD) && $(XVLOG) -sv -work work -f ../scripts/filelist_sv.f

# Override TB_TOP when running a different testbench.
TB_TOP ?= Video_timing_tb
sim: compile check-sim-tools
	@cd $(BUILD) && $(XVLOG) -sv -work work -f ../scripts/filelist_tb.f
	@cd $(BUILD) && $(XELAB) -debug typical work.$(TB_TOP) -s $(TB_TOP)
	@cd $(BUILD) && { \
		$(XSIM) $(TB_TOP) -runall > xsim_run.log 2>&1; status=$$?; \
		cat xsim_run.log; \
		if [ $$status -ne 0 ] || grep -q "ERROR: unexpected exception" xsim_run.log; then exit 1; fi; \
	}

project:
	@command -v $(VIVADO) >/dev/null || { echo "Missing $(VIVADO); source Vivado settings64.sh"; exit 1; }
	@$(VIVADO) -mode batch -source $(ROOT)/scripts/create_project.tcl

clean:
	rm -rf $(BUILD) $(ROOT)/vivado .Xil
