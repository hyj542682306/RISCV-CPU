`include "Definition.v"

module IF (
	input  wire					clk,
	input  wire 				rst,
	input  wire 				rdy,

	//Mem_ctrl
	input  wire 				Mem_success,
	input  wire	[`InstBus]		Mem_value,
	output	reg 				Mem_S,
	output	reg					Mem_op,
	output	reg	[`AddrBus]		Mem_pc,
	output	reg	[`InstLen]		Mem_len,

	//IQ
	input  wire					IQ_full,
	output	reg					IQ_S,
	output	reg	[`InstBus]		IQ_Inst,
	output	reg	[`AddrBus]		IQ_pc,

	//ROB
	input  wire					ROB_Jump_S,
	input  wire	[`AddrBus]		ROB_Jump
);

reg	[`AddrBus]					pc;

always @(posedge clk) begin
	if (rst) begin
		pc<=0;
		Mem_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (ROB_Jump_S) begin
		pc<=ROB_Jump;
		Mem_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (IQ_full) begin
		Mem_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (rdy) begin
		if (Mem_success) begin
			Mem_S<=`Disable;
			IQ_S<=`Enable;
			IQ_Inst<=Mem_value;
			IQ_pc<=pc;
			pc<=pc+3'b100;
		end
		else begin
			Mem_S<=`Enable;
			Mem_op<=1'b0;
			Mem_pc<=pc;
			Mem_len<=3'b100;
		end
	end
	else begin
		Mem_S<=`Disable;
		IQ_S<=`Disable;
	end
end

endmodule //IF