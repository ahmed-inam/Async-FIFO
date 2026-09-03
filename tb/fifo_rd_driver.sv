// Read BFM. Drives on negedge, samples on posedge, so stimulus never races the DUT.
class fifo_rd_driver #(parameter int DATA_WIDTH = 32);

  virtual fifo_rd_if #(DATA_WIDTH)          vif;
  mailbox #(fifo_transaction #(DATA_WIDTH)) drv_mbx;
  string name = "RD_DRV";

  function new(virtual fifo_rd_if #(DATA_WIDTH) vif,
               mailbox #(fifo_transaction #(DATA_WIDTH)) drv_mbx);
    this.vif     = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task run();
    vif.rd_en <= 1'b0;
    wait (vif.arst_n == 1'b1);

    forever begin
      fifo_transaction #(DATA_WIDTH) tr;
      drv_mbx.get(tr);
      drive(tr);
    end
  endtask

  task drive(fifo_transaction #(DATA_WIDTH) tr);

    repeat (tr.delay) @(negedge vif.rd_clk);

    @(negedge vif.rd_clk);
    vif.rd_en <= 1'b1;

    @(posedge vif.rd_clk);
    // Hold rd_en until the FIFO has something to give.
    while (vif.fifo_empty) @(posedge vif.rd_clk);

    @(negedge vif.rd_clk);
    vif.rd_en <= 1'b0;

    if (verbose) $display("[%0t] [%s] read request done %s",
                          $time, name, tr.convert2str());
  endtask

endclass
