`timescale 1ns / 1ps

module fc_layer_tb();

    // Signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic [22:0] relu_out1, relu_out2, relu_out3;
    logic signed[53:0] fc_outputs[9:0];
    logic [9:0] fc_valids;
    logic layer_ready;

    // Instantiate Device Under Test (DUT)
    fc_layer dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .relu_out1(relu_out1),
        .relu_out2(relu_out2),
        .relu_out3(relu_out3),
        .fc_outputs(fc_outputs),
       // .fc_valids(fc_valids),
        .layer_ready(layer_ready)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        relu_out1 = 0;
        relu_out2 = 0;
        relu_out3 = 0;

        // Reset Pulse
        #20 rst_n = 1;

        // Wait for layer to be ready
        wait(layer_ready == 1);
        @(posedge clk);

        // Feed 121 cycles of data (All 1s)
        $display("--- Starting Input Feed: All 1s ---");
        repeat(121) begin
            valid_in = 1;
            relu_out1 = 23'd1;
            relu_out2 = 23'd1;
            relu_out3 = 23'd1;
            @(posedge clk);
        end

        // Clear valid_in and wait for result
        valid_in = 0;
        
        // Wait for the valid_out signal from the neurons
        wait(fc_valids[0] == 1);
        
        // Display Results
        #1; // Small delay to let signals settle for display
        $display("--- Final Results ---");
        for (int j = 0; j < 10; j++) begin
            $display("Neuron %0d: Expected=%0d, Got=%0d", j, 364*(j+1), fc_outputs[j]);
            if (fc_outputs[j] == 364*(j+1)) 
                $display("Neuron %0d: PASS", j);
            else 
                $display("Neuron %0d: FAIL", j);
        end

        #100;
        $finish;
    end

endmodule