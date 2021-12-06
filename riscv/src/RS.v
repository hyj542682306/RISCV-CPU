`include "Definition.v"

module RS (
	input  wire					clk,
	input  wire					rst,
	input  wire 				rdy,

	input  wire					clr,

	//RS
	output	reg					RS_nxt_full,
	output	reg	[`RSBus]		RS_nxt_pos, //send it to Dispatch
	output	reg					RS_nxt_ready, //send it to Dispatch
	output	reg	[`RSBus]		RS_nxt_ready_pos, //send it to Dispatch

	//ID
	input  wire					ID_S,

	//Dispatch
	input  wire					Dispatch_S,
	input  wire	[`RSBus]		Dispatch_pos,
	input  wire	[`OpBus]		Dispatch_Op,
	input  wire	[`DataBus]		Dispatch_A,
	input  wire	[`ROBBus]		Dispatch_Reorder,
	input  wire	[`AddrBus]		Dispatch_pc,
	input  wire					Dispatch_Type_j,
	input  wire	[`DataBus]		Dispatch_Value_j,
	input  wire 				Dispatch_Type_k,
	input  wire	[`DataBus]		Dispatch_Value_k,
	input  wire					Dispatch_ready,
	input  wire	[`DataBus]		Dispatch_ready_pos,

	//ALU
	output	reg					ALU_S,
	output	reg	[`OpBus]		ALU_Op,
	output	reg	[`DataBus]		ALU_Vj,
	output	reg	[`DataBus]		ALU_Vk,
	output	reg	[`ROBBus]		ALU_Reorder,
	output	reg	[`DataBus]		ALU_A,
	output	reg	[`AddrBus]		ALU_pc, 
	input  wire					CDB_ALU_S,
	input  wire	[`ROBBus]		CDB_ALU_Reorder,
	input  wire	[`DataBus]		CDB_ALU_Value,

	//LSB
	input  wire					CDB_LSB_S,
	input  wire	[`ROBBus]		CDB_LSB_Reorder,
	input  wire	[`DataBus]		CDB_LSB_Value
);

reg	[`OpBus]					Opcode[`RSBus];
reg								Tj[`RSBus];
reg 							Tk[`RSBus];
reg	[`ROBBus]					Qj[`RSBus];
reg	[`ROBBus]					Qk[`RSBus];
reg	[`DataBus]					Vj[`RSBus];
reg	[`DataBus]					Vk[`RSBus];
reg	[`DataBus]					A[`RSBus];
reg								Busy[`RSBus];
reg	[`ROBBus]					Reorder[`RSBus];
reg	[`AddrBus]					pc[`RSBus];

integer							i,j,k;
integer							BusyNum;

//whether RS is full
always @(*) begin
	if (BusyNum==`SIZE) begin
		RS_nxt_full=`True;
	end
	else begin
		RS_nxt_full=`False;
	end
end

//find the nxtpos and send it to Dispatch
always @(*) begin
	if (rst||clr||ID_S==`Disable) begin
		RS_nxt_pos=`Null;
	end
	else begin
		for (j=0;j<`SIZE;j=j+1) begin
			if (!Busy[j]) begin
				RS_nxt_pos=j;
			end
		end
	end
end

