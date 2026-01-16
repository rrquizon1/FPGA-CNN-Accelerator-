`timescale 1ns / 1ps

module relu_tb;

    // Inputs
    logic clk;
    logic rst_n;
    logic valid_in;
    logic signed [22:0] maxpool_out;

    // Outputs
    logic signed [22:0] relu_out;
    logic valid_out;
    logic relu_ready;

    // Instantiate the Unit Under Test (UUT)
    relu uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .maxpool_out(maxpool_out),
        .relu_out(relu_out),
        .valid_out(valid_out),
        .relu_ready(relu_ready),
		.fc_ready(1)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        maxpool_out = 0;

        // Reset
        #20;
        rst_n = 1;
        
        // Wait for module to be ready
        wait(relu_ready == 1);
        @(posedge clk);

        // --- Test Case 1: Positive Number ---
        $display("Test 1: Positive Number (500)");
        valid_in = 1;
        maxpool_out = 23'sd500;
        @(posedge clk);
        valid_in = 0; 
        @(posedge clk); // Wait for pipeline latency
        if (valid_out && relu_out == 500) $display("PASS: Output is 500");
        else $display("FAIL: Expected 500, got %d", relu_out);

        // --- Test Case 2: Negative Number ---
        $display("Test 2: Negative Number (-300)");
        valid_in = 1;
        maxpool_out = -23'sd300;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        if (valid_out && relu_out == 0) $display("PASS: Output is 0 (Clipped)");
        else $display("FAIL: Expected 0, got %d", relu_out);

        // --- Test Case 3: Zero ---
        $display("Test 3: Zero (0)");
        valid_in = 1;
        maxpool_out = 23'sd0;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        if (valid_out && relu_out == 0) $display("PASS: Output is 0");

        // --- Test Case 4: Non-continuous data (The "Stutter" test) ---
        $display("Test 4: Stuttering Inputs");
        @(posedge clk);
        
        valid_in = 1; maxpool_out = 23'sd10; // Data A
        @(posedge clk);
        
        valid_in = 0; maxpool_out = 23'sd99; // Gap (This 99 should be ignored)
        @(posedge clk);
        
        valid_in = 1; maxpool_out = -23'sd20; // Data B
        @(posedge clk);
        
        valid_in = 0;
        @(posedge clk);
        @(posedge clk);

        $display("Simulation Complete.");
        $finish;
    end

    // Monitor outputs in real-time
    initial begin
        $monitor("Time=%0t | valid_in=%b | in=%d | valid_out=%b | out=%d", 
                 $time, valid_in, maxpool_out, valid_out, relu_out);
    end

endmodule