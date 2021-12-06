`include "Definition.v"

module LSB (
	input  wire					clk,
	input  wire 				rst,
	input  wire 				rdy,

	input  wire 				clr,

	//Mem_ctrl
	input  wire					Mem_success,
	input  wire	[`DataBus]		Mem_value,
	output	reg 				Mem_S,
	output	reg					Mem_op,
	output	reg	[`AddrBus]		Mem_pc,
	output	reg	[`InstLen]		Mem_len, 

	//LSB
	output	reg					LSB_nxt_full,
	output	reg	[`LSBBus]		LSB_nxt_pos, //send it to the Dispatch
	output	reg					CDB_LSB_S,
	output	reg	[`ROBBus]		CDB_LSB_Reorder,
	output	reg	[`DataBus]		CDB_LSB_Value,

	//ID
	input  wire					ID_S,

	//Dispatch
	input  wire					Dispatch_S,
	input  wire	[`OpBus]		Dispatch_Op,
	input  wire	[`DataBus]		Dispatch_A,
	input  wire	[`ROBBus]		Dispatch_Reorder,
	input  wire	[`AddrBus]		Dispatch_pc,
	input  wire					Dispatch_Type_j,
	input  wire	[`DataBus]		Dispatch_Value_j,
	input  wire 				Dispatch_Type_k,
	input  wire	[`DataBus]		Dispatch_Value_k,

	//ROB
	input  wire 				ROB_store_S,
	input  wire	[`ROBBus]		ROB_store_Reorder,
	input  wire					ROB_Update1_S,
	input  wire	[`ROBBus]		ROB_Update1_Reorder,
	input  wire	[`DataBus]		ROB_Update1_Value,
	input  wire					ROB_Update2_S,
	input  wire	[`ROBBus]		ROB_Update2_Reorder,
	input  wire	[`DataBus]		ROB_Update2_Value,
	output	reg 				ROB_load_S,
	output	reg	[`ROBBus]		ROB_load_Reorder,
	output	reg	[`DataBus]		ROB_load_Value
);

reg	[`OpBus]					Opcode[`LSBBus];
reg								Tj[`LSBBus];
reg								Tk[`LSBBus];
reg	[`ROBBus]					Qj[`LSBBus];
reg	[`ROBBus]					Qk[`LSBBus];
reg	[`DataBus]					Vj[`LSBBus];
reg	[`DataBus]					Vk[`LSBBus];
reg	[`DataBus]					A[`LSBBus];
reg 							Busy[`LSBBus];
reg	[`ROBBus]					Reorder[`LSBBus];
reg	[`AddrBus]					pc[`LSBBus];
reg 							Commit[`LSBBus];
reg	[`LSBBus]					head;
reg	[`LSBBus]					tail;

