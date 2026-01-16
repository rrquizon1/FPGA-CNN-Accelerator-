module relu(
	    input  logic                 clk,
        input  logic                 rst_n,
        input  logic                 valid_in,
		input logic 					fc_ready,
		input  logic signed [22:0] maxpool_out,
		output  logic signed [22:0] relu_out,
		output logic valid_out,
		output logic relu_ready
	);
	
reg  [3:0] state;localparam READY=0,RELU=1;

	
	always @(posedge clk)begin
		if(rst_n==0)begin
			relu_out<=0;
			valid_out<=0;
			relu_ready<=0;
			state<=READY;
		end
		
		else begin
			if(fc_ready==1)begin 
			case(state)
				READY:begin
					relu_ready<=1;
					state<=RELU;
				end
				
				RELU:begin
					if(valid_in)begin
						if(maxpool_out[22]==1)begin
							relu_out<=0;
							
						end
						
						else begin
							relu_out<=maxpool_out;
						end
						valid_out<=1;
					end
					
					else begin
						valid_out<=0;
					end
					
				end
			
			
			endcase
			end
			
		end
		
		
	end




endmodule