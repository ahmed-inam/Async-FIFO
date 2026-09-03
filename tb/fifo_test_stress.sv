// Constrained-random soak. Both interfaces randomise data and spacing and run
// concurrently for N transactions (+NUM=<n>, default 1000), long enough that the two
// clocks drift through a wide range of phase relationships and the pointers wrap
// repeatedly. Rising edges of full and empty are counted as a stress-coverage
// indicator: a soak that never reaches either extreme has not stressed the flags.
class fifo_test_stress #(parameter int DATA_WIDTH = 32,
                         parameter int FIFO_DEPTH = 16) extends fifo_test #(DATA_WIDTH);

  int unsigned n_items = 1000;

  int unsigned full_hits  = 0;
  int unsigned empty_hits = 0;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "STRESS";
    void'($value$plusargs("NUM=%d", n_items));
  endfunction

  // Rising edges only: full stays asserted across many cycles, and counting levels
  // would report clock cycles rather than times the boundary was reached.
  task watch_flags();
    bit full_d  = 0;
    bit empty_d = 1;
    forever begin
      @(posedge wr_vif.wr_clk);
      if (wr_vif.fifo_full  && !full_d)  full_hits++;
      if (rd_vif.fifo_empty && !empty_d) empty_hits++;
      full_d  = wr_vif.fifo_full;
      empty_d = rd_vif.fifo_empty;
    end
  endtask

  // Sequences only dispatch into the mailbox (zero sim time), so wait on the
  // scoreboard rather than a guessed drain length. The budget scales with n_items
  // because the drivers execute the backlog at hardware speed.
  task wait_for_reads(int unsigned n);
    int unsigned cycles  = 0;
    int unsigned timeout = 200 * n + 20000;
    while (env.scbd.n_read < n && cycles < timeout) begin
      @(posedge rd_vif.rd_clk);
      cycles++;
    end
    if (env.scbd.n_read < n)
      $error("[%0t] [%s] timeout: only %0d of %0d reads completed",
             $time, name, env.scbd.n_read, n);
  endtask

  virtual task body();
    verbose = 0;   // per-transaction tracing would dwarf the run at this scale

    env.wr_agent.seq.directed  = 0;
    env.wr_agent.seq.max_delay = 3;
    env.wr_agent.seq.n_items   = n_items;

    env.rd_agent.seq.directed  = 0;
    env.rd_agent.seq.max_delay = 3;
    env.rd_agent.seq.n_items   = n_items;

    $display("[%0t] [%s] soaking %0d transactions per interface", $time, name, n_items);

    fork
      watch_flags();
    join_none

    fork
      env.wr_agent.seq.run();
      env.rd_agent.seq.run();
    join

    wait_for_reads(n_items);
    repeat (50) @(posedge rd_vif.rd_clk);

    $display("[%0t] [%s] %0d writes, %0d reads, %0d full hits, %0d empty hits",
             $time, name, env.scbd.n_written, env.scbd.n_read, full_hits, empty_hits);

    if (full_hits == 0 && empty_hits == 0)
      $error("[%s] soak never reached full or empty -- the flags were not stressed", name);
  endtask

endclass
