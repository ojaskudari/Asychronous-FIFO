module write_pointer #(parameter SIZE = 4)
(
    input                   write_clk,         // Write clock
    input                   write_reset_n,     // Active low reset for write domain
    input                   write_inc,         // Write increment signal
    input      [SIZE:0]     read_pointer_grey, // Synchronized read pointer (Gray code)

    output reg              write_full,        // Full flag for FIFO
    output      [SIZE-1:0]  write_address,     // Write address for FIFO memory
    output reg [SIZE:0]     write_pointer      // Write pointer (Gray code)
);


    reg [SIZE:0] write_pointer_binary;

    wire [SIZE:0] write_pointer_binary_next;
    wire [SIZE:0] write_pointer_grey_next;
    wire          temp_write_full;


    always @(posedge write_clk or negedge write_reset_n)
    begin
        if (!write_reset_n)
            {write_pointer_binary, write_pointer} <= 0;
        else
            {write_pointer_binary, write_pointer} <= {write_pointer_binary_next, write_pointer_grey_next};
    end

    
    assign write_address = write_pointer_binary[SIZE-1:0];


    assign write_pointer_binary_next = write_pointer_binary + (write_inc & ~write_full);

    
    bin2gray #(SIZE) write_bin2gray (
        .bin(write_pointer_binary_next),
        .gray(write_pointer_grey_next)
    );


    assign temp_write_full = (write_pointer_grey_next == {~read_pointer_grey[SIZE:SIZE-1], read_pointer_grey[SIZE-2:0]});
    always @(posedge write_clk or negedge write_reset_n)
    begin
        if (!write_reset_n)
            write_full <= 1'b0;
        else
            write_full <= temp_write_full;
    end

endmodule
