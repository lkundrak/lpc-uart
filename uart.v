module uart (clk, data, data_valid, tx, busy);
	input clk;
	input [7:0] data;
	input data_valid;
	output tx;
	output busy;

	wire clk;
	wire [7:0] data;
	wire data_valid;
	reg tx = 1'bZ;
	wire busy;

	// 286 * 115200 = 32947200 MHz
	parameter DIVISOR = 286;
	reg [8:0] divisor = 0;

	parameter IDLE = 0;
	parameter ENABLE = 1;
	parameter START = 2;
	parameter DATA0 = 3;
	parameter DATA1 = 4;
	parameter DATA2 = 5;
	parameter DATA3 = 6;
	parameter DATA4 = 7;
	parameter DATA5 = 8;
	parameter DATA6 = 9;
	parameter DATA7 = 10;
	parameter STOP = 11;
	reg [3:0] state = IDLE;
	assign busy = (state > IDLE);

	always @(posedge clk)
	begin
		// $display("UARTCLK: [%d] [%d] [%d] {%d}", state, data_valid, divisor, tx);
		if (data_valid == 1 && state == IDLE)
			state = ENABLE;

		if (divisor == DIVISOR)
		begin
			divisor <= 0;
			if (state > IDLE && state < STOP)
				state = state + 1;
			else
				state = IDLE;
			case (state)
			IDLE: tx <= 1'bZ;
			START: tx <= 0;
			DATA0: tx <= data[0];
			DATA1: tx <= data[1];
			DATA2: tx <= data[2];
			DATA3: tx <= data[3];
			DATA4: tx <= data[4];
			DATA5: tx <= data[5];
			DATA6: tx <= data[6];
			DATA7: tx <= data[7];
			STOP: tx <= 1;
			endcase
		end
		else
			divisor <= divisor + 1;
	end
endmodule
