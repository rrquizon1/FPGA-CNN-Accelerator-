module maxpool
	#(parameter BUFFER_SIZE=484, //output of the next layer size
				BLOCK_SIZE=2,
				ROW_SIZE=22
				
	)(				input clk,
					input rst_n,			
					//input  logic [DATA_BITS-1:0] data_in,
					input  valid_in,
					input relu_ready,
					output logic maxpool_ready,
					input signed [22:0]   conv_out,
					output logic valid_out_maxpool,
					output logic  signed [22:0] maxpool_out
	
	);
	
	
logic  [22:0] buffer [0:BUFFER_SIZE-1];
logic [22:0] max_1,max_2;


integer i,r,c;
localparam READY=0,CAPTURE_DATA=1,MAXPOOL_1=2,MAXPOOL_2=3,OUT=4;
logic  [3:0]               state;
logic [15:0] buf_idx; 
logic [15:0] maxpool_idx; 
logic [7:0] col_cnt; // Tracks 0 to 10 (since we have 11 blocks)
logic [7:0] row_cnt; // Tracks 0 to 10


always @(posedge clk)begin
	if(rst_n==0 || relu_ready==0)begin
            for (i=0; i < BUFFER_SIZE; i=i+1)
            begin
                buffer[i] <= 0;
            end
			state<=READY;
			maxpool_out<=0;
			buf_idx<=0;
			row_cnt<=0;
			col_cnt<=0;
			maxpool_idx<=0;
			valid_out_maxpool <= 0;
	end
			
	else begin
			case(state)
				READY: begin
					maxpool_ready<=1;
					state<=CAPTURE_DATA;
					maxpool_out<=0;
					buf_idx<=0;
					row_cnt<=0;
					col_cnt<=0;
					maxpool_idx<=0;
					valid_out_maxpool <= 0;
				end
				
				CAPTURE_DATA:begin
					if (buf_idx == BUFFER_SIZE) begin
						buf_idx <= 0;
						//maxpool_ready <= 0;
						valid_out_maxpool <= 0;
						state <= MAXPOOL_1;
					end
					else if (valid_in == 1) begin
							buffer[buf_idx] <= conv_out;
							buf_idx <= buf_idx + 1;
					end
				end
				
				MAXPOOL_1:begin
					if (buffer[maxpool_idx]>buffer[maxpool_idx+1])begin
						max_1<=buffer[maxpool_idx];
					end
					
					else begin 
						max_1<=buffer[maxpool_idx+1]; 
					end

					if (buffer[maxpool_idx+ROW_SIZE]>buffer[maxpool_idx+ROW_SIZE+1])begin
						max_2<=buffer[maxpool_idx+ROW_SIZE];
					end
					
					else begin 
						max_2<=buffer[maxpool_idx+ROW_SIZE+1]; 
					end
					
					state<=MAXPOOL_2;
					valid_out_maxpool<=0;
				end
				
				MAXPOOL_2:begin
					if (max_1>max_2)begin
						maxpool_out<=max_1;
						
					end
					
					else begin
						maxpool_out<=max_2;
					end
					
					if (col_cnt < (ROW_SIZE/2) - 1) begin
						// Move to the next block in the same row
						maxpool_idx <= maxpool_idx + 2;
						col_cnt <= col_cnt + 1;
						state <= MAXPOOL_1;
					end
					else if (row_cnt < (ROW_SIZE/2) - 1) begin
						// We hit the end of the row! Jump down to the next pooling row
						maxpool_idx <= maxpool_idx + ROW_SIZE + BLOCK_SIZE; // +22 to skip current row, +2 to finish the stride
						col_cnt <= 0;
						row_cnt <= row_cnt + 1;
						state <= MAXPOOL_1;
					end
					
					else begin 
						state<=READY;
					end
					
					 valid_out_maxpool<=1;
					
						
				end
				
				
				
				
				
				
				
			endcase
			
	end		

	
	
	
	
end

endmodule