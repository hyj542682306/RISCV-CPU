module ROB (
	input  wire 				clk,
	input  wire 				rst,
	input  wire 				rdy,

	//ROB
	output	reg 				ROB_nxt_full,
	output	reg 				clr,
	output	reg	[`ROBBus]		ROB_nxt_pos, //send it to Dispatch

	//IF
	output	reg					IF_Jump_S,
	output	reg	[`AddrBus]		IF_Jump,

	//ID
	input  wire					ID_S,

	//Dispatch
	input  wire					Dispatch_S,
	input  wire	[`OpBus]		Dispatch_Op,
	input  wire	[`RegBus]		Dispatch_rd,
	input  wire	[`AddrBus]		Dispatch_pc,
	input  wire					Dispatch_rs1_S,
	input  wire	[`ROBBus]		Dispatch_rs1_Reorder,
	input  wire 				Dispatch_rs2_S,
	input  wire	[`ROBBus]		Dispatch_rs2_Reorder,
	output	reg					Dispatch_rs1_already,
	output	reg	[`DataBus]		Dispatch_rs1_value,
	output	reg					Dispatch_rs2_already,
	output	reg	[`DataBus]		Dispatch_rs2_value,

	//ALU
	input  wire					ALU_S,
	input  wire	[`ROBBus]		ALU_Reorder,
	input  wire	[`DataBus]		ALU_Value,
	input  wire					ALU_Jump_S,
	input  wire	[`AddrBus]		ALU_Jump,

	//Regfile
	output	reg					Reg_write_S,
	output	reg	[`RegBus]		Reg_rd,
	output	reg	[`ROBBus]		Reg_Reorder,
	output	reg	[`DataBus]		Reg_result,

	//LSB
	input  wire 				LSB_load_S,
	input  wire	[`ROBBus]		LSB_load_Reorder,
	input  wire	[`DataBus]		LSB_load_Value,
	output	reg					LSB_store_S,
	output	reg	[`ROBBus]		LSB_store_Reorder,
	output	reg					LSB_Update1_S,
	output	reg	[`ROBBus]		LSB_Update1_Reorder,
	output	reg	[`DataBus]		LSB_Update1_Value,
	output	reg 				LSB_Update2_S,
	output	reg	[`ROBBus]		LSB_Update2_Reorder,
	output	reg	[`DataBus]		LSB_Update2_Value,

	output	reg					LSB_head_S,
	output	reg	[`ROBBus]		LSB_head
);

reg	[`OpBus]					Opcode[`ROBSize];
reg	[`RegBus]					Dest[`ROBSize];
reg	[`DataBus]					Value[`ROBSize];
reg								Jump_S[`ROBSize];
reg	[`AddrBus]					Jump[`ROBSize];
reg	[`AddrBus]					pc[`ROBSize];
reg								Ready[`ROBSize];
reg	[`ROBBus]					head;
reg	[`ROBBus]					tail;
reg								empty;

integer 						i;

//find the nxtpos and send it to Dispatch
always @(*) begin
	if (ID_S==`Disable) begin
		ROB_nxt_pos=`Null;
	end
	else begin
		ROB_nxt_pos=tail;
	end
end

//send the information to Dispatch rs1
always @(*) begin
	if (Dispatch_rs1_S==`Disable) begin
		Dispatch_rs1_already=`False;
		Dispatch_rs1_value=`Null;
	end
	else begin
		if (Ready[Dispatch_rs1_Reorder]) begin
			Dispatch_rs1_already=`True;
			Dispatch_rs1_value=Value[Dispatch_rs1_Reorder];
		end
		else begin
			Dispatch_rs1_already=`False;
			Dispatch_rs1_value=`Null;
		end
	end
end

//send the information to Dispatch rs2
always @(*) begin
	if (Dispatch_rs2_S==`Disable) begin
		Dispatch_rs2_already=`False;
		Dispatch_rs2_value=`Null;
	end
	else begin
		if (Ready[Dispatch_rs2_Reorder]) begin
			Dispatch_rs2_already=`True;
			Dispatch_rs2_value=Value[Dispatch_rs2_Reorder];
		end
		else begin
			Dispatch_rs2_already=`False;
			Dispatch_rs2_value=`Null;
		end
	end
end

//send the information of the head of the queue to LSB
always @(*) begin
	if (!empty) begin
		LSB_head_S=`Enable;
		LSB_head=head;
	end
	else begin
		LSB_head_S=`Disable;
		LSB_head=`Null;
	end
end

