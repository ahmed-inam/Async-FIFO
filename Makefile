# Async FIFO -- AMD Vivado (XSim) flow.
#
#   make                 run the default test (basic)
#   make sim TEST=ratio  run one test by name
#   make regress         run every test, report pass/fail per test
#   make gui TEST=fill   run in the Vivado GUI with waveforms
#   make clean

TOP  := tb_top
SNAP := $(TOP)_sim

RTL := \
  rtl/two_ff_sync.sv \
  rtl/fifo_mem.sv \
  rtl/wptr_full.sv \
  rtl/rptr_empty.sv \
  rtl/async_fifo.sv

# The test/component classes are pulled in by fifo_pkg.sv via `include, so only
# these three compile directly. -i tb tells xvlog where to find the rest.
TB := \
  tb/fifo_if.sv \
  tb/fifo_pkg.sv \
  tb/tb_top.sv

SRCS := $(RTL) $(TB)

TESTS := smoke basic fill reset empty concurrent ratio
TEST  ?= basic

# soak size and watchdog, used by the stress target
NUM     ?= 1000
TIMEOUT ?= 400000000

XVLOG_FLAGS := -sv -i ./tb
XELAB_FLAGS := -relax -debug typical -s $(SNAP)

.PHONY: all compile elab sim regress stress gui clean help

all: sim

compile:
	xvlog $(XVLOG_FLAGS) $(SRCS)

elab: compile
	xelab $(XELAB_FLAGS) $(TOP)

sim: elab
	xsim $(SNAP) -testplusarg "TEST=$(TEST)" -R 2>&1 | tee sim_$(TEST).log
	@! grep -qE "RESULT: FAIL|Error|\[tb_top\] TIMEOUT" sim_$(TEST).log

regress: elab
	@fail=0; \
	for t in $(TESTS); do \
	  xsim $(SNAP) -testplusarg "TEST=$$t" -R > reg_$$t.log 2>&1; \
	  if grep -qE "RESULT: FAIL|Error|\[tb_top\] TIMEOUT" reg_$$t.log; \
	  then echo "  $$t FAIL"; fail=1; else echo "  $$t pass"; fi; \
	done; \
	exit $$fail

# Constrained-random soak. make stress NUM=10000
stress: elab
	xsim $(SNAP) -testplusarg "TEST=stress" -testplusarg "NUM=$(NUM)" \
	     -testplusarg "TIMEOUT=$(TIMEOUT)" -R 2>&1 | tee stress_$(NUM).log
	@! grep -qE "RESULT: FAIL|Error|\[tb_top\] TIMEOUT" stress_$(NUM).log

gui: elab
	xsim $(SNAP) -testplusarg "TEST=$(TEST)" -gui

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb .Xil *.vcd

help:
	@echo "  make                 run the default test (basic)"
	@echo "  make sim TEST=<name> run one test: $(TESTS)"
	@echo "  make regress         run every test"
	@echo "  make stress NUM=<n>  constrained-random soak"
	@echo "  make gui TEST=<name> run in the Vivado GUI"
	@echo "  make clean"
