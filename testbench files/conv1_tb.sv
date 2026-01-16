`timescale 1ns / 1ps

module tb_conv1_buf();

    // Parameters
    parameter WIDTH = 28;
    parameter HEIGHT = 28;
    parameter DATA_BITS = 8;
    parameter FILTER_SIZE = 7;
    parameter CLK_PERIOD = 10; 

    // Signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic [DATA_BITS-1:0] data_in;
    
    logic signed [DATA_BITS:0] data_out [0:FILTER_SIZE*FILTER_SIZE-1]; 
    logic valid_out_buf;
    logic ready_in;
	logic ready_out;
	
	    integer error_count = 0;
    integer win_count = 0;
    logic state_is_done = 0;

    // Instantiate UUT
    conv1_buf #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .DATA_BITS(DATA_BITS), .FILTER_SIZE(FILTER_SIZE)
    ) uut (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in), .data_in(data_in),
        .valid_out_buf(valid_out_buf),
        .buf_ready(ready_in), .data_out(data_out)
		,.calc_ready(ready_out)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- PART 1: Data Feeding Logic ---
    initial begin
        clk = 0; rst_n = 0; valid_in = 0;data_in = 0; ready_out=0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
       
		#100
		ready_out=1;
		#100
        wait(ready_in == 1);
        $display("[%0t] System Ready. Feeding Image...", $time);

        for (int p = 0; p < (WIDTH * HEIGHT); p = p + 1) begin
            @(posedge clk); 
            valid_in <= 1;
            data_in  <= p[7:0]; // Data is simply the pixel index
        end

        @(posedge clk);
        valid_in <= 0;
        data_in  <= 0;

        // Wait for the checker to finish all windows
        wait(valid_out_buf == 0 && state_is_done); 
        
        $display("---------------------------------------");
        $display("Simulation Finished.");
        $display("Total Windows Checked: %0d", win_count);
        $display("Total Errors Found:    %0d", error_count);
        $display("---------------------------------------");
        $finish;
    end

    // --- PART 2: Verification Logic ---


    initial begin
        // Wait for the first valid output window
        wait(valid_out_buf == 1);
        
        // There are (28-7+1) * (28-7+1) = 22 * 22 = 484 total windows
        for (int h = 0; h <= (HEIGHT - FILTER_SIZE); h++) begin
            for (int w = 0; w <= (WIDTH - FILTER_SIZE); w++) begin
                
                // Wait for the clock edge where this window is valid
                @(posedge clk);
                if (valid_out_buf) begin
                    win_count++;
                    
                    // Check every pixel in the 7x7 window
                    for (int r = 0; r < FILTER_SIZE; r++) begin
                        for (int c = 0; c <  FILTER_SIZE; c++) begin
                            // Calculate what the pixel value SHOULD be
                            // Based on: Index = (Current_Row * WIDTH) + Current_Col
                            automatic logic [7:0] expected_val = ((h + r) * WIDTH + (w + c)) % 256;
                            
                            if (data_out[r*FILTER_SIZE + c] !== expected_val) begin
                                $display("[%0t] ERROR: Win %0d | Pixel[%0d][%0d] | Exp: %0d, Got: %0d", 
                                         $time, win_count, r, c, expected_val, data_out[r*7 + c]);
                                error_count++;
                            end
                        end
                    end
                end
            end
        end
        state_is_done = 1;
    end

endmodule