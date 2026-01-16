module fc_layer #(
    parameter WEIGHT_FILE_PREFIX = "neuron_weights_", // Example: neuron_weights_0.mem, etc.
    parameter BIAS_FILE = "test_bias.mem"
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic signed [22:0] relu_out1,
    input  logic signed [22:0] relu_out2,
    input  logic signed [22:0] relu_out3,
    output logic signed [53:0] fc_outputs[9:0], // Array of 10 outputs
    output logic        fc_valids_out,  // Individual valid signals
    output logic             layer_ready
);

logic [9:0] fc_valids;
logic [9:0] fc_ready;
    // Generate 10 neurons
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : neuron_block
            neuron #(
                .WEIGHTMEM({WEIGHT_FILE_PREFIX, 8'(i + 48), ".mem"}), // Dynamic file naming (i+48 converts 0 to ASCII '0')
                .BIASMEM(BIAS_FILE),
                .BIAS_INDEX(i)
            ) n_inst (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(valid_in),
                .relu_out_1(relu_out1),
                .relu_out_2(relu_out2),
                .relu_out_3(relu_out3),
                .fc_out(fc_outputs[i]),
                .valid_out(fc_valids[i]),
                .fc_ready(fc_ready[i]) // We can use the first one to drive layer_ready
            );
        end
    endgenerate

    // The layer is ready when the neurons are ready
    // We can just track the first one since they are in sync
//assign layer_ready = neuron_block[0].n_inst.fc_ready;
	assign fc_valids_out=&fc_valids;
	assign layer_ready=&fc_ready;

endmodule