

module spi_slave
(
   input wire reset,
	
   input wire mosi,
   input wire miso,
   input wire ss,
   input wire clk,
	
   input wire fifo_clk,
	
   input wire uart_busy,
    
   output wire [7:0] data,
   output wire data_valid
);

reg [7:0] received_bytes = 0;
reg [2:0] received_bits = 0;
reg [7:0] received_data_mosi = 0;
reg [7:0] received_data_miso = 0;
reg received_write = 0;
reg last_ss = 0;
reg last_ss_check = 0;

reg [7:0] data_internal;

reg data_req = 0;
reg data_req_sync[2:0];
reg data_half = 0;
reg data_complete = 0;
reg ss_deactivated = 0;




always @(posedge fifo_clk) data_valid <= (data_req_sync[2] != data_req_sync[1]);
always @(posedge fifo_clk) data_req_sync[2] <= data_req_sync[1];
always @(negedge fifo_clk) data_req_sync[1] <= data_req_sync[0];
always @(posedge fifo_clk) data_req_sync[0] <= data_req;



always @ (posedge data_complete or posedge ss)
begin
   if (ss) begin
		ss_deactivated <= 1;
   end else if (data_complete) begin
		ss_deactivated <= 0;
	end
end

always @ (negedge ss)
begin
	last_ss <= !last_ss;
end

always @ (negedge clk)
begin
	if (!ss) begin
		if(data_complete) begin
			if(received_write || received_bytes < 2) begin
				data <= received_data_mosi;
			end else begin
				data <= received_data_miso;
			end
			data_req <= !data_req;
		end else if(data_half) begin
			if(ss_deactivated) begin
				data <= 8'hDE;
			end else begin
				data <= 8'hDD;
			end
			data_req <= !data_req;
		end
	end
end

always @ (posedge clk)
begin

	if (!ss) begin
	
		if(last_ss_check != last_ss) begin
			last_ss_check <= last_ss;
			received_data_mosi <= { 7'b0, mosi };
			received_data_miso <= { 7'b0, miso };
			received_bits <= 1;
			received_bytes <= 0;
			received_write <= mosi;
			data_half <= 0;
			data_complete <= 0;
		end else begin
			received_data_mosi <= { received_data_mosi[6:0], mosi };
			received_data_miso <= { received_data_miso[6:0], miso };
			
			data_half <= (received_bits == 3);
			
			if(received_bits == 7) begin
				received_bytes <= received_bytes + 1;
				data_complete <= 1;
			end else begin
				data_complete <= 0;
			end
			
			received_bits <= received_bits + 1;
		end
	end
end

endmodule
