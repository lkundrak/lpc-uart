/*
 * LPC UART device test bench.
 * As good as I can write, which is not too good.
 *
 * Copyright (C) 2017 Lubomir Rintel <lkundrak@v3.sk>
 * Distributed under the terms of GPLv2 or (at your option) any later version.
 */

module test;
	reg data_out = 1;
	reg [3:0] out_data;
	wire [3:0] lpc_data;
	assign lpc_data = data_out ? out_data : 4'bZ;

	reg lpc_clk;
	reg lpc_frame;

	reg uart_rx = 1;
	wire uart_tx;
	wire lpc_rst;

	reg [7:0] read_data = 8'hff;

	device device0 (lpc_clk, lpc_rst, lpc_data[0], lpc_data[1], lpc_data[2], lpc_data[3], lpc_frame,
		uart_tx, uart_rx);

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

	task lpc_write;
	input [15:0] port;
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
		out_data = port[15:12];
		tick;
		// ADDR1
		out_data = port[11:8];
		tick;
		// ADDR2
		out_data = port[7:4];
		tick;
		// ADDR3
		out_data = port[3:0];
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
	input [15:0] port;
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
		out_data = port[15:12];
		tick;
		// ADDR1
		out_data = port[11:8];
		tick;
		// ADDR2
		out_data = port[7:4];
		tick;
		// ADDR3
		out_data = port[3:0];
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

		// Initial state
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty initially");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'hff) $error("Data read from empty FIFO");

		// Receive data on the UART
		uart_write (8'h5a);

		// Read the data from LPC
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h61) $error("FIFO empty after write");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'h5a) $error("Wrong data read");

		// Attempt a couple of reads from an empty FIFO
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty after a read");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'hff) $error("Data read from empty FIFO");

		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty after a read from empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'hff) $error("Data read from empty FIFO");

		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty after a read from empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'hff) $error("Data read from empty FIFO");

		// Transmit data on the LPC
		lpc_write (16'h3f8, 8'h5a);
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h00) $error("Port not busy after transmit");

		repeat (2000) tick;
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h00) $error("Port not busy after 2000 ticks");

		repeat (2000) tick;
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready after 4000 ticks");

		// Transmit some more data
		lpc_write (16'h3f8, 8'ha5);
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h00) $error("Port not busy after transmit");

		// Receive on UART while we're still transmitting
		uart_write (8'h0f);
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h01) $error("Port not busy or FIFO empty after a RX during TX");

		repeat (4000) tick;
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h61) $error("Port not ready or FIFO empty after finished RX and TX");

		// Now pick up the received data
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'h0f) $error("Wrong data read");
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty after a read");

		// Transmit more bytes to fill the FIFO
		uart_write (8'h01);
		repeat (286) tick;
		uart_write (8'h02);
		repeat (10) tick;
		uart_write (8'h03);
		repeat (10) tick;

		// Pick up tbe bytes
		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h61) $error("Port not ready or FIFO empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'h01) $error("Wrong data read");

		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h61) $error("Port not ready or FIFO empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'h02) $error("Wrong data read");

		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h61) $error("Port not ready or FIFO empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'h03) $error("Wrong data read");

		lpc_read (16'h3fd, read_data);
		if (read_data != 8'h60) $error("Port not ready or FIFO not empty");
		lpc_read (16'h3f8, read_data);
		if (read_data != 8'hff) $error("Data read from empty FIFO");

		$finish;
	end
endmodule
