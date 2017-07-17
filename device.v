/*
 * A simple LPC UART device.
 * Glues a transmitter part, a receiver part and a LPC bus interface.
 *
 * Copyright (C) 2017 Lubomir Rintel <lkundrak@v3.sk>
 * Distributed under the terms of GPLv2 or (at your option) any later version.
 */

module device (
	LPC_CLK,
	LPC_RST,
	LPC_D0,
	LPC_D1,
	LPC_D2,
	LPC_D3,
	LPC_FRAME,

	UART_TX,
	UART_RX
);
	input LPC_CLK;
	input LPC_RST;
	inout LPC_D0;
	inout LPC_D1;
	inout LPC_D2;
	inout LPC_D3;
	input LPC_FRAME;

	output UART_TX;
	input UART_RX;

	wire [7:0] tx_data;
	wire tx_data_valid;
	wire [7:0] rx_data;
	wire rx_data_valid;
	wire tx_busy;

	lpc lpc0 (LPC_CLK, LPC_RST, { LPC_D3, LPC_D2, LPC_D1, LPC_D0 }, LPC_FRAME, tx_data, tx_data_valid, rx_data, rx_data_valid, tx_busy);
	uart_tx uart_tx0 (LPC_CLK, tx_data, tx_data_valid, UART_TX, tx_busy);
	uart_rx uart_rx0 (LPC_CLK, rx_data, rx_data_valid, UART_RX);
endmodule