//update the information of ROB (add, update, commit)
always @(posedge clk) begin
	if (rst) begin
		head<=0;
		tail<=0;
		empty<=`True;
		clr<=`False;
		for (i=0;i<`SIZE;i=i+1) begin
			Opcode[i]<=`Null;
			Dest[i]<=`Null;
			Value[i]<=`Null;
			Jump_S[i]<=`Null;
			Jump[i]<=`Null;
			pc[i]<=`Null;
			Ready[i]<=`Null;
		end
		IF_Jump_S<=`Disable;
		Reg_write_S<=`Disable;
		LSB_store_S<=`Disable;
		LSB_Update1_S<=`Disable;
		LSB_Update2_S<=`Disable;
	end
	else if (clr) begin
		head<=0;
		tail<=0;
		empty<=`True;
		clr<=`False;
		for (i=0;i<`SIZE;i=i+1) begin
			Opcode[i]<=`Null;
			Dest[i]<=`Null;
			Value[i]<=`Null;
			Jump_S[i]<=`Null;
			Jump[i]<=`Null;
			pc[i]<=`Null;
			Ready[i]<=`Null;
		end
		IF_Jump_S<=`Disable;
		Reg_write_S<=`Disable;
		LSB_store_S<=`Disable;
		LSB_Update1_S<=`Disable;
		LSB_Update2_S<=`Disable;
	end
	else if (rdy) begin
		ROB_nxt_full<=head+((!empty)&&Ready[head])==tail+Dispatch_S&&(!empty);
		empty<=(head+((!empty)&&Ready[head])==tail+Dispatch_S&&empty)
			 ||(head+((!empty)&&Ready[head])==tail+Dispatch_S&&((!empty)&&Ready[head])&&(!Dispatch_S));

		//add a new inst
		if (Dispatch_S) begin
			// $display("Add Inst Op: %b; pc: %d; head: %d; tail: %d",Dispatch_Op,Dispatch_pc,head,tail);
			Opcode[tail]<=Dispatch_Op;
			Dest[tail]<=Dispatch_rd;
			Value[tail]<=`Null;
			Jump_S[tail]<=`Null;
			Jump[tail]<=`Null;
			pc[tail]<=Dispatch_pc;
			if (Dispatch_Op==`SB||Dispatch_Op==`SW||Dispatch_Op==`SH) begin
				Ready[tail]<=`True;
			end
			else begin
				Ready[tail]<=`False;
			end
			tail<=tail+1'b1;
		end

		//update the information from ALU or LSB
		if (ALU_S) begin
			Value[ALU_Reorder]<=ALU_Value;
			Jump_S[ALU_Reorder]<=ALU_Jump_S;
			Jump[ALU_Reorder]<=ALU_Jump;
			Ready[ALU_Reorder]<=`True;
			LSB_Update1_S<=`Enable;
			LSB_Update1_Reorder<=ALU_Reorder;
			LSB_Update1_Value<=ALU_Value;
		end
		else begin
			LSB_Update1_S<=`Disable;
		end
		if (LSB_load_S) begin
			// $display("LSB_LOAD_S Reorder: %d",LSB_load_Reorder);
			Value[LSB_load_Reorder]<=LSB_load_Value;
			Ready[LSB_load_Reorder]<=`True;
			LSB_Update2_S<=`Enable;
			LSB_Update2_Reorder<=LSB_load_Reorder;
			LSB_Update2_Value<=LSB_load_Value;
		end
		else begin
			LSB_Update2_S<=`Disable;
		end

		// $display("ROB HEAD: Head: %d; Tail: %d; Opcode: %b; Ready: %d",head,tail,Opcode[head],Ready[head]);

		//commit
		if ((!empty)&&Ready[head]) begin
			// $display("Commit Opcode: %b; rd: %h; Value: %d; Jump: %d",Opcode[head],Dest[head],Value[head],Jump[head]);
			// $display("Value: %d; Jump: %d; Commit Opcode: %b; rd: %h; pc: %d; head: %d; tail: %d",Value[head],Jump[head],Opcode[head],Dest[head],pc[head],head,tail);
			case (Opcode[head])

				`JAL,`JALR: begin
					clr<=`True;

					IF_Jump_S<=`Enable;
					IF_Jump<=Jump[head];

					Reg_write_S<=`Enable;
					Reg_Reorder<=head;
					Reg_rd<=Dest[head];
					Reg_result<=Value[head];

					LSB_store_S<=`Disable;
				end

				`BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU: begin
					if (Jump_S[head]) begin
						clr<=`True;
						IF_Jump_S<=`Enable;
						IF_Jump<=Jump[head];
					end
					else begin
						clr<=`False;
						IF_Jump_S<=`Disable;
					end
					Reg_write_S<=`Disable;
					LSB_store_S<=`Disable;
				end

				`SB,`SH,`SW: begin
					clr<=`False;

					IF_Jump_S<=`Disable;

					Reg_write_S<=`Disable;

					LSB_store_S<=`Enable;
					LSB_store_Reorder<=head;
				end

				default: begin
					clr<=`False;

					IF_Jump_S<=`Disable;

					Reg_write_S<=`Enable;
					Reg_Reorder<=head;
					Reg_rd<=Dest[head];
					Reg_result<=Value[head];

					LSB_store_S<=`Disable;
				end

			endcase
			head<=head+1'b1;
		end
		else begin
			clr<=`False;
			IF_Jump_S<=`Disable;
			Reg_write_S<=`Disable;
			LSB_store_S<=`Disable;
		end
	end
	else begin
		ROB_nxt_full<=head==tail&&(!empty);
		clr<=`False;
		IF_Jump_S<=`Disable;
		Reg_write_S<=`Disable;
		LSB_store_S<=`Disable;
		LSB_Update1_S<=`Disable;
		LSB_Update2_S<=`Disable;
	end
end

endmodule //ROB