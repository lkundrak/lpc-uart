module uart_rx (clk, data, data_valid, rx);
	input clk;
	output [7:0] data;
	output data_valid;
	input rx;

	reg [7:0] data = 8'h7a;
	reg data_valid = 0;

	reg [7:0] buffer;

	// 286 * 115200 = 32947200 MHz
	parameter DIVISOR = 286;
	reg [8:0] divisor = 0;

	parameter IDLE = 0;
	parameter START = 1;
	parameter DATA0 = 2;
	parameter DATA1 = 3;
	parameter DATA2 = 4;
	parameter DATA3 = 5;
	parameter DATA4 = 6;
	parameter DATA5 = 7;
	parameter DATA6 = 8;
	parameter DATA7 = 9;
	parameter STOP = 10;
	reg [3:0] state = IDLE;

	always @(posedge clk)
	begin
		if (divisor == 0 && state == IDLE)
		begin
			data_valid <= 0;
			if (rx == 0)
			begin
				divisor <= DIVISOR / 2;
				state <= START;
			end
		end
		else if (divisor == DIVISOR)
		begin
			divisor <= 0;
			case (state)
			START: if (rx != 0)
				state = IDLE;
			DATA0: data[0] <= rx;
			DATA1: data[1] <= rx;
			DATA2: data[2] <= rx;
			DATA3: data[3] <= rx;
			DATA4: data[4] <= rx;
			DATA5: data[5] <= rx;
			DATA6: data[6] <= rx;
			DATA7: data[7] <= rx;
			STOP: if (rx == 1)
				data_valid <= 1;
			endcase
			//$display("UARTCLK: [%d] (%d) {%d} <%x>:%d", state, divisor, rx, data, data_valid);
			if (state > IDLE && state < STOP)
				state = state + 1;
			else
				state = IDLE;
		end
		else
			divisor <= divisor + 1;
	end
endmodule
