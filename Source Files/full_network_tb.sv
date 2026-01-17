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
/*
`timescale 1ns / 1ps

module full_network_tb;

    // --- Parameters ---
    parameter DATA_BITS = 8;
    parameter HEIGHT    = 28;
    parameter WIDTH     = 28;
    parameter CLK_PERIOD = 10;
    localparam TOTAL_PIXELS = HEIGHT * WIDTH;
    localparam NUM_IMAGES   = 20; // You can increase this up to 1000

    // --- Signals ---
    logic clk, rst_n, valid_in, ready, valid_out_network;
    logic [DATA_BITS-1:0] data_in;
    logic [3:0] class_out;

    // --- Memory for Dataset ---
    // Holds 1000 images * 784 pixels each
    logic [DATA_BITS-1:0] global_mem [0:(1000 * TOTAL_PIXELS)-1];
    integer image_offset;

    // --- Device Under Test (DUT) ---
    full_network #(
        .DATA_BITS(DATA_BITS), 
        .HEIGHT(HEIGHT), 
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .data_in(data_in),
        .valid_in(valid_in), 
        .ready(ready),
        .class_out(class_out), 
        .valid_out_network(valid_out_network)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- Main Test Logic ---
    initial begin
        // 1. Load the massive dataset once at the start
        // Ensure input_1000.txt is in the simulation folder
        $display("--- Loading Global Dataset: input_1000.txt ---");
        $readmemh("input_1000.txt", global_mem);

        // Initial System Reset
        rst_n = 0;
        data_in = 0;
        valid_in = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;

        // 2. Loop through images
        for (int img_idx = 0; img_idx < NUM_IMAGES; img_idx++) begin
            
            // Calculate starting index for this image in the .txt file
            image_offset = img_idx * TOTAL_PIXELS;
            $display("\n--- Starting Inference: Image %0d (Index: %0d) ---", img_idx, image_offset);

            // 3. Reset internal state/buffers for the new image
            // This ensures convolution line buffers and accumulators are cleared
            rst_n = 0;
            #(CLK_PERIOD * 2);
            rst_n = 1;
            
            // Wait for the hardware to signal it can accept data
            wait(ready == 1); 

            // 4. Feed the 784 pixels
            for (int i = 0; i < TOTAL_PIXELS; i++) begin
                // Flow control: Wait if the hardware back-pressures (ready goes low)
                while (ready !== 1'b1) begin
                    valid_in <= 0;
                    @(posedge clk);
                end

                valid_in <= 1;
                data_in  <= global_mem[image_offset + i]; 
                @(posedge clk);
            end

            // 5. Cleanup transmission
			 @(posedge clk);
            valid_in <= 0;
            data_in  <= 0;
            $display("--- Image %0d Feed Complete. Waiting for valid_out_network... ---", img_idx);

            // 6. Wait for the Argmax/Output stage to finish
            wait(valid_out_network == 1);
            
            // Brief pause for signal stability in waveform
            #(CLK_PERIOD * 2);

            // 7. Display Results
            $display("--- Results for Image %0d ---", img_idx);
            // Accessing internal signals for debugging scores
            for (int k = 0; k < 10; k++) begin
                $display("  Class %0d Score: %d", k, $signed(dut.fc_outputs[k]));
            end
            $display(">>> FINAL NETWORK PREDICTION: %0d", class_out);

            // Delay between images to clearly separate them in the waveform
            #(CLK_PERIOD * 20);
        end

        $display("\n--- Processed %0d images. Simulation Finished. ---", NUM_IMAGES);
        $finish;
    end

endmodule
*/
