module test;
	reg data_out = 1;
	reg [3:0] out_data;
	wire [3:0] lpc_data;
	assign lpc_data = data_out ? out_data : 4'bZ;

	reg lpc_clk;
	reg lpc_frame;

	wire led1;
	wire led2;
	reg uart_rx;
	wire uart_tx;
	wire lpc_rst;

	reg [7:0] read_data = 8'hff;

	device device0 (lpc_clk, lpc_rst, lpc_data[0], lpc_data[1], lpc_data[2], lpc_data[3], lpc_frame,
		uart_tx, uart_rx, led1, led2);

	task tick;
	begin
		# 1 lpc_clk = 1;
		# 1 lpc_clk = 0;
	end
	endtask

	task lpc_write;
	input [7:0] write_value;
	begin
		$display ("Write: %x", write_value);

		data_out = 1;

		// START
		lpc_frame = 0;
		out_data = 0; // ISA transaction
		tick;

		// CTDIR
		lpc_frame = 1;
		out_data = 2; // IOWR
		//out_data = 0; // IORD
		tick;

		// ADDR0
		out_data = 0;
		tick;
		// ADDR1
		out_data = 3;
		tick;
		// ADDR2
		out_data = 15;
		tick;
		// ADDR3
		out_data = 8;
		tick;

		// DATA0
		out_data <= write_value[7:4];
		tick;
		// DATA1
		out_data <= write_value[3:0];
		tick;

		data_out = 0;
		// TAR
		tick;

		// SYNC
		tick;

		data_out = 1;
		// TAR
		tick;
	end
	endtask

	task lpc_read;
	output [7:0] read_value;
	begin
		data_out = 1;

		// START
		lpc_frame = 0;
		out_data = 0; // ISA transaction
		tick;

		// CTDIR
		lpc_frame = 1;
		out_data = 0; // IORD
		tick;

		// ADDR0
		out_data = 0;
		tick;
		// ADDR1
		out_data = 3;
		tick;
		// ADDR2
		out_data = 15;
		tick;
		// ADDR3
		out_data = 13;
		tick;

		data_out = 0;
		// TAR
		tick;

		// SYNC
		tick;

		// DATA0
		tick;
		read_value[3:0] <= lpc_data;

		// DATA1
		tick;
		read_value[7:4] <= lpc_data;

		data_out = 1;
		// TAR
		tick;

		$display ("Read: %x", read_value);
	end
	endtask

	initial
	begin
		$dumpfile("test.vcd");
		$dumpvars;

		lpc_write (8'h5a);
		lpc_read (read_data);
		repeat (2000) tick;
		lpc_read (read_data);
		repeat (2000) tick;
		lpc_read (read_data);
		lpc_write (8'ha5);
		repeat (4000) tick;

		$finish;
	end
endmodule
