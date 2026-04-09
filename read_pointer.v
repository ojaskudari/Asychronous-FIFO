module Read_pointer #( parameter SIZE=4)(
    input r_clk, r_rst_n, r_en,
    input [SIZE:0] s_wr_ptr,  // Corrected name to indicate it's the synchronized write pointer

    output reg r_empty,
    wire [SIZE-1:0] r_addr,
    output reg [SIZE:0] r_ptr
);

wire [SIZE:0] r_bin_nxt, r_gray_nxt;
reg [SIZE:0] r_bin;
wire temp_r_empty;

always @(posedge r_clk or negedge r_rst_n) 
begin
    if (!r_rst_n)
    begin
        r_bin <= 0;
        r_ptr <= 0;
    end
    else
    begin
        r_bin <= r_bin_nxt;
        r_ptr <= r_gray_nxt;  // Fixed incorrect assignment
    end
end

assign r_addr = r_bin[SIZE-1:0];
assign r_bin_nxt = r_bin + (r_en & !r_empty);  // Fixed incorrect control signals

// Instantiate Binary to Gray converter
binary_to_gray b2gr(.bin(r_bin_nxt), .gray(r_gray_nxt));

// Correct FIFO Empty Detection Logic
assign temp_r_empty = (r_ptr == s_wr_ptr);

always @(posedge r_clk or negedge r_rst_n)
begin
    if (!r_rst_n)
        r_empty <= 1'b1;
    else
        r_empty <= temp_r_empty;  // Update correctly
end

endmodule
