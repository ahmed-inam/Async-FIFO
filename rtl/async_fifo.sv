// Async FIFO top level. Gray-coded pointers crossed by two-flop synchronizers
// (Cummings, SNUG 2002 partitioned style). FIFO_DEPTH must be a power of 2.
module async_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16,

    parameter int ADDR_WIDTH = $clog2(FIFO_DEPTH)  // derived; do not override
)(
    input  logic                  wr_clk,
    input  logic                  arst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    input  logic                  rd_clk,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    // ADDR_WIDTH+1 bits: the extra MSB is what distinguishes full from empty.
    logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0] wq2_rptr;
    logic [ADDR_WIDTH:0] rq2_wptr;

    logic [ADDR_WIDTH-1:0] wr_addr, rd_addr;

    two_ff_sync #(.WIDTH(ADDR_WIDTH+1)) u_sync_r2w (
        .clk    (wr_clk),
        .arst_n (arst_n),
        .d_in   (rd_ptr),
        .d_out  (wq2_rptr)
    );

    two_ff_sync #(.WIDTH(ADDR_WIDTH+1)) u_sync_w2r (
        .clk    (rd_clk),
        .arst_n (arst_n),
        .d_in   (wr_ptr),
        .d_out  (rq2_wptr)
    );

    wptr_full #(.ADDR_WIDTH(ADDR_WIDTH)) u_wptr_full (
        .wr_clk   (wr_clk),
        .arst_n   (arst_n),
        .wr_en    (wr_en),
        .rq2_rptr (wq2_rptr),
        .wr_addr  (wr_addr),
        .wr_ptr   (wr_ptr),
        .full     (full)
    );

    rptr_empty #(.ADDR_WIDTH(ADDR_WIDTH)) u_rptr_empty (
        .rd_clk   (rd_clk),
        .arst_n   (arst_n),
        .rd_en    (rd_en),
        .rq2_wptr (rq2_wptr),
        .rd_addr  (rd_addr),
        .rd_ptr   (rd_ptr),
        .empty    (empty)
    );

    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_mem (
        .wr_clk  (wr_clk),
        .wclken  (wr_en & ~full),  // a full FIFO must not accept the write
        .wr_addr (wr_addr),
        .rd_addr (rd_addr),
        .wr_data (wr_data),
        .rd_data (rd_data)
    );

endmodule
