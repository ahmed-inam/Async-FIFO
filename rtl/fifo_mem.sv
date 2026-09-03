// FIFO storage array: synchronous write in wr_clk, combinational read. No control logic.
module fifo_mem #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  wr_clk,
    input  logic                  wclken,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data
);
    localparam int DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [DEPTH];

    always_ff @(posedge wr_clk) begin
        if (wclken)
            mem[wr_addr] <= wr_data;
    end

    assign rd_data = mem[rd_addr];
endmodule
