module full_network #(
		DATA_BITS=8,
		HEIGHT=28,
		WIDTH=28
)

(					input clk,
					input rst_n,			
					input  wire [DATA_BITS-1:0] data_in,
					input wire valid_in,
					output ready,
					output [3:0] class_out,
					output valid_out_network,
					input  logic calc_weight_en,
					input  logic [5:0] calc_weight_addr,
					input  logic signed [DATA_BITS-1:0] calc_weight_in
					//output wire valid_out_calc
					//output out_valid

);
localparam FILTER_SIZE=7;
logic signed [22:0] conv_out1,conv_out2,conv_out3;
logic maxpool_ready,maxpool_ready1,maxpool_ready2,maxpool_ready3,valid_out_maxpool1,valid_out_maxpool2,valid_out_maxpool3,relu_ready1,relu_ready2,relu_ready3,valid_out_relu1,valid_out_relu2,valid_out_relu3;	
logic signed [22:0] maxpool_out1,maxpool_out2,maxpool_out3,relu_out1,relu_out2,relu_out3;
logic signed [53:0] fc_outputs[9:0];
logic      fc_valids,valid_out_calc;
logic fc_layer_ready,valid_out_relu;
logic [3:0] max_index;
    conv1_layer #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT), .DATA_BITS(DATA_BITS), .FILTER_SIZE(FILTER_SIZE)
    ) conv1 (
        .clk(clk), .rst_n(rst_n), .data_in(data_in), .valid_in(valid_in),
        .ready(ready), .conv_out_1(conv_out1), .conv_out_2(conv_out2),
        .conv_out_3(conv_out3), .valid_out_calc(valid_out_calc),.maxpool_ready(maxpool_ready),
				.calc_weight_en(calc_weight_en),
		.calc_weight_addr(calc_weight_addr),
		.calc_weight_in
    );
	
//Channel 1 Maxpool+ReLU
    maxpool #(
        .BUFFER_SIZE(484),
        .ROW_SIZE(22)
    ) mp_ch1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_calc),
        .maxpool_ready(maxpool_ready1),
        .conv_out(conv_out1),
        .valid_out_maxpool(valid_out_maxpool1),
        .maxpool_out(maxpool_out1),
		.relu_ready(relu_ready1)
    );
	
	    relu ch1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_maxpool1),
        .maxpool_out(maxpool_out1),
        .relu_out(relu_out1),
        .valid_out(valid_out_relu1),
        .relu_ready(relu_ready1),
		.fc_ready(fc_layer_ready)
    );
	
//Channel 2 Maxpool+ReLU	
	   maxpool #(
        .BUFFER_SIZE(484),
        .ROW_SIZE(22)
    ) mp_ch2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_calc),
        .maxpool_ready(maxpool_ready2),
        .conv_out(conv_out2),
        .valid_out_maxpool(valid_out_maxpool2),
        .maxpool_out(maxpool_out2),
		.relu_ready(relu_ready2)
    );
	
	    relu ch2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_maxpool2),
        .maxpool_out(maxpool_out2),
        .relu_out(relu_out2),
        .valid_out(valid_out_relu2),
        .relu_ready(relu_ready2),
		.fc_ready(fc_layer_ready)
    );
//Channel 3 Maxpool+ReLU	
	   maxpool #(
        .BUFFER_SIZE(484),
        .ROW_SIZE(22)
    ) mp_ch3 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_calc),
        .maxpool_ready(maxpool_ready3),
        .conv_out(conv_out3),
        .valid_out_maxpool(valid_out_maxpool3),
        .maxpool_out(maxpool_out3),
		.relu_ready(relu_ready3)
		//.fc_ready(fc_layer_ready)
		
    );
	
	    relu ch3 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_out_maxpool3),
        .maxpool_out(maxpool_out3),
        .relu_out(relu_out3),
        .valid_out(valid_out_relu3),
        .relu_ready(relu_ready3),
		.fc_ready(fc_layer_ready)
    );

assign valid_out_relu=valid_out_relu1&valid_out_relu2&valid_out_relu3;

fc_layer #(
    .WEIGHT_FILE_PREFIX("neuron_weights_"), // Custom prefix for memory files
    .BIAS_FILE("fc_bias.mem")         // Custom bias file
) u_fc_layer_inst (
    .clk         (clk),
    .rst_n       (rst_n),
    .valid_in    (valid_out_relu),
    .relu_out1   (relu_out1),
    .relu_out2   (relu_out2),
    .relu_out3   (relu_out3),
    .fc_outputs  (fc_outputs),    // Connects to the 10x54-bit array
    .fc_valids_out   (fc_valids),
    .layer_ready (fc_layer_ready)
);

    argmax uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(fc_valids),
        .data_in(fc_outputs),
        .max_index(max_index),
        .done(done)
    );

assign maxpool_ready=maxpool_ready1&maxpool_ready2&maxpool_ready3;
assign class_out=max_index;
assign valid_out_network=done;
//assign out_valid=fc_valids;
endmodule