module read_pointer #(parameter SIZE = 4)
(
  input   read_clock,
  input   read_reset_n,
  input   [SIZE:0]read_pointer_grey,

  output  read_empty,
  output  [SIZE-1:0]read_address,
  output  [SIZE:0] read_pointer
);

wire [SIZE:0] read_pointer_binary;
wire [SIZE :0] read_pointer_binary_next;
wire [SIZE :0] read_pointer_grey_next;
wire temp_read_empty;


always@(posedge clk or negedge reset_n)
begin 
      if(!reset_n)
      {read_pointer_binary,read_pointer}=0;
      else
      {read_pointer_binary,read_pointer}=read_pointer_binary_next,read_pointer_grey_next;
end

assign read_address = read_pointer_binary[SIZE-1:0];
assign read_pointer_binary_next = read_pointer_binary + (read_inc & ~read_empty); 

bin2gray #(SIZE) read_bin2gray(.bin(read_pointer_binary_next),.gray(read_pointer_grey_next));


assign temp_read_empty = (read_pointer_grey_next == read_pointer_binary);


always@(posedge clk or negedge reset_n)
begin 
      if(!reset_n)
      read_empty<=0;
      else
      read_empty<=temp_read_empty;
end
endmodule
