module conv1_layer
    #(
        parameter WIDTH = 28,
                  HEIGHT = 28,
                  DATA_BITS = 8,
				  FILTER_SIZE = 7
				 
    )
(					input clk,
					input rst_n,			
					input  logic [DATA_BITS-1:0] data_in,
					input logic valid_in,
					input maxpool_ready,
					output ready,
					output logic signed [22:0]   conv_out_1,
					output logic signed  [22:0]   conv_out_2,
					output logic signed [22:0]   conv_out_3,
					output logic signed  valid_out_calc,
					input  logic calc_weight_en,
					input  logic [5:0] calc_weight_addr,
					input  logic signed [DATA_BITS-1:0] calc_weight_in
					
					//weight signals are shorted to all conv1_calc inputs for simpler design. Ideally, different conv1_calc blocks should have different weights
					//weight initialization are done within the block

);

logic signed [DATA_BITS:0] data_out [0:FILTER_SIZE*FILTER_SIZE-1];
logic valid_out_buf;
logic ready_calc1;
logic ready_calc2;
logic ready_calc3;
logic ready_buf;
logic valid_out_calc1;
logic valid_out_calc2;
logic valid_out_calc3;


	conv1_buf #(.WIDTH(WIDTH),
                  .HEIGHT(HEIGHT),
                  .DATA_BITS(DATA_BITS),
				  .FILTER_SIZE(FILTER_SIZE)
				  
    )BUF(
		.clk(clk), 
		.rst_n(rst_n), 
		.valid_in(valid_in), 
		.data_in(data_in), 
		.data_out(data_out), 
		.valid_out_buf(valid_out_buf), 
		.buf_ready(ready_buf),
		.calc_ready(ready_calc)
	);



	conv1_calc #(.WIDTH(WIDTH),
                  .HEIGHT(HEIGHT),
                  .DATA_BITS(DATA_BITS),
				  .FILTER_SIZE(FILTER_SIZE),
				  .BIAS_INDEX(0),
				  .WEIGHTMEM("conv1_weight_1.mem"),
				  .BIASMEM("conv1_bias.mem")
    ) CALC_1(
		.clk(clk), 
		.rst_n(rst_n), 
		.valid_out_buf(valid_out_buf), 
		.data_out(data_out), 
		.conv_out_1(conv_out_1), 
		.calc_ready(ready_calc1), 
		.valid_out_calc(valid_out_calc1),
		.maxpool_ready(maxpool_ready),
		.calc_weight_en(calc_weight_en),
		.calc_weight_addr(calc_weight_addr),
		.calc_weight_in(calc_weight_in)
	);
	

conv1_calc #(.WIDTH(WIDTH),
                  .HEIGHT(HEIGHT),
                  .DATA_BITS(DATA_BITS),
				  .FILTER_SIZE(FILTER_SIZE),
				  .BIAS_INDEX(1),
				  .WEIGHTMEM("conv1_weight_2.mem"),
				  .BIASMEM("conv1_bias.mem")
    ) CALC_2(
		.clk(clk), 
		.rst_n(rst_n), 
		.valid_out_buf(valid_out_buf), 
		.data_out(data_out), 
		.conv_out_1(conv_out_2), 
		.calc_ready(ready_calc2), 
		.valid_out_calc(valid_out_calc2),
		.maxpool_ready(maxpool_ready),
		.calc_weight_en(calc_weight_en),
		.calc_weight_addr(calc_weight_addr),
		.calc_weight_in(calc_weight_in)
	);
	
conv1_calc #(.WIDTH(WIDTH),
                  .HEIGHT(HEIGHT),
                  .DATA_BITS(DATA_BITS),
				  .FILTER_SIZE(FILTER_SIZE),
				  .BIAS_INDEX(2),
				  .WEIGHTMEM("conv1_weight_3.mem"),
				  .BIASMEM("conv1_bias.mem")
    ) CALC_3(
		.clk(clk), 
		.rst_n(rst_n), 
		.valid_out_buf(valid_out_buf), 
		.data_out(data_out), 
		.conv_out_1(conv_out_3), 
		.calc_ready(ready_calc3), 
		.valid_out_calc(valid_out_calc3),
		.maxpool_ready(maxpool_ready),
		.calc_weight_en(calc_weight_en),
		.calc_weight_addr(calc_weight_addr),
		.calc_weight_in(calc_weight_in)
	);
	
	
	
	assign ready=ready_buf;
	assign valid_out_calc=valid_out_calc1 &valid_out_calc2&valid_out_calc3; 
	assign ready_calc=ready_calc1 &ready_calc2&ready_calc3;


endmodule