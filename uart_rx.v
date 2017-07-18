/*
 * UART receiver.
 * Hardwired to 115200 8-N-1 with 33 MHz clock source (see inline comments).
 *
 * Copyright (C) 2017 Lubomir Rintel <lkundrak@v3.sk>
 * Distributed under the terms of GPLv2 or (at your option) any later version.
 */

module uart_rx (
	clk,
	data,
	data_valid,
	rx
);
	input clk;
	output [7:0] data;
	output data_valid;
	input rx;

	reg [7:0] data = 8'h7a;
	reg data_valid = 0;

	// 286 * 115200 = 32947200 MHz
	parameter DIVISOR = 286;
	reg [8:0] divisor = 0;
	reg [8:0] counter;

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

	reg bit;

	always @(negedge clk)
	begin
		if (divisor == 0 && state == IDLE)
		begin
			data_valid <= 0;
			if (rx == 0)
				state <= START;
		end
		else if (divisor == DIVISOR - 1 && state != IDLE)
		begin
			if (counter > 143)
				bit = 1;
			else
				bit = 0;
			divisor <= 0;
			case (state)
			START: if (bit != 0)
				state = IDLE;
			DATA0: data[0] <= bit;
			DATA1: data[1] <= bit;
			DATA2: data[2] <= bit;
			DATA3: data[3] <= bit;
			DATA4: data[4] <= bit;
			DATA5: data[5] <= bit;
			DATA6: data[6] <= bit;
			DATA7: data[7] <= bit;
			STOP: if (bit == 1)
				data_valid <= 1;
			endcase
			//$display("UARTCLK: [%d] (%d) {%d} <%x>:%d", state, divisor, rx, data, data_valid);
			if (state > IDLE && state < STOP)
				state = state + 1;
			else
				state = IDLE;
			counter <= 0;
		end
		else
		begin
			data_valid <= 0;
			divisor <= divisor + 1;
			counter <= counter + rx;
		end
	end
endmodule
