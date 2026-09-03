// Write stimulus. directed=1 replays data_q verbatim; directed=0 randomizes.
class fifo_wr_sequence #(parameter int DATA_WIDTH = 32);

  mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx;
  string name = "WR_SEQ";

  int unsigned          n_items   = 1;
  bit                   directed  = 0;
  int unsigned          max_delay = 0;
  logic [DATA_WIDTH-1:0] data_q[$];

  function new(mailbox #(fifo_transaction #(DATA_WIDTH)) seq_mbx);
    this.seq_mbx = seq_mbx;
  endfunction

  task run();

    if (directed)
      assert (data_q.size() >= n_items)
        else $fatal(1, "[%s] directed mode needs data_q.size()>=%0d, got %0d",
                    name, n_items, data_q.size());

    for (int i = 0; i < n_items; i++) begin
      fifo_transaction #(DATA_WIDTH) tr = new();

      if (directed) begin
        tr.data  = data_q[i];
        tr.delay = 0;
      end
      else begin
        assert (tr.randomize() with { delay <= max_delay; })
          else $error("[%s] randomize failed", name);
      end

      tr.kind = fifo_transaction #(DATA_WIDTH)::WRITE;

      seq_mbx.put(tr);
      if (verbose) $display("[%0t] [%s] sent %s", $time, name, tr.convert2str());
    end
  endtask

endclass
