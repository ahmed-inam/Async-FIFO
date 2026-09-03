// Asymmetric producer/consumer rates. Phase A is a fast writer with a slow
// reader (backs up toward full), phase B the reverse (runs near empty). Throttled
// per transaction rather than by changing the clocks.
class fifo_test_ratio #(parameter int DATA_WIDTH = 32,
                        parameter int FIFO_DEPTH = 16) extends fifo_test #(DATA_WIDTH);

  fifo_fill_sequence #(DATA_WIDTH) wr_seq;

  localparam int N_A     = 24;
  localparam int N_B     = 24;
  localparam int TIMEOUT = 40000;

  bit full_seen  = 0;
  bit empty_seen = 0;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "RATIO";
  endfunction

  task watch_flags();
    forever begin
      @(posedge wr_vif.wr_clk);
      if (wr_vif.fifo_full)  full_seen  = 1;
      if (rd_vif.fifo_empty) empty_seen = 1;
    end
  endtask

  task wait_for_reads(int unsigned n);
    int unsigned cycles = 0;
    while (env.scbd.n_read < n && cycles < TIMEOUT) begin
      @(posedge rd_vif.rd_clk);
      cycles++;
    end
    if (env.scbd.n_read < n)
      $error("[%0t] [%s] timeout: only %0d of %0d reads completed",
             $time, name, env.scbd.n_read, n);
  endtask

  virtual task body();
    fork
      watch_flags();
    join_none

    $display("[%0t] [%s] phase A: fast writer / slow reader", $time, name);

    wr_seq = new(env.wr_agent.seq2drv_mbx);
    wr_seq.n_items   = N_A;
    wr_seq.base_data = 32'h9000_0000;

    env.rd_agent.seq.directed  = 0;
    env.rd_agent.seq.max_delay = 3;
    env.rd_agent.seq.n_items   = N_A;

    fork
      wr_seq.run();
      env.rd_agent.seq.run();
    join
    wait_for_reads(N_A);

    if (!full_seen)
      $display("[%0t] [%s] note: full never asserted in phase A", $time, name);
    else
      $display("[%0t] [%s] phase A reached full  OK", $time, name);

    $display("[%0t] [%s] phase B: slow writer / fast reader", $time, name);
    empty_seen = 0;

    env.wr_agent.seq.directed  = 0;
    env.wr_agent.seq.max_delay = 3;
    env.wr_agent.seq.n_items   = N_B;

    env.rd_agent.seq.directed  = 1;
    env.rd_agent.seq.n_items   = N_B;

    fork
      env.wr_agent.seq.run();
      env.rd_agent.seq.run();
    join
    wait_for_reads(N_A + N_B);

    if (!empty_seen)
      $display("[%0t] [%s] note: empty never asserted in phase B", $time, name);
    else
      $display("[%0t] [%s] phase B reached empty  OK", $time, name);

    repeat (40) @(posedge rd_vif.rd_clk);
    $display("[%0t] [%s] complete (%0d writes, %0d reads)",
             $time, name, env.scbd.n_written, env.scbd.n_read);
  endtask

endclass
