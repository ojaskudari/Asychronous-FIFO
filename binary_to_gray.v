`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/14/2025 01:25:20 AM
// Design Name: 
// Module Name: binary_to_gray
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



// Binary to Gray Code Converter Module
module binary_to_gray#(SIZE=4) (
    input  [SIZE:0] bin,   // N-bit binary input
    output [SIZE:0] gray   // N-bit Gray code output
);
    assign gray = (bin >> 1) ^ bin;  // Binary to Gray conversion logic
endmodule
