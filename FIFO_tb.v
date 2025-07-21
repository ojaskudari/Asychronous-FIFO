`timescale 1ns / 1ps

module FIFO_tb ;

    // Parameters
    parameter DATA_WIDTH = 128;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = 1 << ADDR_WIDTH;  // 16 entries

    // Testbench signals
    reg w_clk, r_clk;
    reg w_rst_n, r_rst_n;
    reg w_en, r_en;
    reg [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire w_full, r_empty;

    // Test data storage (for verification)
    reg [DATA_WIDTH-1:0] written_data [0:FIFO_DEPTH-1];
    integer write_counter, read_counter;

    // Instantiate FIFO
    FIFO_top #(
        .data(DATA_WIDTH),
        .addr(ADDR_WIDTH)
    ) fifo_inst (
        .w_clk(w_clk),
        .r_clk(r_clk),
        .w_rst_n(w_rst_n),
        .r_rst_n(r_rst_n),
        .w_en(w_en),
        .r_en(r_en),
        .wdata(wdata),
        .rdata(rdata),
        .w_full(w_full),
        .r_empty(r_empty)
    );

    // Clock generation
    initial begin
        w_clk = 0;
        forever #5 w_clk = ~w_clk;  // 100MHz write clock
    end

    initial begin
        r_clk = 0;
        forever #10 r_clk = ~r_clk; // 50MHz read clock
    end

    // Main test sequence
    initial begin
        // Initialize signals
        w_rst_n = 0;
        r_rst_n = 0;
        w_en = 0;
        r_en = 0;
        wdata = 0;
        write_counter = 0;
        read_counter = 0;

        // Reset sequence
        #20;
        w_rst_n = 1;
        r_rst_n = 1;
        #20;

        // --------------------------------------------------
        // Test 1: Sequential write followed by read
        // --------------------------------------------------
        $display("\n=== TEST 1: Basic write/read operation ===");
        
        // Write known values (1-16)
        w_en = 1;
        for(write_counter=0; write_counter<FIFO_DEPTH; write_counter=write_counter+1) begin
            wdata = write_counter + 1;  // Simple incrementing pattern
            written_data[write_counter] = wdata;
            @(posedge w_clk);
            $display("[WRITE] Data=%0d (w_full=%b)", wdata, w_full);
            
            // Verify w_full behavior
            if((write_counter == FIFO_DEPTH-1) && !w_full) begin
                $display("ERROR: w_full not asserted at end of write sequence");
            end
        end
        w_en = 0;
        
        // Verify full flag
        if(w_full) $display("SUCCESS: w_full asserted after %0d writes", FIFO_DEPTH);
        else $display("ERROR: w_full not asserted after %0d writes", FIFO_DEPTH);

        // Read all data
        r_en = 1;
        for(read_counter=0; read_counter<FIFO_DEPTH; read_counter=read_counter+1) begin
            @(posedge r_clk);
            $display("[READ] Data=%0d (r_empty=%b)", rdata, r_empty);
            
            // Data verification
            if(rdata !== written_data[read_counter]) begin
                $display("ERROR: Data mismatch! Expected=%0d, Received=%0d",
                        written_data[read_counter], rdata);
            end
        end
        r_en = 0;

        // Verify empty flag
        if(r_empty) $display("SUCCESS: r_empty asserted after %0d reads", FIFO_DEPTH);
        else $display("ERROR: r_empty not asserted after %0d reads", FIFO_DEPTH);

        // --------------------------------------------------
        // Test 2: Simultaneous read/write
        // --------------------------------------------------
        $display("\n=== TEST 2: Concurrent read/write ===");
        fork
            begin // Writer
                w_en = 1;
                for(write_counter=0; write_counter<FIFO_DEPTH; write_counter=write_counter+1) begin
                    wdata = 100 + write_counter;  // New pattern: 100-115
                    written_data[write_counter] = wdata;
                    @(posedge w_clk);
                    $display("[WRITE] Data=%0d (w_full=%b)", wdata, w_full);
                end
                w_en = 0;
            end
            
            begin // Reader
                r_en = 1;
                for(read_counter=0; read_counter<FIFO_DEPTH; read_counter=read_counter+1) begin
                    @(posedge r_clk);
                    $display("[READ] Data=%0d (r_empty=%b)", rdata, r_empty);
                    
                    // Data verification
                    if(rdata !== written_data[read_counter]) begin
                        $display("ERROR: Data mismatch! Expected=%0d, Received=%0d",
                                written_data[read_counter], rdata);
                    end
                end
                r_en = 0;
            end
        join

        // --------------------------------------------------
        // Test 3: Reset behavior
        // --------------------------------------------------
        $display("\n=== TEST 3: Reset verification ===");
        w_rst_n = 0;
        r_rst_n = 0;
        #20;
        w_rst_n = 1;
        r_rst_n = 1;
        #20;

        // Verify post-reset state
        if(r_empty) $display("SUCCESS: r_empty asserted after reset");
        else $display("ERROR: r_empty not asserted after reset");
        
        if(!w_full) $display("SUCCESS: w_full deasserted after reset");
        else $display("ERROR: w_full still asserted after reset");

        // Final cleanup
        #100;
        $display("\nTESTBENCH COMPLETED SUCCESSFULLY");
        $finish;
    end

    // Monitor critical signals
    initial begin
        $monitor("Time=%0t | w_en=%b | r_en=%b | wdata=%0d | rdata=%0d | w_full=%b | r_empty=%b",
                 $time, w_en, r_en, wdata, rdata, w_full, r_empty);
    end

endmodule
