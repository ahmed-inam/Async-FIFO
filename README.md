# Asynchronous FIFO

A parameterized dual-clock FIFO in SystemVerilog, with a class-based testbench
covering the four requirements a CDC FIFO has to meet: correct reset state,
correct full/empty boundaries, safe concurrent access, and correct behaviour at
asymmetric producer/consumer rates.

Built in the partitioned style from Clifford Cummings' *Simulation and Synthesis
Techniques for Asynchronous FIFO Design* (SNUG 2002): Gray-coded pointers crossed
between domains through two-flop synchronizers, with flag generation living in
the domain that owns each pointer.

## Design

    async_fifo          top level, wires the four blocks together
      two_ff_sync   x2  CDC synchronizer, one per pointer crossing
      wptr_full         write pointer + full flag   (wr_clk domain)
      rptr_empty        read pointer  + empty flag  (rd_clk domain)
      fifo_mem          dual-port storage, sync write / comb read

Parameters: `DATA_WIDTH` (default 32) and `FIFO_DEPTH` (default 16, must be a
power of 2). Reset is a single shared active-low asynchronous `arst_n`.

Pointers are `$clog2(FIFO_DEPTH)+1` bits wide. The extra MSB is what separates
full from empty: equal pointers mean empty, while pointers equal in the low bits
with the top two inverted mean the write side has wrapped once more than the read
side, so the FIFO is full. Only Gray-coded values cross domains, so a pointer
sampled mid-transition can only ever be off by the one bit that is changing.

## Testbench

Class-based, two agents (one per clock domain), each with a driver, monitor and
sequence, plus a scoreboard that queues every observed write and pops it on every
observed read. Leftover entries at report time mean data was lost.

Drivers drive on `negedge` and sample on `posedge`, so stimulus never races the
DUT. `wr_clk` runs at 100 MHz and `rd_clk` at ~71 MHz -- coprime periods, so the
domains never settle into a fixed phase relationship.

| test | covers |
|---|---|
| `smoke`      | write one word, read it back |
| `basic`      | five known words, drained in order |
| `fill`       | `full` asserts at exactly `FIFO_DEPTH`; excess writes held, not lost |
| `reset`      | post-reset state, that it holds, and that the FIFO works from it |
| `concurrent` | simultaneous read and write until the pointers wrap repeatedly |
| `empty`      | a read while empty is refused; no phantom data |
| `ratio`      | fast-writer/slow-reader, then the reverse |
| `stress`     | constrained-random soak, `NUM` transactions per interface |

## Build

Developed against AMD Vivado XSim.

```bash
make                    # run the default test (basic)
make sim TEST=ratio     # run one test by name
make regress            # run every test, pass/fail per test
make stress NUM=10000   # constrained-random soak
make gui TEST=fill      # run in the Vivado GUI with waveforms
make clean
```

`tb/filelist.f` gives the same compile order for non-XSim flows.

The component and test classes are pulled into `fifo_pkg.sv` via `` `include ``,
so only `fifo_if.sv`, `fifo_pkg.sv` and `tb_top.sv` are compiled directly; `-i tb`
tells `xvlog` where to find the rest.

## Status

All eight tests pass. The recorded soak runs completed with 0 errors and no
leftover entries:

| transactions | writes | reads | leftover | errors | `full` hits | `empty` hits |
|---|---|---|---|---|---|---|
| 1,000  | 1,000  | 1,000  | 0 | 0 | 885   | 3 |
| 10,000 | 10,000 | 10,000 | 0 | 0 | 9,382 | 3 |

The high `full` count against the low `empty` count is the clock ratio showing
through: `wr_clk` at 10 ns against `rd_clk` at 14 ns means equal randomised
delays leave the FIFO under write pressure, so the soak exercises the full side
far harder than the empty side. The empty boundary is covered directly by the
`empty` and `ratio` tests instead.

The design was also re-verified at `DATA_WIDTH`=8 / `FIFO_DEPTH`=8 to confirm the
parameterization holds.
