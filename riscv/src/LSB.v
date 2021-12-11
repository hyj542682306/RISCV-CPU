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
	output	reg [`DataBus]		Mem_result,

	//LSB
	output	reg					LSB_nxt_full,
	output	reg					CDB_LSB_S,
	output	reg	[`ROBBus]		CDB_LSB_Reorder,
	output	reg	[`DataBus]		CDB_LSB_Value,

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
	input  wire					ROB_head_S,
	input  wire [`ROBBus]		ROB_head
);

reg	[`OpBus]					Opcode[`LSBSize];
reg								Tj[`LSBSize];
reg								Tk[`LSBSize];
reg	[`ROBBus]					Qj[`LSBSize];
reg	[`ROBBus]					Qk[`LSBSize];
reg	[`DataBus]					Vj[`LSBSize];
reg	[`DataBus]					Vk[`LSBSize];
reg	[`DataBus]					A[`LSBSize];
reg 							Busy[`LSBSize];
reg	[`ROBBus]					Reorder[`LSBSize];
reg	[`AddrBus]					pc[`LSBSize];
reg 							Commit[`LSBSize];
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

always @(posedge clk) begin
	if (rst) begin
		Mem_S<=`Disable;
		CDB_LSB_S<=`Disable;
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
		if (Mem_success&&Commit[head]==1) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (head==i||!Commit[i]) begin
					Busy[i]<=`False;
				end
			end
			Commit[head]<=`False;
			CommitNum<=CommitNum-1'b1;
			Busy[head]<=`False;
			BusyNum<=CommitNum-1'b1;
			head<=head+1'b1;
			tail<=head+CommitNum;
		end
		else begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (!Commit[i]) begin
					Busy[i]<=`False;
				end
			end
			tail<=head+CommitNum;
			BusyNum<=CommitNum;
		end
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

		//add a new inst
		if (Dispatch_S) begin
			// $display("LSB NEW INST: %b",Dispatch_Op);
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
		end

		//check the head of the queue
		if (BusyNum>0&&Busy[head]) begin
			// $display("LSB HEAD: Head: %d; Tail: %d; Opcode: %b; Tj: %d; Commit: %d",head,tail,Opcode[head],Tj[head],Commit[head]);
			case (Opcode[head])

				`LB,`LH,`LW,`LBU,`LHU: begin
					if (Tj[head]==1'b0 &&
						( (Vj[head]+A[head]<32'h30000)
						|| (Vj[head]+A[head]>=32'h30000&&ROB_head_S&&Reorder[head]==ROB_head) )
						) begin
						case (Opcode[head])
							`LB: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Reorder<=Reorder[head];
									CDB_LSB_Value<={{25{Mem_value[7]}},Mem_value[6:0]};

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=1'b1;
									
									CDB_LSB_S<=`Disable;

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`LH: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Reorder<=Reorder[head];
									CDB_LSB_Value<={{17{Mem_value[15]}},Mem_value[14:0]};

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=2'b10;
									
									CDB_LSB_S<=`Disable;

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`LW: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Reorder<=Reorder[head];
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=3'b100;
									
									CDB_LSB_S<=`Disable;

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`LBU: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Reorder<=Reorder[head];
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=1'b1;
									
									CDB_LSB_S<=`Disable;

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`LHU: begin
								if (Mem_success) begin
									Mem_S<=`Disable;

									CDB_LSB_S<=`Enable;
									CDB_LSB_Reorder<=Reorder[head];
									CDB_LSB_Value<=Mem_value;

									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b0;
									Mem_pc<=Vj[head]+A[head];
									Mem_len<=2'b10;

									CDB_LSB_S<=`Disable;

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
						endcase
					end
					else begin
						Mem_S<=`Disable;
						CDB_LSB_S<=`Disable;
						BusyNum<=BusyNum+Dispatch_S;
					end
				end

				`SB,`SH,`SW: begin
					CDB_LSB_S<=`Disable;
					if (Commit[head]) begin
						case (Opcode[head])
							`SB: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									Commit[head]<=`False;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;

									if (ROB_Update1_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update1_Reorder) begin
										Mem_pc<=ROB_Update1_Value+A[head];
									end
									else if (ROB_Update2_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update2_Reorder) begin
										Mem_pc<=ROB_Update2_Value+A[head];
									end
									else begin
										Mem_pc<=Vj[head]+A[head];
									end

									Mem_len<=1'b1;

									if (ROB_Update1_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update1_Reorder) begin
										Mem_result<=ROB_Update1_Value;
									end
									else if (ROB_Update2_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update2_Reorder) begin
										Mem_result<=ROB_Update2_Value;
									end
									else begin
										Mem_result<=Vk[head];
									end

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`SH: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									Commit[head]<=`False;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;

									if (ROB_Update1_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update1_Reorder) begin
										Mem_pc<=ROB_Update1_Value+A[head];
									end
									else if (ROB_Update2_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update2_Reorder) begin
										Mem_pc<=ROB_Update2_Value+A[head];
									end
									else begin
										Mem_pc<=Vj[head]+A[head];
									end

									Mem_len<=2'b10;

									if (ROB_Update1_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update1_Reorder) begin
										Mem_result<=ROB_Update1_Value;
									end
									else if (ROB_Update2_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update2_Reorder) begin
										Mem_result<=ROB_Update2_Value;
									end
									else begin
										Mem_result<=Vk[head];
									end

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
							`SW: begin
								if (Mem_success) begin
									Mem_S<=`Disable;
									Busy[head]<=`False;
									BusyNum<=BusyNum-1'b1+Dispatch_S;
									Commit[head]<=`False;
									head<=head+1'b1;
								end
								else begin
									Mem_S<=`Enable;
									Mem_op<=1'b1;

									if (ROB_Update1_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update1_Reorder) begin
										Mem_pc<=ROB_Update1_Value+A[head];
									end
									else if (ROB_Update2_S&&Tj[head]==1'b1&&Qj[head]==ROB_Update2_Reorder) begin
										Mem_pc<=ROB_Update2_Value+A[head];
									end
									else begin
										Mem_pc<=Vj[head]+A[head];
									end

									Mem_len<=3'b100;
									
									if (ROB_Update1_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update1_Reorder) begin
										Mem_result<=ROB_Update1_Value;
									end
									else if (ROB_Update2_S&&Tk[head]==1'b1&&Qk[head]==ROB_Update2_Reorder) begin
										Mem_result<=ROB_Update2_Value;
									end
									else begin
										Mem_result<=Vk[head];
									end

									BusyNum<=BusyNum+Dispatch_S;
								end
							end
						endcase
					end
					else begin
						Mem_S<=`Disable;
						BusyNum<=BusyNum+Dispatch_S;
					end
				end

			endcase
		end
		else begin
			Mem_S<=`Disable;
			CDB_LSB_S<=`Disable;
			BusyNum<=BusyNum+Dispatch_S;
		end

		if (ROB_store_S) begin
			for (i=0;i<`SIZE;i=i+1) begin
				if (Busy[i]) begin
					if (ROB_store_Reorder==Reorder[i]) begin
						Commit[i]<=`True;
						CommitNum<=CommitNum+1'b1-
							(BusyNum>0 && Busy[head] && 
								(Opcode[head]==`SB||Opcode[head]==`SH||Opcode[head]==`SW) &&
							Mem_success);
					end
				end
			end
		end
		else begin
			CommitNum<=CommitNum-
				(BusyNum>0 && Busy[head] && 
					(Opcode[head]==`SB||Opcode[head]==`SH|Opcode[head]==`SW) &&
				Mem_success);
		end
	end
	else begin
		Mem_S<=`Disable;
		CDB_LSB_S<=`Disable;
	end
end

endmodule //LSB