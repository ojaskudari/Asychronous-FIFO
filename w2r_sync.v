`timescale 1ns / 1ps

module w2r_sync #(parameter ADDRSIZE = 4)(
    output reg [ADDRSIZE:0] s_rd_ptr, // Synchronized write pointer in read clock domain
    input      [ADDRSIZE:0] wptr,     // Write pointer from write clock domain
    input                   r_clk,    // Read clock
    input                   r_rst_n   // Active-low reset
);

  reg [ADDRSIZE:0] rq1_wptr; // First stage of synchronization

always @(posedge r_clk or negedge r_rst_n)
begin
    if (!r_rst_n) 
    begin
        rq1_wptr <= 0;
        s_rd_ptr <= 0; // Reset both stages of the synchronizer
    end
    else
    begin
        rq1_wptr <= wptr;  // First stage capture
        s_rd_ptr <= rq1_wptr; // Second stage capture
    end
end

endmodule
