// Wires both agents to the scoreboard. Build order matters: mailboxes, then the
// scoreboard that reads them, then the agents that write them.
class fifo_env #(parameter int DATA_WIDTH = 32);

  virtual fifo_wr_if #(DATA_WIDTH) wr_vif;
  virtual fifo_rd_if #(DATA_WIDTH) rd_vif;

  fifo_wr_agent    #(DATA_WIDTH) wr_agent;
  fifo_rd_agent    #(DATA_WIDTH) rd_agent;
  fifo_scoreboard  #(DATA_WIDTH) scbd;

  mailbox #(fifo_transaction #(DATA_WIDTH)) wr_mon_mbx;
  mailbox #(fifo_transaction #(DATA_WIDTH)) rd_mon_mbx;

  function new(virtual fifo_wr_if #(DATA_WIDTH) wr_vif,
               virtual fifo_rd_if #(DATA_WIDTH) rd_vif);
    this.wr_vif = wr_vif;
    this.rd_vif = rd_vif;
  endfunction

  function void build();

    wr_mon_mbx = new();
    rd_mon_mbx = new();

    scbd = new(wr_mon_mbx, rd_mon_mbx);

    wr_agent = new(wr_vif, wr_mon_mbx);
    rd_agent = new(rd_vif, rd_mon_mbx);
    wr_agent.build();
    rd_agent.build();
  endfunction

  task run();
    fork
      wr_agent.run();
      rd_agent.run();
      scbd.run();
    join_none
  endtask

  function void report();
    scbd.report();
  endfunction

endclass
