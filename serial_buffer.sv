

module serial_buffer
(
   input wire reset,
   input wire clk,
	
   input wire fifo_empty,
   output wire fifo_rdreq,
	
   input wire uart_busy,
    
   output wire data_valid
);

parameter
	s_idle = 0, 
	s_wait_read = 1,
	s_wait_send = 2,
	s_wait_sent = 3;

reg [2:0] state = s_idle;


always @ (negedge clk)
begin
	
	case (state)
	
		s_idle:
			begin
				data_valid = 0;
				if(!fifo_empty && !uart_busy) begin
					fifo_rdreq = 1;
					state = s_wait_read;
				end
			end
			
		s_wait_read:
			begin
				fifo_rdreq = 0;
				data_valid = 1;
				state = s_wait_send;
			end
			
		s_wait_send:
			begin
				if(uart_busy) begin
					data_valid = 0;
					state = s_wait_sent;
				end
			end
			
		s_wait_sent:
			begin
				if(!uart_busy) begin
					state = s_idle;
				end
			end
	endcase

end

endmodule

