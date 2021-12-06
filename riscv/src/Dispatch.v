`include "Definition.v"

module Dispatch (
	//ID
	input  wire					Dispatch_S,
	input  wire					A,
	input  wire 				rd,
	input  wire	[`OpBus] 		Op,
	input  wire	[`AddrBus]		pc,

	//Dispatch
	output	reg					Dispatch_Op,
	output	reg					Dispatch_A,
	output	reg	[`RegBus]		Dispatch_rd,
	output	reg	[`ROBBus]		Dispatch_Reorder,
	output	reg	[`AddrBus]		Dispatch_pc,
	output	reg					Dispatch_Type_j,
	output	reg	[`DataBus]		Dispatch_Value_j,
	output	reg					Dispatch_Type_k,
	output	reg	[`DataBus]		Dispatch_Value_k,

	//Regfile - writeQ_S,rd,Reorder
	input  wire 				rs1_S,
	input  wire 				rs1_type,
	input  wire	[`DataBus]		rs1_value,
	input  wire 				rs2_S,
	input  wire	[`DataBus]		rs2_type,
	input  wire 				rs2_value,
	output	reg					Reg_writeQ_S,

	//RS - S,pos,Op,A,Reorder,pc
	input  wire	[`RSBus]		RS_las_pos,
	input  wire					RS_las_ready,
	input  wire	[`RSBus]		RS_las_ready_pos,
	output	reg					RS_S,
	output	reg	[`RSBus]		RS_pos,
	output	reg					RS_ready,
	output	reg	[`DataBus]		RS_ready_pos,

	//LSB - S,Op,A,Reorder,pc
	output	reg					LSB_S,
	
	//ROB - S,Op,rd,pc
	input  wire	[`ROBBus]		ROB_nxtpos,
	output	reg					ROB_S,

	input  wire					ROB_rs1_already,
	input  wire	[`DataBus]		ROB_rs1_value,
	input  wire					ROB_rs2_already,
	input  wire	[`DataBus]		ROB_rs2_value,
	output	reg					ROB_rs1_S,
	output	reg	[`ROBBus]		ROB_rs1_Reorder,
	output	reg 				ROB_rs2_S,
	output	reg	[`ROBBus]		ROB_rs2_Reorder
);

always @(*) begin
	if (Dispatch_S) begin
		//Dispatch
		Dispatch_Op=Op;
		Dispatch_A=A;
		Dispatch_rd=rd;
		Dispatch_Reorder=ROB_nxtpos;
		Dispatch_pc=pc;
		if (rs1_S) begin
			if (rs1_type==1'b0) begin
				Dispatch_Type_j=1'b0;
				Dispatch_Value_j=rs1_value;
				ROB_rs1_S=`Disable;
			end
			else begin
				ROB_rs1_S=`Enable;
				ROB_rs1_Reorder=rs1_value;
				if (ROB_rs1_already) begin
					Dispatch_Type_j=1'b0;
					Dispatch_Value_j=ROB_rs1_value;
				end
				else begin
					Dispatch_Type_j=1'b1;
					Dispatch_Value_j=rs1_value;
				end
			end
		end
		else begin
			Dispatch_Type_j=`Null;
			Dispatch_Value_j=`Null;
		end
		if (rs2_S) begin
			if (rs2_type==1'b0) begin
				Dispatch_Type_k=1'b0;
				Dispatch_Value_k=rs2_value;
				ROB_rs2_S=`Disable;
			end
			else begin
				ROB_rs2_S=`Enable;
				ROB_rs2_Reorder=rs2_value;
				if (ROB_rs1_already) begin
					Dispatch_Type_k=1'b0;
					Dispatch_Value_k=ROB_rs2_value;
				end
				else begin
					Dispatch_Type_k=1'b1;
					Dispatch_Value_k=rs2_value;
				end
			end
		end
		else begin
			Dispatch_Type_k=`Null;
			Dispatch_Value_k=`Null;
		end

		//Reg
		Reg_writeQ_S=`Enable;

		//RS
		RS_S=`Enable;
		RS_ready=RS_las_ready;
		RS_ready_pos=RS_las_ready;

		//LSB
		LSB_S=`Enable;

		//ROB
		ROB_S=`Enable;
	end
	else begin
		//Reg
		Reg_writeQ_S=`Disable;

		//RS
		RS_S=`Disable;
		RS_ready=RS_las_ready;
		RS_ready_pos=RS_las_ready_pos;

		//LSB
		LSB_S=`Disable;

		//ROB
		ROB_S=`Disable;
	end
end

endmodule //Dispatch