integer							i;
integer							BusyNum;
integer							CommitNum;

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
		CDB_LSB_S<=`Disable;
		ROB_load_S<=`Disable;
		for (i=0;i<`SIZE;i=i+1) begin
			Busy[i]<=`False;
		end
		head<=0;
		tail<=0;
		BusyNum<=0;
		CommitNum<=0;
	end
	else if (clr) begin
		Mem_S<=`Disable;
		CDB_LSB_S<=`Disable;
		ROB_load_S<=`Disable;
		for (i=CommitNum;i<`SIZE;i=i+1) begin
			Busy[head+i]<=`False;
		end
		tail<=head+CommitNum;
		BusyNum<=CommitNum;
	end
	else if (rdy) begin
		//update the information from ROB
		if (ROB_Update1_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]) begin
					if (Tj[i]==1'b1&&Qj[i]==ROB_Update1_Reorder) begin
						Tj[i]<=1'b0;
						Vj[i]<=ROB_Update1_Value;
					end
					if (Tk[i]==1'b1&&Qk[i]==ROB_Update1_Reorder) begin
						Tk[i]<=1'b0;
						Vk[i]<=ROB_Update1_Value;
					end
				end
			end
		end
		if (ROB_Update2_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]) begin
					if (Tj[i]==1'b1&&Qj[i]==ROB_Update2_Reorder) begin
						Tj[i]<=1'b0;
						Vj[i]<=ROB_Update2_Value;
					end
					if (Tk[i]==1'b1&&Qk[i]==ROB_Update2_Reorder) begin
						Tk[i]<=1'b0;
						Vk[i]<=ROB_Update2_Value;
					end
				end
			end
		end
		if (ROB_store_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]) begin
					if (ROB_store_Reorder==Reorder[i]) begin
						Commit[i]<=`True;
						CommitNum<=CommitNum+1'b1;
					end
				end
			end
		end

		//add a new inst
		if (Dispatch_S) begin
			Busy[tail]<=`True;
			Opcode[tail]<=Dispatch_Op;

			if (Dispatch_Type_j==1'b0) begin
				Tj[tail]<=1'b0;
				Vj[tail]<=Dispatch_Value_j;
			end
			else begin
				if (ROB_Update1_S&&Dispatch_Value_j==ROB_Update1_Reorder) begin
					Tj[tail]<=1'b0;
					Vj[tail]<=ROB_Update1_Value;
				end
				else if (ROB_Update2_S&&Dispatch_Value_j==ROB_Update2_Reorder) begin
					Tj[tail]<=1'b0;
					Vj[tail]<=ROB_Update2_Value;
				end
				else begin
					Tj[tail]<=1'b1;
					Qj[tail]<=Dispatch_Value_j;
				end
			end

			if (Dispatch_Type_k==1'b0) begin
				Tk[tail]<=1'b0;
				Vk[tail]<=Dispatch_Value_k;
			end
			else begin
				if (ROB_Update1_S&&Dispatch_Value_k==ROB_Update1_Reorder) begin
					Tk[tail]<=1'b0;
					Vk[tail]<=ROB_Update1_Value;
				end
				else if (ROB_Update2_S&&Dispatch_Value_k==ROB_Update2_Reorder) begin
					Tk[tail]<=1'b0;
					Vk[tail]<=ROB_Update2_Value;
				end
				else begin
					Tk[tail]<=1'b1;
					Qk[tail]<=Dispatch_Value_k;
				end
			end

			A[tail]<=Dispatch_A;
			Reorder[tail]<=Dispatch_Reorder;
			pc[tail]<=Dispatch_pc;
			Commit[tail]<=`False;
			tail<=tail+1'b1;
			BusyNum<=BusyNum+1'b1;
		end

		//check the head of the queuem,,,,,
		if (Busy[head]) begin
			case (Opcode[head])

				`LB,`LH,`LW,`LBU,`LHU: begin
					if (Tj[head]==1'b0) begin
						case (Opcode[head])
							`LB: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Value<={{25{Mem_value[7]}},Mem_value[6:0]};

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=1'b1;
									
									CDB_LSB_S<=`Disable;
								end
							end
							`LH: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Value<={{17{Mem_value[15]}},Mem_value[14:0]};

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=2'b10;
									
									CDB_LSB_S<=`Disable;
								end
							end
							`LW: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=3'b100;
									
									CDB_LSB_S<=`Disable;
								end
							end
							`LBU: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=1'b1;
									
									CDB_LSB_S<=`Disable;
								end
							end
							`LHU: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=2'b10;

									CDB_LSB_S<=`Disable;
								end
							end
						endcase
					end
					else begin
						Mem_S<=`Disable;
						CDB_LSB_S<=`Disable;
					end
				end

				`SB,`SW,`SH: begin
					CDB_LSB_S<=`Disable;
					if (Commit[head]) begin
						case (Opcode[head])
							`SB: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									Commit[head]<=`False;
									CommitNum<=CommitNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=1'b1;
								end
							end
							`SW: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									Commit[head]<=`False;
									CommitNum<=CommitNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=2'b10;
								end
							end
							`SH: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1;
									Commit[head]<=`False;
									CommitNum<=CommitNum-1'b1;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=3'b100;
								end
							end
						endcase
					end
					else begin
						Mem_S<=`Disable;
					end
				end

			endcase
		end
	end
	else begin
		Mem_S<=`Disable;
		ROB_load_S<=`Disable;
	end
end

endmodule //LSB