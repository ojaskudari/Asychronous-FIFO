`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2025 01:36:51 PM
// Design Name: 
// Module Name: FIFO_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// module FIFO_memory #(
//     parameter DATASIZE = 128,  // Memory data word width
//     parameter ADDRSIZE = 4   // Number of memory address bits
// )(
//     output [DATASIZE-1:0] rdata,   // Read data
//     input  [DATASIZE-1:0] wdata,   // Write data
//     input  [ADDRSIZE-1:0] waddr,   // Write address
//     input  [ADDRSIZE-1:0] raddr,   // Read address
//     input                 wclken,  // Write enable
//     input                 wfull,   // Full flag
//     input                 wclk     // Write clock
// );


// module r2w_sync #(parameter ADDRSIZE = 4)(
//     output reg [ADDRSIZE:0] s_wr_ptr, // Synchronized read pointer in write clock domain
//     input      [ADDRSIZE:0] rptr,     // Read pointer from read clock domain
//     input                   w_clk,    // Write clock
//     input                   w_rst_n   // Active-low reset
// );


// module w2r_sync #(parameter ADDRSIZE = 4)(
//     output reg [ADDRSIZE:0] s_rd_ptr, // Synchronized write pointer in read clock domain
//     input      [ADDRSIZE:0] wptr,     // Write pointer from write clock domain
//     input                   r_clk,    // Read clock
//     input                   r_rst_n   // Active-low reset
// );

//   reg [ADDRSIZE:0] rq1_wptr; // First stage of synchronizatio


// module Read_pointer #( parameter SIZE=4)(
//     input r_clk, r_rst_n, r_en,
//     input [SIZE:0] s_wr_ptr,  // Corrected name to indicate it's the synchronized write pointer

//     output reg r_empty,
//     wire [SIZE-1:0] r_addr,
//     output reg [SIZE:0] r_ptr
// );


// module Write_pointer # ( parameter SIZE=4)(
//     input w_clk, w_rst_n, w_en,
//     input [SIZE:0] s_rd_ptr,

//     output reg w_full,
//     output  [SIZE-1:0] w_addr,
//     output reg [SIZE:0] w_ptr
// );


module FIFO_top #(
    parameter data = 128,
    parameter addr = 4
)(
    input w_clk,
    input r_clk,
    input w_rst_n,
    input r_rst_n,
    input w_en,
    input r_en,
    input [data-1:0] wdata,
    output [data-1:0] rdata,
    output w_full,
    output r_empty
);

    // Internal wire declarations
    wire [addr:0] r_ptr;          // Read pointer from Read_pointer
    wire [addr:0] w_ptr;          // Write pointer from Write_pointer
    wire [addr:0] synced_r_ptr;   // Synchronized read pointer in write domain
    wire [addr:0] synced_w_ptr;   // Synchronized write pointer in read domain
    wire [addr-1:0] r_addr;       // Read address to memory
    wire [addr-1:0] w_addr;       // Write address to memory

    // Synchronize read pointer to write clock domain
    r2w_sync #(.ADDRSIZE(addr)) r2w_sync_inst (
        .s_wr_ptr(synced_r_ptr),
        .rptr(r_ptr),
        .w_clk(w_clk),
        .w_rst_n(w_rst_n)
    );

    // Synchronize write pointer to read clock domain
    w2r_sync #(.ADDRSIZE(addr)) w2r_sync_inst (
        .s_rd_ptr(synced_w_ptr),
        .wptr(w_ptr),
        .r_clk(r_clk),
        .r_rst_n(r_rst_n)
    );

    // Read pointer logic
    Read_pointer #(.SIZE(addr)) read_ptr_inst (
        .r_clk(r_clk), 
        .r_rst_n(r_rst_n),
        .r_en(r_en),
        .s_wr_ptr(synced_w_ptr), // Synchronized write pointer
        .r_empty(r_empty),
        .r_addr(r_addr),
        .r_ptr(r_ptr)
    );

    // Write pointer logic
    Write_pointer #(.SIZE(addr)) write_ptr_inst (
        .w_clk(w_clk),
        .w_rst_n(w_rst_n),
        .w_en(w_en),
        .s_rd_ptr(synced_r_ptr), // Synchronized read pointer
        .w_full(w_full),
        .w_addr(w_addr),
        .w_ptr(w_ptr)
    );

    // FIFO memory instantiation
    FIFO_memory #(
        .DATASIZE(data),
        .ADDRSIZE(addr)
    ) fifo_mem_inst (
        .rdata(rdata),
        .wdata(wdata),
        .waddr(w_addr),
        .raddr(r_addr),
        .wclken(w_en & ~w_full), // Directly use w_en (internal logic handles w_full)
        .wfull(w_full),
        .wclk(w_clk)
    );

endmodule
