// Passive write-side observer. Reports only transfers the DUT actually accepted.
class fifo_wr_monitor #(parameter int DATA_WIDTH = 32);

  virtual fifo_wr_if #(DATA_WIDTH)          vif;
  mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx;
  string name = "WR_MON";

  function new(virtual fifo_wr_if #(DATA_WIDTH) vif,
               mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx);
    this.vif     = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    wait (vif.arst_n == 1'b1);

    forever begin
      @(posedge vif.wr_clk);

      if (vif.wr_en && !vif.fifo_full) begin
        fifo_transaction #(DATA_WIDTH) tr = new();
        tr.kind     = fifo_transaction #(DATA_WIDTH)::WRITE;
        tr.data     = vif.wr_data;
        tr.saw_full = vif.fifo_full;
        mon_mbx.put(tr);
        if (verbose) $display("[%0t] [%s] observed %s", $time, name, tr.convert2str());
      end
    end
  endtask

endclass
