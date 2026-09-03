`timescale 1ns/1ps

// Compile-order manifest for the class-based TB. Interfaces are NOT here --
// they compile like modules, outside packages. `include order is dependency
// order: a file may only use things declared above it.
package fifo_pkg;

  // Shared debug switch; every component's `if (verbose)` refers to this one.
  bit verbose = 1;

  `include "fifo_transaction.sv"

  `include "fifo_wr_driver.sv"
  `include "fifo_rd_driver.sv"
  `include "fifo_wr_monitor.sv"
  `include "fifo_rd_monitor.sv"

  `include "fifo_wr_sequence.sv"
  `include "fifo_rd_sequence.sv"
  `include "fifo_fill_sequence.sv"

  `include "fifo_scoreboard.sv"

  `include "fifo_wr_agent.sv"
  `include "fifo_rd_agent.sv"

  `include "fifo_env.sv"

  `include "fifo_test.sv"
  `include "fifo_test_reset.sv"
  `include "fifo_test_empty.sv"
  `include "fifo_test_concurrent.sv"
  `include "fifo_test_ratio.sv"
  `include "fifo_test_stress.sv"

endpackage
