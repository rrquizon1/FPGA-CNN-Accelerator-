module conv1_calc 
#(//need to scale things
        parameter WIDTH = 28,
                  HEIGHT = 28,
                  DATA_BITS = 8,
				  FILTER_SIZE=7,
				  BIAS_INDEX=0,
				  WEIGHTMEM=" ",
				  BIASMEM= " "
    )
    (
        input  logic                 clk,
        input  logic                 rst_n,
        input  logic                 valid_out_buf,
		input logic signed [DATA_BITS:0] data_out [0:FILTER_SIZE*FILTER_SIZE-1],
        output logic signed [22:0]   conv_out_1,
		output logic					calc_ready,
        output logic                valid_out_calc,
		input logic 					maxpool_ready,
		input  logic calc_weight_en,
		input  logic [5:0] calc_weight_addr,
		input  logic signed [DATA_BITS-1:0] calc_weight_in
    );
	
	 logic signed [DATA_BITS-1:0] weight_1 [0:FILTER_SIZE*FILTER_SIZE-1]; //weight	
	 logic signed [DATA_BITS-1:0] bias [0:3]; //bias unpacked array
	 
	 logic signed [22:0] calc_tmp [0:49];//tmp variable pipelined
	 
	 logic calc_done [0:4];//temp calc done 
	 
	 logic signed [DATA_BITS:0] exp_data [0:FILTER_SIZE*FILTER_SIZE-1];
	 logic signed [22:0] exp_bias [0:0];
	 
	 // Unsigned -> Signed for data input Use for loop to simplify coding
	 generate
		genvar i;
			for (i = 0; i < FILTER_SIZE*FILTER_SIZE; i=i+1) begin
				assign exp_data[i] ={1'd0,data_out[i]};
			end
	  endgenerate

	 //expanded bias first element only
	 assign exp_bias[0]=(bias[0][7]==1)? {15'b111111111111111,bias[BIAS_INDEX]} : {15'b000000000000000,bias[BIAS_INDEX]};
	
// This block makes weight_1 look like a writable memory
    // The synthesizer can no longer assume the weights are constant
    always @(posedge clk) begin
        if (calc_weight_en) begin
            weight_1[calc_weight_addr] <= calc_weight_in;
        end
    end


	initial begin
        //$readmemh("conv1_weight_1_all1s.mem", weight_1);
        $readmemh(WEIGHTMEM, weight_1);
       // $readmemh("conv1_bias_all1s.mem", bias);
        $readmemh(BIASMEM, bias);
    end
	
	
	integer j,k;
	always @(posedge clk)begin
		if (rst_n==0)begin
			calc_ready<=0;
			//reset all tmp calculation
			for(j=0;j<50;j=j+1)begin
				calc_tmp[j]<=0;
				
			end

			for(j=0;j<5;j=j+1)begin
				calc_done[j]<=0;
				
			end


		end
		
		
		else begin
			
		//ready
		if(maxpool_ready==1) begin
			calc_ready<=1;
			
		//pipeline 1 25 tmp calc
			for (j=0;j<25;j=j+1)begin
				if (j!=24)begin
					calc_tmp[j]<=exp_data[2*j]*weight_1[2*j]+exp_data[2*j+1]*weight_1[2*j+1];
				end
				
				else begin
					calc_tmp[j]<=exp_data[2*j]*weight_1[2*j];
				end
							
			end
			calc_done[0]<=valid_out_buf;
		//end pipeline 1
		
		//pipeline 2 12 tmp calc
			for(j=0;j<12;j=j+1)begin
				if (j!=11)begin
			
					calc_tmp[25+j]<=calc_tmp[2*j]+calc_tmp[2*j+1];
				end
				
				else begin
					calc_tmp[25+j]<=calc_tmp[2*j]+calc_tmp[2*j+1]+calc_tmp[2*j+2];
				end
				
				
			end
			
			calc_done[1]<=calc_done[0];
		//end pipeline 2
		
		//pipeline 3
		
			for(j=0;j<6;j=j+1)begin	
					calc_tmp[37+j]<=calc_tmp[2*j+25]+calc_tmp[2*j+25+1];
					
			end
			
			calc_done[2]<=calc_done[1];
		//end pipeline 3
		
		//pipeline 4 
			for(j=0;j<3;j=j+1)begin	
					calc_tmp[43+j]<=calc_tmp[2*j+37]+calc_tmp[2*j+37+1];
					
			end
			
			calc_done[3]<=calc_done[2];
		//end pipeline 4
		
		//pipeline 5
			for(j=0;j<2;j=j+1)begin	
				if(j==0)begin
					calc_tmp[46+j]<=calc_tmp[2*j+43]+calc_tmp[2*j+43+1];
				end
				
				else begin
					calc_tmp[46+j]<=calc_tmp[2*j+43]+exp_bias[0];
					
				end
					
			end
			calc_done[4]<=calc_done[3];
		
		//end pipeline 5
		
		//pipeline 6
			conv_out_1<=calc_tmp[46]+calc_tmp[47];
			valid_out_calc<=calc_done[4];
		
		
		//end pipelien 6
		end
		
		else begin
			calc_ready<=0;
		end

			
		end
		
		
		
	end
endmodule