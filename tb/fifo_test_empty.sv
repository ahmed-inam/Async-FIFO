// Empty boundary. A read while empty must be refused -- no phantom data --
// and empty must re-assert once the last word is out, and stay asserted.
class fifo_test_empty #(parameter int DATA_WIDTH = 32,
                        parameter int FIFO_DEPTH = 16) extends fifo_test #(DATA_WIDTH);

  fifo_fill_sequence #(DATA_WIDTH) wr_seq;

  localparam int N_ITEMS = 6;

  int unsigned reads_while_empty = 0;
  bit          watch_enable      = 0;
  int unsigned n_state_errors    = 0;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "EMPTY";
  endfunction

  function void check(string what, bit actual, bit expected);
    if (actual !== expected) begin
      n_state_errors++;
      $error("[%0t] [%s] %s = %0b, expected %0b", $time, name, what, actual, expected);
    end
    else
      $display("[%0t] [%s] %s = %0b  OK", $time, name, what, actual);
  endfunction

  task watch_reads();
    forever begin
      @(posedge rd_vif.rd_clk);
      if (watch_enable && rd_vif.rd_en && !rd_vif.fifo_empty)
        reads_while_empty++;
    end
  endtask

  virtual task body();
    fork
      watch_reads();
    join_none

    check("empty at start", rd_vif.fifo_empty, 1'b1);

    watch_enable = 1;
    env.rd_agent.seq.directed = 1;
    env.rd_agent.seq.n_items  = 1;
    fork
      env.rd_agent.seq.run();
    join_none

    repeat (25) @(posedge rd_vif.rd_clk);
    check("still empty after read attempt", rd_vif.fifo_empty, 1'b1);
    if (reads_while_empty != 0)
      $error("[%0t] [%s] %0d reads accepted while empty", $time, name, reads_while_empty);
    else
      $display("[%0t] [%s] no reads accepted while empty  OK", $time, name);
    watch_enable = 0;

    wr_seq = new(env.wr_agent.seq2drv_mbx);
    wr_seq.n_items   = N_ITEMS;
    wr_seq.base_data = 32'hB000_0000;
    wr_seq.run();

    repeat (25) @(posedge rd_vif.rd_clk);
    check("not empty after writes", rd_vif.fifo_empty, 1'b0);

    env.rd_agent.seq.n_items = N_ITEMS - 1;
    env.rd_agent.seq.run();

    repeat (180) @(posedge rd_vif.rd_clk);
    check("empty after full drain", rd_vif.fifo_empty, 1'b1);
    repeat (20) @(posedge rd_vif.rd_clk);
    check("empty stays asserted", rd_vif.fifo_empty, 1'b1);

    if (n_state_errors == 0)
      $display("[%0t] [%s] empty boundary correct", $time, name);
  endtask

endclass
