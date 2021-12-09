`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/Definition.v"

module IF (
	input  wire					clk,
	input  wire 				rst,
	input  wire 				rdy,

	//ICache
	input  wire 				IC_success,
	input  wire	[`InstBus]		IC_value,
	output	reg 				IC_S,
	output	reg	[`AddrBus]		IC_pc,

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
		IC_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (ROB_Jump_S) begin
		pc<=ROB_Jump;
		IC_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (IQ_full) begin
		IC_S<=`Disable;
		IQ_S<=`Disable;
	end
	else if (rdy) begin
		if (IC_success) begin
			IC_S<=`Disable;
			IQ_S<=`Enable;
			IQ_Inst<=IC_value;
			// $display("IF: %h",IC_value);
			IQ_pc<=pc;
			pc<=pc+3'b100;
		end
		else begin
			IC_S<=`Enable;
			IC_pc<=pc;
			IQ_S<=`Disable;
		end
	end
	else begin
		IC_S<=`Disable;
		IQ_S<=`Disable;
	end
end

endmodule //IF