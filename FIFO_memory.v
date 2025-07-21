module FIFO_memory #(
    parameter DATASIZE = 128,  // Memory data word width
    parameter ADDRSIZE = 4   // Number of memory address bits
)(
    output [DATASIZE-1:0] rdata,   // Read data
    input  [DATASIZE-1:0] wdata,   // Write data
    input  [ADDRSIZE-1:0] waddr,   // Write address
    input  [ADDRSIZE-1:0] raddr,   // Read address
    input                 wclken,  // Write enable
    input                 wfull,   // Full flag
    input                 wclk     // Write clock
);

    // Instantiating Dual-Port RAM
     reg  [DATASIZE-1:0] mem [0:(1<<ADDRSIZE)-1];

  assign rdata = mem[raddr];

  always@(posedge wclk)
    if (wclken && !wfull)
      mem[waddr] <= wdata;

endmodule


