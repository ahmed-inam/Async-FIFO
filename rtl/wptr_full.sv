// Write pointer and full flag. Entirely in the wr_clk domain.
module wptr_full #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  wr_clk,
    input  logic                  arst_n,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH:0]   rq2_rptr,
    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [ADDR_WIDTH:0]   wr_ptr,
    output logic                  full
);
    logic [ADDR_WIDTH:0] wbin, wbin_next;
    logic [ADDR_WIDTH:0] wgray_next;
    logic                full_next;

    always_ff @(posedge wr_clk or negedge arst_n) begin
        if (!arst_n) begin
            wbin   <= '0;
            wr_ptr <= '0;
        end else begin
            wbin   <= wbin_next;
            wr_ptr <= wgray_next;
        end
    end

    assign wr_addr    = wbin[ADDR_WIDTH-1:0];

    assign wbin_next  = wbin + (wr_en & ~full);  // advance only on an accepted write
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;

    // FULL: next write Gray equals the synced read Gray with the top two bits
    // inverted -- pointers have wrapped an odd number of times onto the same slot.
    assign full_next = (wgray_next ==
                        {~rq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1],
                          rq2_rptr[ADDR_WIDTH-2:0]});

    always_ff @(posedge wr_clk or negedge arst_n) begin
        if (!arst_n) full <= 1'b0;
        else         full <= full_next;
    end
endmodule
