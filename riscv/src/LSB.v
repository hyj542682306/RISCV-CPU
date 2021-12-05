`include "Definition.v"

module LSB (
	input  wire				clk,
	input  wire 			rst,
	input  wire 			rdy,

	input  wire 			clr,

	//Mem_ctrl
	input  wire				Mem_success,
	input  wire				Mem_type,
	input  wire[`DataBus]	Mem_value,
	output reg 				Mem_S,
	output reg				Mem_op,
	output reg[`AddrBus]	Mem_pc,
	output reg[`InstLen]	Mem_len, 

	//LSB
	output reg				LSB_nxt_full,
	output reg[`LSBBus]		LSB_nxt_pos, //send it to the Dispatch
	output reg				CDB_LSB_S,
	output reg[`ROBBus]		CDB_LSB_Reorder,
	output reg[`DataBus]	CDB_LSB_Value,

	//ID
	input  wire				ID_S,

	//Dispatch
	input  wire				Dispatch_S,
	input  wire[`OpBus]		Dispatch_Op,
	input  wire[`DataBus]	Dispatch_A,
	input  wire[`ROBBus]	Dispatch_Reorder,
	input  wire[`AddrBus]	Dispatch_pc,
	input  wire				Dispatch_Type_j,
	input  wire[`DataBus]	Dispatch_Value_j,
	input  wire 			Dispatch_Type_k,
	input  wire[`DataBus]	Dispatch_Value_k,

	//ALU
	input  wire				CDB_ALU_S,
	input  wire[`ROBBus]	CDB_ALU_Reorder,
	input  wire[`DataBus]	CDB_ALU_Value,

	//ROB
	input  wire 			ROB_store_S,
	input  wire[`ROBBus]	ROB_store_Reorder,
	input  wire[`DataBus]	ROB_store_Value,
	output reg 				ROB_load_S,
	output reg[`ROBBus]		ROB_load_Reorder,
	output reg[`DataBus]	ROB_load_Value  
);

reg[`OpBus]					Opcode[`LSBBus];
reg							Tj[`LSBBus];
reg							Tk[`LSBBus];
reg[`ROBBus]				Qj[`LSBBus];
reg[`ROBBus]				Qk[`LSBBus];
reg[`DataBus]				Vj[`LSBBus];
reg[`DataBus]				Vk[`LSBBus];
reg[`DataBus]				A[`LSBBus];
reg 						Busy[`LSBBus];
reg[`ROBBus]				Reorder[`LSBBus];
reg[`AddrBus]				pc[`LSBBus];
reg 						Commit[`LSBBus];
reg[`LSBBus]				head;
reg[`LSBBus]				tail;

integer						i;
integer						BusyNum;

//whether LSB is full
always @(*) begin
	if (BusyNum==`SIZE) begin
		LSB_nxt_full=`True;
	end
	else begin
		LSB_nxt_full=`False;
	end
end


//find the nxtpos and send it to Dispatch
always @(*) begin
	if (rst||clr||ID_S==`Disable) begin
		LSB_nxt_pos=`Null;
	end
	else begin
		LSB_nxt_pos=tail;
	end
end

always @(posedge clk) begin
	if (rst) begin
		Mem_S<=`Disable;
		ROB_load_S<=`Disable;
		for (i=0;i<`SIZE;i=i+1) begin
			Busy[i]<=`False;
		end
		head<=0;
		tail<=0;
		BusyNum<=0;
	end
	else if (clr) begin
		;
	end
	else if (rdy) begin
		//update the information from ALU
	end
	else begin
		Mem_S<=`Disable;
		ROB_load_S<=`Disable;
	end
end

endmodule //LSB