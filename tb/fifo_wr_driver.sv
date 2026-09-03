// Write BFM. Drives on negedge, samples on posedge, so stimulus never races the DUT.
class fifo_wr_driver #(parameter int DATA_WIDTH = 32);

  virtual fifo_wr_if #(DATA_WIDTH)          vif;
  mailbox #(fifo_transaction #(DATA_WIDTH)) drv_mbx;
  string name = "WR_DRV";

  function new(virtual fifo_wr_if #(DATA_WIDTH) vif,
               mailbox #(fifo_transaction #(DATA_WIDTH)) drv_mbx);
    this.vif     = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task run();

    vif.wr_en   <= 1'b0;
    vif.wr_data <= '0;
    wait (vif.arst_n == 1'b1);

    forever begin
      fifo_transaction #(DATA_WIDTH) tr;
      drv_mbx.get(tr);
      drive(tr);
    end
  endtask

  task drive(fifo_transaction #(DATA_WIDTH) tr);

    repeat (tr.delay) @(negedge vif.wr_clk);

    @(negedge vif.wr_clk);
    vif.wr_en   <= 1'b1;
    vif.wr_data <= tr.data;

    @(posedge vif.wr_clk);
    // Hold wr_en through back-pressure rather than dropping the write.
    while (vif.fifo_full) @(posedge vif.wr_clk);

    @(negedge vif.wr_clk);
    vif.wr_en <= 1'b0;

    if (verbose) $display("[%0t] [%s] drove %s", $time, name, tr.convert2str());
  endtask

endclass
