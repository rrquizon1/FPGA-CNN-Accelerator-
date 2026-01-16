module conv1_buf
    #(
        parameter WIDTH = 28,
                  HEIGHT = 28,
                  DATA_BITS = 8,
				  FILTER_SIZE = 7
    )
    (
        input  logic                 clk,
        input  logic                 rst_n,
        input  logic                 valid_in,
	
        input  logic [DATA_BITS-1:0] data_in,
		input logic calc_ready,
		output logic signed [DATA_BITS:0] data_out [0:FILTER_SIZE*FILTER_SIZE-1],	
        output logic                  valid_out_buf,
		output logic 					buf_ready
        
    );
	
	//unsigned to signed adds 0 at the beginning
	//signed to signed extends the MSB

    logic  signed [DATA_BITS:0] buffer [0:WIDTH*HEIGHT-1];
    logic  [15:0] buf_idx;
    logic  [4:0]           w_idx, h_idx;
    logic  [2:0]           buf_flag; // 0 ~ 4
    logic  [3:0]               state;
	integer i,r,c;
	
	localparam READY=0,CAPTURE_DATA=1,READY_SEND=2;
always @(posedge clk)
    begin
        if ((~rst_n) || (calc_ready==0))
        begin
            for (i=0; i <= HEIGHT*WIDTH-1; i=i+1)
            begin
                buffer[i] <= 0;
            end
			
			
			for (r = 0; r < FILTER_SIZE; r = r + 1) begin
				for (c = 0; c < FILTER_SIZE; c = c + 1) begin
					data_out[r*FILTER_SIZE + c] <= 0;
				end
			end
			
            buf_idx <= 0;
            w_idx <= 0;
            h_idx <= 0;
            buf_flag <= 0;
            state <= 0;
            valid_out_buf <= 0;
			buf_ready<=0;
			
			state<=READY;
          end
		  
		else begin
			case(state)
				READY: begin
					buf_ready<=1;
					state<=CAPTURE_DATA;
				end
				
				CAPTURE_DATA:begin
					if (valid_in==1)begin
						buffer[buf_idx]<=data_in;
						if(buf_idx==(HEIGHT*WIDTH-1))begin 
							state<=READY_SEND;
							buf_ready<=0;
						end
						else begin
							
							buf_idx<=buf_idx+1;
						end
					end
				end
				
				
				
				READY_SEND:begin
					//buf_ready<=0;
					if (h_idx <= (HEIGHT - FILTER_SIZE)) begin
						valid_out_buf <= 1;
						for (r = 0; r < FILTER_SIZE; r = r + 1) begin
							for (c = 0; c < FILTER_SIZE; c = c + 1) begin
								data_out[r*FILTER_SIZE + c] <= buffer[(h_idx + r)*WIDTH + (w_idx + c)];
							end
						end		
				// Sliding Window Control
						if (w_idx < (WIDTH - FILTER_SIZE)) begin
								w_idx <= w_idx + 1;
						end 
						else begin
							w_idx <= 0;
							h_idx <= h_idx + 1;
						end
						end


					else begin
						valid_out_buf <= 0;
						state <= READY;
						h_idx <= 0; // Reset for next image
						w_idx <= 0;
						buf_idx<=0;
						
					end
				
				
				end
				
			endcase
			
			
			
		end
	end
endmodule