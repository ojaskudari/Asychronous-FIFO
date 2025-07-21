`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2025 01:39:30 AM
// Design Name: 
// Module Name: r2w_sync
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



module r2w_sync #(parameter ADDRSIZE = 4)(
    output reg [ADDRSIZE:0] s_wr_ptr, // Synchronized read pointer in write clock domain
    input      [ADDRSIZE:0] rptr,     // Read pointer from read clock domain
    input                   w_clk,    // Write clock
    input                   w_rst_n   // Active-low reset
);

  reg [ADDRSIZE:0] rq1_rptr; // First stage of synchronization

always @(posedge w_clk or negedge w_rst_n)
begin
    if (!w_rst_n) 
    begin
        rq1_rptr <= 0;
        s_wr_ptr <= 0; // Reset both stages of the synchronizer
    end
    else
    begin
        rq1_rptr <= rptr;   // First stage capture
        s_wr_ptr <= rq1_rptr; // Second stage capture
    end
end

endmodule

