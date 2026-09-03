// Base test: owns the env, builds it, starts background components, then hands
// stimulus to body(). Each concrete test overrides body() and nothing else.
class fifo_test #(parameter int DATA_WIDTH = 32);

  virtual fifo_wr_if #(DATA_WIDTH) wr_vif;
  virtual fifo_rd_if #(DATA_WIDTH) rd_vif;

  fifo_env #(DATA_WIDTH) env;
  string name = "TEST";

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    this.wr_vif = wr_vif;
    this.rd_vif = rd_vif;
  endfunction

  virtual task body();
  endtask

  task run();

    env = new(wr_vif, rd_vif);
    env.build();

    env.run();

    $display("[%0t] [%s] starting stimulus", $time, name);
    body();

    repeat (20) @(posedge wr_vif.wr_clk);

    env.report();
  endtask

endclass

// Write one word, read it back.
class fifo_test_smoke #(parameter int DATA_WIDTH = 32) extends fifo_test #(DATA_WIDTH);

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "SMOKE";
  endfunction

  virtual task body();

    env.wr_agent.seq.directed = 1;
    env.wr_agent.seq.n_items  = 1;
    env.wr_agent.seq.data_q   = '{ 32'hDEAD_BEEF };

    env.rd_agent.seq.directed = 1;
    env.rd_agent.seq.n_items  = 1;

    env.wr_agent.seq.run();
    repeat (10) @(posedge wr_vif.wr_clk);
    env.rd_agent.seq.run();
  endtask

endclass

// Write five known words, drain all five, check order and content.
class fifo_test_basic #(parameter int DATA_WIDTH = 32) extends fifo_test #(DATA_WIDTH);

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "BASIC";
  endfunction

  virtual task body();

    env.wr_agent.seq.directed = 1;
    env.wr_agent.seq.n_items  = 5;
    env.wr_agent.seq.data_q   = '{ 32'hA000_0001, 32'hA000_0002,
                                   32'hA000_0003, 32'hA000_0004,
                                   32'hA000_0005 };

    env.rd_agent.seq.directed = 1;
    env.rd_agent.seq.n_items  = 5;

    env.wr_agent.seq.run();
    repeat (10) @(posedge wr_vif.wr_clk);
    env.rd_agent.seq.run();
  endtask

endclass

// Overfill. Checks full asserts at exactly FIFO_DEPTH entries, that the
// excess writes are held by driver back-pressure rather than lost, and that
// everything written comes back in order.
class fifo_test_fill #(parameter int DATA_WIDTH = 32,
                       parameter int FIFO_DEPTH = 16) extends fifo_test #(DATA_WIDTH);

  fifo_fill_sequence #(DATA_WIDTH) fill_seq;

  int unsigned writes_when_full = 0;
  bit          full_seen        = 0;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    super.new(wr_vif, rd_vif);
    name = "FILL";
  endfunction

  task monitor_full();
    int unsigned accepted = 0;
    forever begin
      @(posedge wr_vif.wr_clk);
      if (wr_vif.wr_en && !wr_vif.fifo_full) accepted++;
      if (wr_vif.fifo_full && !full_seen) begin
        full_seen        = 1;
        writes_when_full = accepted;
        $display("[%0t] [%s] full asserted after %0d accepted writes",
                 $time, name, accepted);
      end
    end
  endtask

  virtual task body();

    fill_seq = new(env.wr_agent.seq2drv_mbx);
    fill_seq.n_items = FIFO_DEPTH + 4;

    fork
      monitor_full();
    join_none

    fill_seq.run();
    repeat (30) @(posedge wr_vif.wr_clk);

    env.rd_agent.seq.directed = 1;
    env.rd_agent.seq.n_items  = FIFO_DEPTH + 4;
    env.rd_agent.seq.run();

    repeat (30) @(posedge rd_vif.rd_clk);

    if (!full_seen)
      $error("[%s] full never asserted after %0d writes", name, FIFO_DEPTH + 4);
    else if (writes_when_full != FIFO_DEPTH)
      $error("[%s] full asserted after %0d writes, expected %0d",
             name, writes_when_full, FIFO_DEPTH);
    else
      $display("[%s] full boundary correct: asserted at %0d entries",
               name, FIFO_DEPTH);
  endtask

endclass
