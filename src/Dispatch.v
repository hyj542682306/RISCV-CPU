module Dispatch (
	//ID
	input  wire					Dispatch_S,
	input  wire	[`DataBus]		A,
	input  wire [`RegBus]		rd,
	input  wire	[`OpBus] 		Op,
	input  wire	[`AddrBus]		pc,

	//Dispatch
	output	reg	[`OpBus]		Dispatch_Op,
	output	reg	[`DataBus]		Dispatch_A,
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
	input  wire					rs2_type,
	input  wire [`DataBus]		rs2_value,
	output	reg					Reg_writeQ_S,

	//RS - S,pos,Op,A,Reorder,pc
	input  wire	[`RSBus]		RS_las_pos,
	input  wire					RS_las_ready,
	input  wire	[`RSBus]		RS_las_ready_pos,
	output	reg					RS_S,
	output	reg	[`RSBus]		RS_pos,
	output	reg					RS_ready,
	output	reg	[`RSBus]		RS_ready_pos,

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

//Dispatch
always @(*) begin
	if (Dispatch_S) begin
		Dispatch_Op=Op;
		Dispatch_A=A;
		Dispatch_rd=rd;
		Dispatch_Reorder=ROB_nxtpos;
		Dispatch_pc=pc;
	end
	else begin
		Dispatch_Op=`Null;
		Dispatch_A=`Null;
		Dispatch_rd=`Null;
		Dispatch_Reorder=`Null;
		Dispatch_pc=`Null;
	end
end

//RS
always @(*) begin
	RS_ready=RS_las_ready;
	RS_ready_pos=RS_las_ready_pos;
	if (!Dispatch_S||Op==`LB||Op==`LH||Op==`LW||Op==`LBU||Op==`LHU||Op==`SB||Op==`SH||Op==`SW) begin
		RS_S=`Disable;
		RS_pos=`Null;
	end
	else begin
		RS_S=`Enable;
		RS_pos=RS_las_pos;
	end
end

//LSB
always @(*) begin
	if (Dispatch_S && 
		(Op==`LB||Op==`LH||Op==`LW||Op==`LBU||Op==`LHU||Op==`SB||Op==`SH||Op==`SW)
		) begin
		LSB_S=`Enable;
	end
	else begin
		LSB_S=`Disable;
	end
end

//Regfile
always @(*) begin
	if (!Dispatch_S||Op==`SB||Op==`SH||Op==`SW||Op==`BEQ||Op==`BNE||Op==`BLT||Op==`BGE||Op==`BLTU||Op==`BGEU) begin
		Reg_writeQ_S=`Disable;
	end
	else begin
		Reg_writeQ_S=`Enable;
	end
end

//ROB
always @(*) begin
	ROB_S=Dispatch_S;
end

//update rs1
always @(*) begin
	if (Dispatch_S&&rs1_S) begin
		if (rs1_type==1'b0) begin
			ROB_rs1_S=`Disable;
			ROB_rs1_Reorder=`Null;
			Dispatch_Type_j=1'b0;
			Dispatch_Value_j=rs1_value;
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
		ROB_rs1_S=`Disable;
		ROB_rs1_Reorder=`Null;
		Dispatch_Type_j=`Null;
		Dispatch_Value_j=`Null;
	end
end

//update rs2
always @(*) begin
	if (Dispatch_S&&rs2_S) begin
		if (rs2_type==1'b0) begin
			ROB_rs2_S=`Disable;
			ROB_rs2_Reorder=`Null;
			Dispatch_Type_k=1'b0;
			Dispatch_Value_k=rs2_value;
		end
		else begin
			ROB_rs2_S=`Enable;
			ROB_rs2_Reorder=rs2_value;
			if (ROB_rs2_already) begin
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
		ROB_rs2_S=`Disable;
		ROB_rs2_Reorder=`Null;
		Dispatch_Type_k=`Null;
		Dispatch_Value_k=`Null;
	end
end

endmodule //Dispatch