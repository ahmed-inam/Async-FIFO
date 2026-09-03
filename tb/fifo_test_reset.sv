// Reset behaviour. Samples the post-reset state (tb_top releases reset before
// the test starts), proves it holds over time, then proves the FIFO works from it.
class fifo_test_reset #(parameter int DATA_WIDTH = 32) extends fifo_test #(DATA_WIDTH);

  int unsigned n_state_errors = 0;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "RESET";
  endfunction

  function void check(string what, bit actual, bit expected);
    if (actual !== expected) begin
      n_state_errors++;
      $error("[%0t] [%s] %s = %0b, expected %0b", $time, name, what, actual, expected);
    end
    else
      $display("[%0t] [%s] %s = %0b  OK", $time, name, what, actual);
  endfunction

  virtual task body();

    $display("[%0t] [%s] checking post-reset state", $time, name);
    check("empty", rd_vif.fifo_empty, 1'b1);
    check("full",  wr_vif.fifo_full,  1'b0);

    repeat (10) @(posedge wr_vif.wr_clk);
    check("empty (held)", rd_vif.fifo_empty, 1'b1);
    check("full  (held)", wr_vif.fifo_full,  1'b0);

    $display("[%0t] [%s] checking operation from reset", $time, name);
    env.wr_agent.seq.directed = 1;
    env.wr_agent.seq.n_items  = 3;
    env.wr_agent.seq.data_q   = '{ 32'hE000_0001, 32'hE000_0002, 32'hE000_0003 };

    env.rd_agent.seq.directed = 1;
    env.rd_agent.seq.n_items  = 3;

    env.wr_agent.seq.run();

    repeat (15) @(posedge rd_vif.rd_clk);
    check("empty after writes", rd_vif.fifo_empty, 1'b0);

    env.rd_agent.seq.run();

    repeat (15) @(posedge rd_vif.rd_clk);
    check("empty after drain", rd_vif.fifo_empty, 1'b1);

    if (n_state_errors == 0)
      $display("[%0t] [%s] reset behaviour correct", $time, name);
    else
      $error("[%0t] [%s] %0d reset state errors", $time, name, n_state_errors);
  endtask

endclass
