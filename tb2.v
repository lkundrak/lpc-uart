module test;
	reg clk;
	reg rst_btn = 1;
	reg mid_btn = 0;

	reg data_out = 1;
	reg [3:0] out_data;
	wire [3:0] lpc_data;
	assign lpc_data = data_out ? out_data : 4'bZ;

	reg lpc_clk;
	reg lpc_frame;

	wire led1;
	wire led2;
	reg uart_rx = 1;
	wire uart_tx;
	wire lpc_rst;

	lpc lpc0 (clk, rst_btn, mid_btn,
		lpc_clk, lpc_rst, lpc_data[0], lpc_data[1], lpc_data[2], lpc_data[3], lpc_frame,
		uart_tx, uart_rx, led1, led2);

	task tick;
	begin
		# 1 lpc_clk = 1;
		# 1 lpc_clk = 0;
	end
	endtask

	task uart_write_bit;
	input write_bit;
	begin
		uart_rx <= write_bit;
		repeat (286) tick;
	end
	endtask

	task uart_write;
	input [7:0] write_value;
	begin
		// Start bit
		uart_write_bit (0);

		// Data bits
		uart_write_bit (write_value[0]);
		uart_write_bit (write_value[1]);
		uart_write_bit (write_value[2]);
		uart_write_bit (write_value[3]);
		uart_write_bit (write_value[4]);
		uart_write_bit (write_value[5]);
		uart_write_bit (write_value[6]);
		uart_write_bit (write_value[7]);

		// Stop bit
		uart_write_bit (1);
	end
	endtask

	initial
	begin
		$dumpfile("test.vcd");
		$dumpvars;

		repeat (10) tick;
		uart_write (8'h0f);
		uart_write (8'ha5);
		repeat (1000) tick;
		uart_write (8'hf0);
		repeat (10) tick;

		$finish;
	end
endmodule
