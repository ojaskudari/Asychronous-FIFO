module Write_pointer #(parameter SIZE=4)(
    input w_clk, w_rst_n, w_en,
    input [SIZE:0] s_rd_ptr,
    output reg w_full,
    output [SIZE-1:0] w_addr,
    output reg [SIZE:0] w_ptr
);

wire [SIZE:0] w_bin_nxt, w_gray_nxt;
reg [SIZE:0] w_bin;
wire temp_w_full;

always @(posedge w_clk or negedge w_rst_n) begin
    if (!w_rst_n) begin
        w_bin <= 0;
        w_ptr <= 0;
    end
    else begin
        w_bin <= w_bin_nxt;
        w_ptr <= w_gray_nxt;
    end
end

assign w_addr = w_bin[SIZE-1:0];
assign w_bin_nxt = w_bin + (w_en & !w_full);

// Binary to Gray converter
binary_to_gray b2gW(.bin(w_bin_nxt), .gray(w_gray_nxt));

// FIXED: Correct FIFO Full Detection Logic
assign temp_w_full = (w_gray_nxt == {~s_rd_ptr[SIZE:SIZE-1], s_rd_ptr[SIZE-2:0]});

always @(posedge w_clk or negedge w_rst_n) begin
    if (!w_rst_n)
        w_full <= 1'b0;
    else
        w_full <= temp_w_full;
end

endmodule
