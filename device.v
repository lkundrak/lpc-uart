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

	wire [7:0] data;
	wire data_valid;
	wire [7:0] rx_data;
	wire rx_data_valid;
	wire busy;

	lpc lpc0 (LPC_CLK, LPC_RST, { LPC_D3, LPC_D2, LPC_D1, LPC_D0 }, LPC_FRAME, data, data_valid, rx_data, rx_data_valid, busy);
	uart uart0 (LPC_CLK, data, data_valid, UART_TX, busy);
	uart_rx uartrx0 (LPC_CLK, rx_data, rx_data_valid, UART_RX);
endmodule
