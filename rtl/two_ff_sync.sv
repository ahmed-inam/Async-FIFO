// Two-flop CDC synchronizer. One full destination cycle for metastability to settle.
module two_ff_sync #(
    parameter int WIDTH = 5
)(
    input  logic             clk,
    input  logic             arst_n,
    input  logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] d_out
);
    logic [WIDTH-1:0] sync_ff1;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            sync_ff1 <= '0;
            d_out    <= '0;
        end else begin
            sync_ff1 <= d_in;
            d_out    <= sync_ff1;
        end
    end
endmodule
