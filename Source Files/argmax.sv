module argmax (
    input  clk,
    input  rst_n,
    input  valid_in,             // Connect to fc_valids[0]
    input  signed [53:0] data_in [9:0] , // All 10 class outputs
    output logic [3:0]  max_index,
    output logic        done
);


logic signed[53:0] max_val[ 12:0];
logic [7:0] max_index_tmp [12:0];//0:4 first clock,
logic tmp_done_bits[3:0];
integer i;
always @(posedge clk)begin
	if(rst_n==0)begin
		done<=0;
		max_index<=0;
		for(int i=0;i<12;i=i+1)begin
			max_index_tmp[i]<=0;
			max_val[i]<=0;
			
		end
		
	end
	
	else begin
		//stage 1
		tmp_done_bits[0]<=valid_in;
		for (int i = 0; i < 5; i++) begin
            if (data_in[2*i] >= data_in[2*i+1]) begin
                max_val[i]       <= data_in[2*i];
                max_index_tmp[i] <= (2*i);
            end else begin
                max_val[i]       <= data_in[2*i+1];
                max_index_tmp[i] <= (2*i+1);
            end
        end
			
		//stage 2	
		tmp_done_bits[1]<=tmp_done_bits[0];	
			if(max_val[0]>max_val[1])begin
				max_val[5]<=max_val[0];
				max_index_tmp[5]<=max_index_tmp[0];
				
			end
			
			else begin
				max_val[5]<=max_val[1];
				max_index_tmp[5]<=max_index_tmp[1];
				
			end


			if(max_val[2]>max_val[3])begin
				max_val[6]<=max_val[2];
				max_index_tmp[6]<=max_index_tmp[2];
				
			end
			
			else begin
				max_val[6]<=max_val[3];
				max_index_tmp[6]<=max_index_tmp[3];
				
			end
				max_val[7]<=max_val[4];
				max_index_tmp[7]<=max_index_tmp[4];
				
		//Stage 3
		
		tmp_done_bits[2]<=tmp_done_bits[1];
		
		if(max_val[5]>max_val[6])begin
			max_val[8]<=max_val[5];
			max_index_tmp[8]<=max_index_tmp[5];
			
		end
		
		else begin 
			max_val[8]<=max_val[6];
			max_index_tmp[8]<=max_index_tmp[6];
						
			
		end
			max_val[9]<=max_val[7];
			max_index_tmp[9]<=max_index_tmp[7];
			
		//Stage 4
		tmp_done_bits[3]<=tmp_done_bits[2];
		done<=tmp_done_bits[3];
		if(max_val[8]>max_val[9])begin
			//max_val[8]<=max_val[5];
			max_index<=max_index_tmp[8];
			
		end
		
		else begin 
			max_index<=max_index_tmp[9];
		end
		
			
			
		
		
	end
end

endmodule