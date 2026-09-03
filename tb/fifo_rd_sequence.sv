// Read stimulus. directed=1 issues back-to-back reads; directed=0 randomizes spacing.
class fifo_rd_sequence #(parameter int DATA_WIDTH = 32);

  mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx;
  string name = "RD_SEQ";

  int unsigned n_items   = 1;
  int unsigned max_delay = 0;
  bit          directed  = 0;

  function new(mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx);
    this.seq_mbx = seq_mbx;
  endfunction

  task run();
    for (int i = 0; i < n_items; i++) begin
      fifo_transaction #(DATA_WIDTH) tr = new();

      if (directed) begin
        tr.delay = 0;
      end
      else begin
        assert (tr.randomize() with { delay <= max_delay; })
          else $error("[%s] randomize failed", name);
      end

      tr.kind = fifo_transaction #(DATA_WIDTH)::READ;

      seq_mbx.put(tr);
      if (verbose) $display("[%0t] [%s] sent %s", $time, name, tr.convert2str());
    end
  endtask

endclass
