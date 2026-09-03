// Write-side driver + monitor + sequence. Owns the sequence-to-driver mailbox;
// the monitor-to-scoreboard mailbox comes from the env.
class fifo_wr_agent #(parameter int DATA_WIDTH = 32);

  virtual fifo_wr_if #(DATA_WIDTH)          vif;
  mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx;

  fifo_wr_driver   #(DATA_WIDTH) drv;
  fifo_wr_monitor  #(DATA_WIDTH) mon;
  fifo_wr_sequence #(DATA_WIDTH) seq;

  mailbox #(fifo_transaction #(DATA_WIDTH)) seq2drv_mbx;

  function new(virtual fifo_wr_if #(DATA_WIDTH) vif,
               mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx);
    this.vif     = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  function void build();
    seq2drv_mbx = new();
    drv = new(vif, seq2drv_mbx);
    seq = new(seq2drv_mbx);
    mon = new(vif, mon_mbx);
  endfunction

  task run();
    fork
      drv.run();
      mon.run();
    join_none
  endtask

endclass
