// Simultaneous read and write on unrelated clocks, sustained long enough that
// the pointers wrap several times.
class fifo_test_concurrent #(parameter int DATA_WIDTH = 32,
                             parameter int FIFO_DEPTH = 16) extends fifo_test #(DATA_WIDTH);

  fifo_fill_sequence #(DATA_WIDTH) wr_seq;

  localparam int N_ITEMS = 40;
  localparam int TIMEOUT = 20000;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "CONCUR";
  endfunction

  // Sequences only dispatch into the mailbox (zero sim time), so fork/join returns
  // immediately. Wait on the scoreboard, not on a guessed drain length.
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

    wr_seq = new(env.wr_agent.seq2drv_mbx);
    wr_seq.n_items   = N_ITEMS;
    wr_seq.base_data = 32'hD000_0000;

    env.rd_agent.seq.directed  = 0;
    env.rd_agent.seq.max_delay = 3;
    env.rd_agent.seq.n_items   = N_ITEMS;

    $display("[%0t] [%s] starting %0d concurrent writes and reads",
             $time, name, N_ITEMS);

    fork
      wr_seq.run();
      env.rd_agent.seq.run();
    join

    wait_for_reads(N_ITEMS);

    repeat (20) @(posedge rd_vif.rd_clk);

    $display("[%0t] [%s] concurrent phase complete (%0d writes, %0d reads)",
             $time, name, env.scbd.n_written, env.scbd.n_read);
  endtask

endclass
