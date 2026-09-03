// Reference model: every observed write is queued, every observed read pops the
// queue and must match. Leftover entries at report time mean data was lost.
class fifo_scoreboard #(parameter int DATA_WIDTH = 32);

  mailbox #(fifo_transaction #(DATA_WIDTH)) wr_mbx;
  mailbox #(fifo_transaction #(DATA_WIDTH)) rd_mbx;
  string name = "SCBD";

  fifo_transaction #(DATA_WIDTH) expected_q[$];

  int unsigned n_written = 0;
  int unsigned n_read    = 0;
  int unsigned n_errors  = 0;

  function new(mailbox #(fifo_transaction #(DATA_WIDTH)) wr_mbx,
               mailbox #(fifo_transaction #(DATA_WIDTH)) rd_mbx);
    this.wr_mbx = wr_mbx;
    this.rd_mbx = rd_mbx;
  endfunction

  task run();
    fork
      collect_writes();
      check_reads();
    join
  endtask

  task collect_writes();
    forever begin
      fifo_transaction #(DATA_WIDTH) wtr;
      wr_mbx.get(wtr);
      expected_q.push_back(wtr);
      n_written++;
      if (verbose) $display("[%0t] [%s] expect  %s", $time, name, wtr.convert2str());
    end
  endtask

  task check_reads();
    forever begin
      fifo_transaction #(DATA_WIDTH) rtr, etr;
      rd_mbx.get(rtr);
      n_read++;

      if (expected_q.size() == 0) begin
        n_errors++;
        $error("[%0t] [%s] READ with empty reference model: got data=0x%0h",
               $time, name, rtr.data);
        continue;
      end

      etr = expected_q.pop_front();
      if (rtr.compare(etr)) begin
        if (verbose) $display("[%0t] [%s] MATCH   exp=0x%0h got=0x%0h",
                              $time, name, etr.data, rtr.data);
      end
      else begin
        n_errors++;
        $error("[%0t] [%s] MISMATCH exp=0x%0h got=0x%0h",
               $time, name, etr.data, rtr.data);
      end
    end
  endtask

  function void report();
    $display("--------------------------------------------------");
    $display("[%s] writes=%0d reads=%0d leftover=%0d errors=%0d",
             name, n_written, n_read, expected_q.size(), n_errors);
    if (n_errors == 0 && expected_q.size() == 0)
      $display("[%s] RESULT: PASS", name);
    else
      $display("[%s] RESULT: FAIL", name);
    $display("--------------------------------------------------");
  endfunction

endclass
