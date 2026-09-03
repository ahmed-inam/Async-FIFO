// Passive read-side observer. Reports only transfers the DUT actually accepted.
class fifo_rd_monitor #(parameter int DATA_WIDTH = 32);

  virtual fifo_rd_if #(DATA_WIDTH)          vif;
  mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx;
  string name = "RD_MON";

  function new(virtual fifo_rd_if #(DATA_WIDTH) vif,
               mailbox #(fifo_transaction #(DATA_WIDTH)) mon_mbx);
    this.vif     = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    wait (vif.arst_n == 1'b1);

    forever begin
      @(posedge vif.rd_clk);

      if (vif.rd_en && !vif.fifo_empty) begin
        fifo_transaction #(DATA_WIDTH) tr = new();
        tr.kind      = fifo_transaction #(DATA_WIDTH)::READ;
        tr.data      = vif.rd_data;
        tr.saw_empty = vif.fifo_empty;
        mon_mbx.put(tr);
        if (verbose) $display("[%0t] [%s] observed %s", $time, name, tr.convert2str());
      end
    end
  endtask

endclass
