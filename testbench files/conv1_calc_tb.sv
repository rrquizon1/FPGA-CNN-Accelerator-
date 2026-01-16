`timescale 1ns/1ps

module tb_conv1_calc();
    // Parameters
    parameter DATA_BITS = 8;
    parameter FILTER_SIZE = 7;

    // Clock and Reset
    reg clk;
    reg rst_n;
    reg valid_out_buf;
    reg signed [DATA_BITS:0]  data_in [0:FILTER_SIZE*FILTER_SIZE-1];
    
    // Outputs from UUT
    wire signed [22:0] conv_out_1;
    wire ready_in;
    wire valid_out_calc;

    // Instantiate the Unit Under Test (UUT)
    conv1_calc #(
        .DATA_BITS(DATA_BITS),
        .FILTER_SIZE(FILTER_SIZE),
		.BIAS_INDEX(1),
		.WEIGHTMEM("conv1_weight_1_all1s.mem"),
		.BIASMEM("conv1_bias_all1s.mem")
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_out_buf(valid_out_buf),
        .data_out(data_in),
        .conv_out_1(conv_out_1),
        .calc_ready(ready_in),
        .valid_out_calc(valid_out_calc),
		.maxpool_ready(1)
    );

    // Clock Generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    integer i;
    initial begin
        // Initialize Signals
        clk = 0;
        rst_n = 0;
        valid_out_buf = 0;
        for(i=0; i<49; i=i+1) data_in[i] = 0;

        // Release Reset
        #20 rst_n = 1;
        #20;

        // --- TEST CASE 1: All Inputs = 1 ---
        // If your weights are all 1 and bias is 0, output should be 49.
        wait(ready_in == 1); // Ensure module is ready
        for(i=0; i<49; i=i+1) data_in[i] = 8'd1; 
        valid_out_buf = 1;
        #10;
       // valid_out_buf = 0; // Pulse valid for 1 cycle
		


        // Wait for the pipeline to finish (6 cycles)
        wait(valid_out_calc == 1);
        $display("Test Case 1 Result: %d (Expected: 50)", conv_out_1);

        #100;
        $finish;
    end
endmodule