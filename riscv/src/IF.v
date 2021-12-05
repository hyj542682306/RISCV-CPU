`include "Definition.v"

module IF (
	input  wire				clk,
	input  wire 			rst,
	input  wire 			rdy,

	//Mem_ctrl
	input  wire 			Mem_success,
	input  wire				Mem_type,
	input  wire[`InstBus]	Mem_Inst,
	output reg 				Mem_S,
	output reg				Mem_op,
	output reg[`AddrBus]	Mem_pc,
	output reg[`InstLen]	Mem_len,

	//IQ
	input  wire				IQ_full,
	output reg				IQ_S,
	output reg[`InstBus]	IQ_Inst,
	output reg[`AddrBus]	IQ_pc,

	//ROB
	input  wire				ROB_Jump_S,
	input  wire[`AddrBus]	ROB_Jump
);

reg[`AddrBus]				pc;
reg[`InstBus]				Inst;
reg[1:0]					status;

always @(posedge clk) begin

	Mem_S=`Disable;
	IQ_S=`Disable;

	if (rst) begin
		pc<=0;
		Inst<=`Null;
		status<=2'b00;
	end
	else if (ROB_Jump_S) begin
		pc<=ROB_Jump;
		Inst<=`Null;
		status<=2'b00;
	end
	else if (rdy) begin
		if (status==2'b00) begin
			Mem_S<=`Enable;
			Mem_op<=1'b0;
			Mem_pc<=pc;
			Mem_len<=3'b100;
			status<=2'b01;
		end
		else if (status==2'b01) begin
			if (Mem_success) begin
				Inst<=Mem_Inst;
				status<=2'b10;
				if (!IQ_full) begin
					IQ_S<=`Enable;
					IQ_Inst<=Mem_Inst;
					IQ_pc<=pc;

					Mem_S<=`Enable;
					Mem_op<=1'b0;
					Mem_pc<=pc+3'b100;
					Mem_len<=3'b100;

					pc<=pc+3'b100;
					status<=2'b01;
					Inst<=`Null;
				end
			end
		end
		else if (status==2'b10) begin
			if (!IQ_full) begin
				IQ_S<=`Enable;
				IQ_Inst<=Inst;
				IQ_pc<=pc;

				Mem_S<=`Enable;
				Mem_op<=1'b0;
				Mem_pc<=pc+3'b100;
				Mem_len<=3'b100;

				pc<=pc+3'b100;
				status<=2'b01;
				Inst<=`Null;
			end
		end
	end
end

endmodule //IF