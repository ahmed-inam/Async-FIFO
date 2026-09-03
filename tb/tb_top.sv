`timescale 1ns/1ps

// Hardware top: two independent clocks, shared reset, interfaces, DUT, and the
// handoff from the static world to the class world via virtual interfaces.
import fifo_pkg::*;

module tb_top;

  localparam int DATA_WIDTH = 32;
  localparam int FIFO_DEPTH = 16;

  logic wr_clk = 0;
  logic rd_clk = 0;
  logic arst_n = 0;

  always #5  wr_clk = ~wr_clk;   // 100 MHz
  always #7  rd_clk = ~rd_clk;   // ~71 MHz -- coprime period, so the domains never lock in phase

  fifo_wr_if #(DATA_WIDTH) wr_if (.wr_clk(wr_clk), .arst_n(arst_n));
  fifo_rd_if #(DATA_WIDTH) rd_if (.rd_clk(rd_clk), .arst_n(arst_n));

  async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .FIFO_DEPTH (FIFO_DEPTH)
  ) dut (
    .wr_clk  (wr_clk),
    .arst_n  (arst_n),
    .wr_en   (wr_if.wr_en),
    .wr_data (wr_if.wr_data),
    .full    (wr_if.fifo_full),

    .rd_clk  (rd_clk),
    .rd_en   (rd_if.rd_en),
    .rd_data (rd_if.rd_data),
    .empty   (rd_if.fifo_empty)
  );

  fifo_test #(DATA_WIDTH) test;

  initial begin
    arst_n = 0;
    repeat (5) @(posedge wr_clk);
    // Release off the posedge: releasing on one collapses the drivers' first clocking wait.
    @(negedge wr_clk);
    arst_n = 1;

    begin
      string tname;
      if (!$value$plusargs("TEST=%s", tname)) tname = "basic";

      case (tname)
        "smoke": test = fifo_test_smoke #(DATA_WIDTH)::new(wr_if, rd_if);
        "basic": test = fifo_test_basic #(DATA_WIDTH)::new(wr_if, rd_if);
        "fill" : test = fifo_test_fill  #(DATA_WIDTH, FIFO_DEPTH)::new(wr_if, rd_if);
        "reset": test = fifo_test_reset #(DATA_WIDTH)::new(wr_if, rd_if);
        "empty": test = fifo_test_empty #(DATA_WIDTH, FIFO_DEPTH)::new(wr_if, rd_if);
        "concurrent": test = fifo_test_concurrent #(DATA_WIDTH, FIFO_DEPTH)::new(wr_if, rd_if);
        "ratio": test = fifo_test_ratio #(DATA_WIDTH, FIFO_DEPTH)::new(wr_if, rd_if);
        "stress": test = fifo_test_stress #(DATA_WIDTH, FIFO_DEPTH)::new(wr_if, rd_if);
        default: begin
          $display("[tb_top] unknown TEST=%s, using basic", tname);
          test = fifo_test_basic #(DATA_WIDTH)::new(wr_if, rd_if);
        end
      endcase
    end

    test.run();
    $finish;
  end

  // Global watchdog so a hang cannot run forever. Overridable because the soak test
  // legitimately runs orders of magnitude longer than the directed tests.
  initial begin
    int unsigned tmo = 500000;
    void'($value$plusargs("TIMEOUT=%d", tmo));
    #tmo;
    $display("[tb_top] TIMEOUT");
    $finish;
  end

  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
