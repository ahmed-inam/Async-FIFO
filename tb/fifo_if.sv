`timescale 1ns/1ps

// One interface per clock domain. Interfaces compile like modules, so these live
// outside fifo_pkg.

interface fifo_wr_if #(parameter int DATA_WIDTH = 32)
                      (input logic wr_clk, input logic arst_n);
  logic                  wr_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic                  fifo_full;
endinterface

interface fifo_rd_if #(parameter int DATA_WIDTH = 32)
                      (input logic rd_clk, input logic arst_n);
  logic                  rd_en;
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  fifo_empty;
endinterface
