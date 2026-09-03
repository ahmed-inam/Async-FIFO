// Read pointer and empty flag. Entirely in the rd_clk domain.
module rptr_empty #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  rd_clk,
    input  logic                  arst_n,
    input  logic                  rd_en,
    input  logic [ADDR_WIDTH:0]   rq2_wptr,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [ADDR_WIDTH:0]   rd_ptr,
    output logic                  empty
);
    logic [ADDR_WIDTH:0] rbin, rbin_next;
    logic [ADDR_WIDTH:0] rgray_next;
    logic                empty_next;

    always_ff @(posedge rd_clk or negedge arst_n) begin
        if (!arst_n) begin
            rbin   <= '0;
            rd_ptr <= '0;
        end else begin
            rbin   <= rbin_next;
            rd_ptr <= rgray_next;
        end
    end

    assign rd_addr    = rbin[ADDR_WIDTH-1:0];

    assign rbin_next  = rbin + (rd_en & ~empty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;

    // EMPTY: the next read Gray has caught up exactly with the synced write Gray.
    assign empty_next = (rgray_next == rq2_wptr);

    always_ff @(posedge rd_clk or negedge arst_n) begin
        if (!arst_n) empty <= 1'b1;  // reset state is empty
        else         empty <= empty_next;
    end
endmodule
