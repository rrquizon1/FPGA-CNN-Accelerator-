`timescale 1ns/1ps

module tb_argmax();

    // Inputs
    logic clk;
    logic rst_n;
    logic valid_in;
    logic signed  [53:0] data_in [9:0];

    // Outputs
    logic [3:0] max_index;
    logic done;

    // Instantiate the Unit Under Test (UUT)
    argmax uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .max_index(max_index),
        .done(done)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        for(int i=0; i<10; i++) data_in[i] = 0;

        // Reset the system
        #20 rst_n = 1;
        #10;

        // --- TEST CASE 1: Simple Positive Winner ---
        // Let's make index 3 the winner
        $display("Test 1: Index 3 is the winner (Positive Values)");
        data_in[0] = 54'd10;
        data_in[1] = 54'd20;
        data_in[2] = 54'd5;
        data_in[3] = 54'd100; // Winner
        data_in[4] = 54'd50;
        data_in[5] = 54'd12;
        data_in[6] = 54'd80;
        data_in[7] = 54'd45;
        data_in[8] = 54'd1;
        data_in[9] = 54'd99;
        valid_in = 1;
        #10 valid_in = 0; // Pulse valid for 1 cycle

        // Wait for 'done' signal
        wait(done);
        #1; // Offset to see values clearly
        $display("Result: max_index = %d (Expected: 3)", max_index);
        if (max_index == 3) $display(">>> SUCCESS!");
        else                $display(">>> FAILED!");

        #50;

       // --- TEST CASE 2: Negative Values (Crucial for Signed Logic) ---
        // Let's make index 7 the winner (least negative)
        $display("\nTest 2: Index 7 is the winner (Negative Values)");
        for(int i=0; i<10; i++) data_in[i] = -54'd1000; // All very negative
        data_in[7] = -54'd5; // Winner (closest to zero)
        valid_in = 1;
        #10 valid_in = 0;

        wait(done);
        #1;
        $display("Result: max_index = %d (Expected: 7)", max_index);
        if (max_index == 7) $display(">>> SUCCESS!");
        else                $display(">>> FAILED!");

        #50;

        // --- TEST CASE 3: Throughput Test (Continuous Data) ---
        // Sending data every cycle to see the pipeline in action
        $display("\nTest 3: Continuous Data (Pipeline Throughput)");
        valid_in = 1;
        data_in[0] = 54'd500; // Winner 0
        #10 data_in[0] = 0; data_in[1] = 54'd500; // Winner 1
        #10 data_in[1] = 0; data_in[2] = 54'd500; // Winner 2
        #10 data_in[2] = 0; data_in[3] = 54'd500; // Winner 3
        #10 valid_in = 0;

        // Monitoring the outputs for the next few cycles
        repeat(8) begin
            @(posedge clk);
            if(done) $display("Cycle T%0t: Result Index = %d", $time, max_index);
        end

        #100 $finish;
    end

endmodule