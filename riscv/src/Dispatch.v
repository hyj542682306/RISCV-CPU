`include "Definition.v"

module Dispatch (
	//ID
	input  wire				Dispatch_S,
	input  wire				A,
	input  wire 			rd,
	input  wire[`OpBus] 	Op,
	input  wire[`AddrBus]	pc,

	//Regfile
	input  wire 			rs1_S,
	input  wire 			rs1_type,
	input  wire[`DataBus]	rs1_value,
	input  wire 			rs2_S,
	input  wire[`DataBus]	rs2_type,
	input  wire 			rs2_value,
	output reg				Reg_writeQ_S,
	output reg[`RegBus]		Reg_rd,
	output reg[`ROBBus]		Reg_ROBpos,

	//RS
	output wire				RS_S,
	output wire[`RSBus]		RS_pos,
	output wire[`OpBus]		RS_Op,
	output wire[`DataBus]	RS_A,
	output wire[`ROBBus]	RS_Reorder,
	output wire[`AddrBus]	RS_pc,
	output wire				RS_Type_j,
	output wire[`DataBus]	RS_Value_j,
	output wire 			RS_Type_k,
	output wire[`DataBus]	RS_Value_k,
	output wire				RS_ready,
	output wire[`DataBus]	RS_ready_pos,

	//LSB
	output reg				LSB_S,
	output reg[`OpBus]		LSB_Op,
	output reg[`DataBus]	LSB_A,
	output reg[`ROBBus]		LSB_Reorder,
	output reg[`AddrBus]	LSB_pc,
	output reg				LSB_Type_j,
	output reg[`DataBus]	LSB_Value_j,
	output reg 				LSB_Type_k,
	output reg[`DataBus]	LSB_Value_k,
	
	//ROB
	input  wire[`ROBBus]	ROB_nxtpos,
	output reg				ROB_S,
	output reg[`OpBus]		ROB_Op,
	output reg[`RegBus]		ROB_rd,
	output reg[`AddrBus]	ROB_pc,

	input  wire				ROB_rs1_already,
	input  wire[`DataBus]	ROB_rs1_value,
	input  wire				ROB_rs2_already,
	input  wire[`DataBus]	ROB_rs2_value,
	output reg				ROB_rs1_S,
	output reg[`ROBBus]		ROB_rs1_Reorder,
	output reg 				ROB_rs2_S,
	output reg[`ROBBus]		ROB_rs2_Reorder
);

always @(*) begin
	;
end

endmodule //Dispatch