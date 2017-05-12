module lpc (
	CLK,
	RST_BTN,
	MID_BTN,

	LPC_CLK,
	LPC_RST,
	LPC_D0,
	LPC_D1,
	LPC_D2,
	LPC_D3,
	LPC_FRAME,

	UART_TX,
	LED1,
	LED2
);

	input CLK;
	input RST_BTN;
	input MID_BTN;

	input LPC_CLK;
	input LPC_RST;
	inout LPC_D0;
	inout LPC_D1;
	inout LPC_D2;
	inout LPC_D3;
	input LPC_FRAME;

	output UART_TX;
	output LED1;
	output LED2;

	reg LED1 = 0;
	reg LED2 = 0;

	wire [7:0] data;
	wire data_valid;
	wire busy;

	lpc_dev dev0 (LPC_CLK, LPC_RST, { LPC_D3, LPC_D2, LPC_D1, LPC_D0 }, LPC_FRAME, data, data_valid, busy);
	uart uart0 (LPC_CLK, data, data_valid, UART_TX, busy);

	reg [23:0] count = 0;
	always @(posedge LPC_CLK)
	begin
		count <= count + 1;
		if (count == 0)
			LED2 <= ~LED2;
	end
endmodule
