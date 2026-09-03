# Simulator-agnostic compile order, for flows that are not the Makefile's XSim.
#   Questa:  vlog -sv -f filelist.f && vsim -c tb_top +TEST=basic -do "run -all; quit"

../rtl/two_ff_sync.sv
../rtl/fifo_mem.sv
../rtl/wptr_full.sv
../rtl/rptr_empty.sv
../rtl/async_fifo.sv

fifo_if.sv
fifo_pkg.sv
tb_top.sv
