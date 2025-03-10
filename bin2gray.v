module bin2gray #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] bin,   // Binary input
    output [WIDTH-1:0] gray   // Gray code output
);

    assign gray = (bin >> 1) ^ bin;  // Convert binary to Gray code

endmodule
