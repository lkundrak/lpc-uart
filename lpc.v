/*
 * LPC interface module.
 *
 * Hardwired to 0x03fx address range (see inline comments), implementing just
 * the few bits in the status register and the data I/O.
 *
 * Sufficient for the Coreboot console and the SerialICE input.
 *
 * Copyright (C) 2017 Lubomir Rintel <lkundrak@v3.sk>
 * Distributed under the terms of GPLv2 or (at your option) any later version.
 */

module lpc (
	lpc_clk,
	lpc_rst,
	lpc_data,
	lpc_frame,
	tx_data,
	tx_data_valid,
	rx_data,
	rx_data_valid,
	tx_busy
);
	reg rd = 0;
	reg lpc_data_out = 0;
	reg [3:0] out_data = 4'hf;

	input lpc_clk;
	input lpc_rst;

	inout [3:0] lpc_data;
	wire [3:0] in_data;
	input lpc_frame;

	output [7:0] tx_data;
	output tx_data_valid;

	input [7:0] rx_data;
	input rx_data_valid;

	input tx_busy;

	wire lpc_clk;
	wire lpc_rst;
	wire tx_busy;

`ifdef YOSYS
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) databuf0 (
		.PACKAGE_PIN(lpc_data[0]),
		.OUTPUT_ENABLE(lpc_data_out),
		.D_OUT_0(out_data[0]),
		.D_IN_0(in_data[0])
	);
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) databuf1 (
		.PACKAGE_PIN(lpc_data[1]),
		.OUTPUT_ENABLE(lpc_data_out),
		.D_OUT_0(out_data[1]),
		.D_IN_0(in_data[1])
	);
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) databuf2 (
		.PACKAGE_PIN(lpc_data[2]),
		.OUTPUT_ENABLE(lpc_data_out),
		.D_OUT_0(out_data[2]),
		.D_IN_0(in_data[2])
	);
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) databuf3 (
		.PACKAGE_PIN(lpc_data[3]),
		.OUTPUT_ENABLE(lpc_data_out),
		.D_OUT_0(out_data[3]),
		.D_IN_0(in_data[3])
	);
`else
	assign lpc_data = lpc_data_out ? out_data : 4'bZ, in_data = lpc_data;
`endif

	wire lpc_frame;

	reg [7:0] tx_data = 0;
	reg tx_data_valid = 0;

	parameter START = 0;
	parameter CTDIR = 1;
	parameter ADDR0 = 2;
	parameter ADDR1 = 3;
	parameter ADDR2 = 4;
	parameter ADDR3 = 5;
	parameter WDATA0 = 6;
	parameter WDATA1 = 7;
	parameter TAR0 = 8;
	parameter SYNC = 9;
	parameter RDATA0 = 10;
	parameter RDATA1 = 11;
	parameter TAR1 = 12;
	reg [3:0] state = START;

	reg status_port = 0;

	reg [7:0] rxbuf[3:0];
	reg [1:0] rx_begin = 0;
	reg [1:0] rx_end = 0;

	always @(posedge lpc_clk)
	begin


		if (rx_data_valid)
		begin
			$display("LPC RX: [%x]", rx_data);
			rxbuf[rx_end] <= rx_data;
			rx_end <= rx_end + 1;
		end

//		$display("RXBUF: begin=%d end=%d [%02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x]", rx_begin, rx_end,
//			rxbuf[0], rxbuf[1], rxbuf[2], rxbuf[3], rxbuf[4], rxbuf[5], rxbuf[6], rxbuf[7]);

		//$display("LPCCLK: [%d] [%x] [%x]", state, lpc_frame, in_data);
		if (lpc_frame == 0)
		begin
			if (in_data == 0)
				state <= CTDIR;
			else
				state <= START;
		end
		else
		begin
			case (state)
			START:
				tx_data_valid <= 0;
			CTDIR:
				if (in_data == 0)
				begin
					rd <= 1;
					state <= ADDR0;
				end
				else if (in_data == 2)
				begin
					rd <= 0;
					state <= ADDR0;
				end
				else
					state <= START;
			ADDR0:
				// 0x03fx
				//   ^ the most significant address nibble
				if (in_data == 0)
					state <= ADDR1;
				else
					state <= START;
			ADDR1:
				// 0x03fx
				//    ^ second address nibble
				if (in_data == 'h3)
					state <= ADDR2;
				else
					state <= START;
			ADDR2:
				// 0x03fx
				//     ^ third address nibble
				if (in_data == 'hf)
					state <= ADDR3;
				else
					state <= START;
			ADDR3:
			begin
				// 0x03fx
				//      ^ d || 8
				if (in_data[3:0] == 4'hd || in_data[3:0] == 4'h8)
				begin
					status_port <= in_data[0];
					if (rd == 1)
						state <= TAR0;
					else
						state <= WDATA0;
				end
				else
					state <= START;
			end
			WDATA0:
			begin
				tx_data[3:0] <= in_data;
				state <= WDATA1;
			end
			WDATA1:
			begin
				tx_data[7:4] <= in_data;
				state <= TAR0;
			end
			TAR0:
			begin
				lpc_data_out <= 1;
				state <= SYNC;
			end
			SYNC:
			begin
				out_data <= 0;
				if (rd)
					state <= RDATA0;
				else
				begin
					tx_data_valid <= 1;
					state <= TAR1;
				end
			end
			RDATA0:
			begin
				if (status_port)
					out_data <= rx_begin != rx_end;
				else if (rx_begin != rx_end)
					out_data <= rxbuf[rx_begin][3:0];
				else
					out_data <= 4'hf;
				state <= RDATA1;
			end
			RDATA1:
			begin
				if (status_port)
					out_data <= (tx_busy ? 0 : 6);
				else if (rx_begin != rx_end)
				begin
					out_data <= rxbuf[rx_begin][7:4];
					rx_begin <= rx_begin + 1;
				end
				else
					out_data <= 4'hf;
				state <= TAR1;
			end
			TAR1:
			begin
				lpc_data_out <= 0;
				state <= START;
			end
			endcase
		end
	end
endmodule
