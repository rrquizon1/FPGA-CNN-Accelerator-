module neuron#(
		WEIGHTMEM=" ",
		BIASMEM= " ",
		BIAS_INDEX=0
)


(//Need tos cale things
	    input  logic                 clk,
        input  logic                 rst_n,
        input  logic                 valid_in,
		input  logic signed [22:0] relu_out_1,
		input  logic signed [22:0] relu_out_2,
		input  logic signed [22:0] relu_out_3,
		output  logic signed [53:0] fc_out,
		output logic valid_out,
		output logic fc_ready
);

	 logic signed [7:0] weight [0:362]; //weight	
	 logic signed [7:0] bias [0:9]; //bias unpacked array
	 
	initial begin
      //  $readmemh("conv1_weight_1_all1s.mem", weight);
       $readmemh(WEIGHTMEM, weight);
       // $readmemh("conv1_bias_all1s.mem", bias);
        $readmemh(BIASMEM, bias);
    end	
	
logic  [3:0] state;
logic	 [15:0] fc_index;
logic signed [53:0]  tmp_out;
localparam READY=0,COMPUTATION=1;

always @(posedge clk)begin
	if(rst_n==0)begin
			//valid_out<=0;
			fc_ready<=0;
			state<=READY;
		
	end
	
	else begin 
		case(state)
			READY:begin
				state<=COMPUTATION;
				fc_ready<=1;
				valid_out<=0;
				fc_index<=0;
				tmp_out<=0;
				
			end
			
			COMPUTATION:begin
				if(fc_index<121)begin
					if (valid_in==1)begin
						fc_index<=fc_index+1;
						tmp_out<=tmp_out+weight[fc_index]*relu_out_1+weight[121+fc_index]*relu_out_2+weight[242+fc_index]*relu_out_3;
					end
				end
				
				else begin
					valid_out<=1;
					fc_out<=tmp_out+bias[BIAS_INDEX];
					state<=READY;
					tmp_out<=0;
					fc_index<=0;
				end
				
				
			end
			
			
			
		endcase
		
		
	end
	
	
	
	
	
	
end


endmodule