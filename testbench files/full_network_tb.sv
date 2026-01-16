`timescale 1ns / 1ps

module full_network_tb;

    parameter DATA_BITS = 8;
    parameter HEIGHT = 28;
    parameter WIDTH = 28;
    parameter CLK_PERIOD = 10;
    localparam TOTAL_PIXELS = HEIGHT * WIDTH;

    logic clk, rst_n, valid_in, ready, valid_out_network;
    logic [DATA_BITS-1:0] data_in;
    logic [3:0] class_out;

    // Buffer to hold one image at a time
    logic [DATA_BITS-1:0] image_mem [0:TOTAL_PIXELS-1];
    string file_name; // Variable to store the dynamic filename

    full_network #(
        .DATA_BITS(DATA_BITS), .HEIGHT(HEIGHT), .WIDTH(WIDTH)
    ) dut (
        .clk(clk), .rst_n(rst_n), .data_in(data_in),
        .valid_in(valid_in), .ready(ready),
        .class_out(class_out), .valid_out_network(valid_out_network)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        // Initial Reset
        rst_n = 0;
        data_in = 0;
        valid_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;

        // Loop from 0 to 9
        for (int img_idx = 0; img_idx <= 9; img_idx++) begin
            
            // 1. Generate filename and load memory
            file_name = $sformatf("%0d_0.txt", img_idx);
            $display("\n--- Loading File: %s ---", file_name);
            $readmemh(file_name, image_mem);

            // 2. Reset the internal state for the new image
            rst_n = 0;
            #(CLK_PERIOD * 2);
            rst_n = 1;
            wait(ready == 1); // Wait for buffer to be ready

            // 3. Feed the image pixels
            for (int i = 0; i < TOTAL_PIXELS; i++) begin
                while (ready !== 1'b1) begin
                    valid_in <= 0;
                    @(posedge clk);
                end

                valid_in <= 1;
                data_in  <= image_mem[i];
                @(posedge clk);
            end
				 @(posedge clk);
            // 4. Clean up after transmission
            valid_in <= 0;
            data_in  <= 0;
            $display("--- Image %0d Feed Complete. Waiting for Inference... ---", img_idx);

            // 5. Wait for the network to finish (using your valid_out_network)
            wait(valid_out_network == 1);
            
            // Allow a few cycles for signals to settle before printing
            #(CLK_PERIOD * 2);

            $display("--- Result for %s ---", file_name);
            for (int k = 0; k < 10; k++) begin
                $display("Class %0d Output: %d", k, $signed(dut.fc_outputs[k]));
            end
            $display(">>> Network Prediction: %0d", class_out);

            // Small delay between images
            #(CLK_PERIOD * 20);
        end

        $display("\n--- All 10 Images Processed. Simulation Finished. ---");
        $finish;
    end

endmodule
