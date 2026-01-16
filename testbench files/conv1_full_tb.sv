`timescale 1ns / 1ps

module tb_conv1_layer();

    parameter WIDTH = 28;
    parameter HEIGHT = 28;
    parameter DATA_BITS = 8;
    parameter FILTER_SIZE = 7;
    parameter TOTAL_INPUTS = WIDTH * HEIGHT; // 784
    parameter OUT_WIDTH = WIDTH - FILTER_SIZE + 1; // 22
    parameter TOTAL_OUTPUTS = OUT_WIDTH * OUT_WIDTH; // 484

    reg clk;
    reg rst_n;
    reg [DATA_BITS-1:0] data_in;
    reg valid_in;
    
    wire ready;
    wire [22:0] conv_out_1, conv_out_2, conv_out_3;
    wire valid_out_calc;

    // 1. DUT Instance
    conv1_layer #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT), .DATA_BITS(DATA_BITS), .FILTER_SIZE(FILTER_SIZE)
    ) dut (
        .clk(clk), .rst_n(rst_n), .data_in(data_in), .valid_in(valid_in),
        .ready(ready), .conv_out_1(conv_out_1), .conv_out_2(conv_out_2),
        .conv_out_3(conv_out_3), .valid_out_calc(valid_out_calc),.maxpool_ready(1)
    );

    always #5 clk = ~clk;

    // 2. Monitoring logic to track output count and values
    integer out_count = 0;
    always @(posedge clk) begin
        if (valid_out_calc) begin
            out_count <= out_count + 1;
            $display("Time: %0t | Out #%0d | Ch1: %d | Ch2: %d | Ch3: %d", 
                      $time, out_count + 1, conv_out_1, conv_out_2, conv_out_3);
        end
    end

    // 3. Stimulus Block
    integer i;
    initial begin
        // Initialize
        clk = 0; rst_n = 0; valid_in = 0; data_in = 0;
        
        // Reset
        #20 rst_n = 1;
        repeat(5) @(posedge clk);

        $display("--- Starting Sequential Data Input (0 to 255 wrap) ---");
        
        for (i = 0; i < TOTAL_INPUTS; i = i + 1) begin
            @(posedge clk);
            // Check back-pressure (ready signal)
            while (!ready) begin
                valid_in = 0;
                @(posedge clk);
            end
            
            valid_in = 1;
            data_in = i % 256; // Sequential 0, 1, 2 ... 255, 0, 1 ...
        end

        // Finish feeding
        @(posedge clk);
        valid_in = 0;
        data_in = 0;

        // 4. Wait for all 484 pixels to be calculated
        wait(out_count == TOTAL_OUTPUTS);
        
        repeat(10) @(posedge clk);
        $display("--- Simulation Finished ---");
        $display("Total Pixels Processed: %d", out_count);
        $finish;
    end

endmodule
/*module tb_conv1_layer();

    // 1. Parameters for a 7x7 test
    parameter WIDTH = 7;
    parameter HEIGHT = 7;
    parameter DATA_BITS = 8;
    parameter FILTER_SIZE = 7;

    reg clk;
    reg rst_n;
    reg [DATA_BITS-1:0] data_in;
    reg valid_in;
    
    wire ready;
    wire [22:0] conv_out_1;
    wire [22:0] conv_out_2;
    wire [22:0] conv_out_3;
    wire valid_out_calc;

    // 2. Instantiate DUT
    conv1_layer #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .DATA_BITS(DATA_BITS),
        .FILTER_SIZE(FILTER_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .ready(ready),
        .conv_out_1(conv_out_1),
        .conv_out_2(conv_out_2),
        .conv_out_3(conv_out_3),
        .valid_out_calc(valid_out_calc)
    );

    // 3. Clock Generation (10ns period)
    always #5 clk = ~clk;

    // 4. Stimulus
    integer i;
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;

        // Reset
        #20 rst_n = 1;
        repeat(5) @(posedge clk);

        // Feed 49 Pixels
        $display("--- Starting Data Input ---");
        for (i = 0; i < (WIDTH * HEIGHT); i = i + 1) begin
            @(posedge clk);
            wait(ready); // Wait until the buffer is ready for data
            
            valid_in = 1;
            data_in = i; // Pixels: 0, 1, 2 ... 48
            $display("Feeding Pixel %d: Value = %d", i, data_in);
        end

        // End of Input
        @(posedge clk);
        valid_in = 0;
        data_in = 0;

        // 5. Wait for the Output
        $display("--- Waiting for Convolution Result ---");
        // We expect valid_out_calc to trigger after the 49th pixel is processed
        wait(valid_out_calc == 1);
        
        @(posedge clk);
        $display("SUCCESS: Calculation Complete!");
        $display("Final Result Channel 1 (Sum of 0 to 48): %d", conv_out_1);
        $display("Final Result Channel 2(Sum of 0 to 48): %d", conv_out_2);
        $display("Final Result Channel 3(Sum of 0 to 48): %d", conv_out_3);
        
        if (conv_out_1 == 1177) 
            $display("PASSED: 1176 is the correct sum.");
        else 
            $display("FAILED: Expected 1176, got %d", conv_out_1);

        #100;
        $finish;
    end

endmodule*/