//find the readypos and send it tp Dispatch
always @(*) begin
	if (rst||clr) begin
		RS_nxt_ready=`False;
	end
	else begin
		for (k=0;k<`SIZE;k=k+1) begin
			if (Busy[k]) begin
				case (Opcode[k])
					`LUI,`AUIPC,`JAL: begin
						RS_nxt_ready=`Enable;
						RS_nxt_ready_pos=k;
					end
					`JALR,`ADDI,`SLTI,`SLTIU,`XORI,`ORI,`ANDI,`SLLI,`SRLI,`SRAI: begin
						if (Tj[k]==1'b0) begin
							RS_nxt_ready=`Enable;
							RS_nxt_ready_pos=k;
						end
						else begin
							RS_nxt_ready=`Disable;
						end
					end
					`BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU,`ADD,`SUB,`SLL,`SLT,`SLTU,`XOR,`SRL,`SRA,`OR,`AND: begin
						if (Tj[k]==1'b0&&Tk[k]==1'b0) begin
							RS_nxt_ready=`Enable;
							RS_nxt_ready_pos=k;
						end
						else begin
							RS_nxt_ready=`Disable;
						end
					end
					default: RS_nxt_ready=`Disable;
				endcase
			end
		end
	end
end

always @(posedge clk) begin
	if (rst) begin
		ALU_S<=`Disable;
		for (i=0;i<`SIZE;i=i+1) begin
			Busy[i]<=`False;
		end
		BusyNum<=0;
	end
	else if (clr) begin
		ALU_S<=`Disable;
		for (i=0;i<`SIZE;i=i+1) begin
			Busy[i]<=`False;
		end
		BusyNum<=0;
	end
	else if (rdy) begin
		//update the information from ALU
		if (CDB_ALU_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]==`True) begin
					if (Tj[i]==1'b1&&Qj[i]==CDB_ALU_Reorder) begin
						Tj[i]<=1'b0;
						Vj[i]<=CDB_ALU_Value;
					end
					if (Tk[i]==1'b1&&Qk[i]==CDB_ALU_Reorder) begin
						Tk[i]<=1'b0;
						Vk[i]<=CDB_ALU_Value;
					end
				end
			end
		end
		if (CDB_LSB_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]==`True) begin
					if (Tj[i]==1'b1&&Qj[i]==CDB_LSB_Reorder) begin
						Tj[i]<=1'b0;
						Vj[i]<=CDB_LSB_Value;
					end
					if (Tk[i]==1'b1&&Qk[i]==CDB_LSB_Reorder) begin
						Tk[i]<=1'b0;
						Vk[i]<=CDB_LSB_Value;
					end
				end
			end
		end

		//add a new inst
		if (Dispatch_S) begin
			Busy[Dispatch_pos]<=`True;
			Opcode[Dispatch_pos]<=Dispatch_Op;

			if (Dispatch_Type_j==1'b0) begin
				Tj[Dispatch_pos]<=1'b0;
				Vj[Dispatch_pos]<=Dispatch_Value_j;
			end
			else begin
				if (CDB_ALU_S&&Dispatch_Value_j==CDB_ALU_Reorder) begin
					Tj[Dispatch_pos]<=1'b0;
					Vj[Dispatch_pos]<=CDB_ALU_Value;
				end
				else if (CDB_LSB_S&&Dispatch_Value_j==CDB_LSB_Reorder) begin
					Tj[Dispatch_pos]<=1'b0;
					Vj[Dispatch_pos]<=CDB_LSB_Value;
				end
				else begin
					Tj[Dispatch_pos]<=1'b1;
					Qj[Dispatch_pos]<=Dispatch_Value_j;
				end
			end

			if (Dispatch_Type_k==1'b0) begin
				Tk[Dispatch_pos]<=1'b0;
				Vk[Dispatch_pos]<=Dispatch_Value_k;
			end
			else begin
				if (CDB_ALU_S&&Dispatch_Value_k==CDB_ALU_Reorder) begin
					Tk[Dispatch_pos]<=1'b0;
					Vk[Dispatch_pos]<=CDB_ALU_Value;
				end
				else if (CDB_LSB_S&&Dispatch_Value_k==CDB_LSB_Reorder) begin
					Tk[Dispatch_pos]<=1'b0;
					Vk[Dispatch_pos]<=CDB_LSB_Value;
				end
				else begin
					Tk[Dispatch_pos]<=1'b1;
					Qk[Dispatch_pos]<=Dispatch_Value_k;
				end
			end

			A[Dispatch_pos]<=Dispatch_A;
			Reorder[Dispatch_pos]<=Dispatch_Reorder;
			pc[Dispatch_pos]<=Dispatch_pc;
			BusyNum<=BusyNum+1'b1;
		end

		//find the ready inst and send it to ALU
		if (Dispatch_ready) begin
			ALU_S<=`Enable;
			ALU_Op<=Opcode[Dispatch_ready_pos];
			ALU_Vj<=Vj[Dispatch_ready_pos];
			ALU_Vk<=Vk[Dispatch_ready_pos];
			ALU_Reorder<=Reorder[Dispatch_ready_pos];
			ALU_A<=A[Dispatch_ready_pos];
			ALU_pc<=pc[Dispatch_ready_pos];
			Busy[Dispatch_ready_pos]<=`False;
			BusyNum<=BusyNum-1'b1;
		end
		else begin
			ALU_S<=`Disable;
		end
	end
	else begin
		ALU_S<=`Disable;
	end
end

endmodule //RS