// Named stimulus: n_items back-to-back writes with generated data, to drive the
// FIFO to and past full.
class fifo_fill_sequence #(parameter int DATA_WIDTH = 32);

  mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx;
  string name = "FILL_SEQ";

  int unsigned           n_items   = 16;
  logic [DATA_WIDTH-1:0] base_data = 32'hC000_0000;

  function new(mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx);
    this.seq_mbx = seq_mbx;
  endfunction

  task run();
    for (int i = 0; i < n_items; i++) begin
      fifo_transaction #(DATA_WIDTH) tr = new();
      tr.data  = base_data + i;
      tr.delay = 0;
      tr.kind  = fifo_transaction #(DATA_WIDTH)::WRITE;

      seq_mbx.put(tr);
      if (verbose) $display("[%0t] [%s] sent %s", $time, name, tr.convert2str());
    end
  endtask

endclass
