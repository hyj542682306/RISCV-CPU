module Regfile (
	input  wire					clk,
	input  wire 				rst,
	input  wire 				rdy,

	input  wire 				clr,

	//ID
	input  wire 				ID_rs1_S,
	input  wire	[`RegBus] 		ID_rs1,
	input  wire 				ID_rs2_S,
	input  wire	[`RegBus] 		ID_rs2,

	//Dispatch
	output	reg					Dispatch_rs1_S,
	output	reg					Dispatch_rs1_type,
	output	reg	[`DataBus] 		Dispatch_rs1_value,
	output	reg					Dispatch_rs2_S,
	output	reg					Dispatch_rs2_type,
	output	reg	[`DataBus]		Dispatch_rs2_value,
	input  wire					Dispatch_writeQ_S,
	input  wire	[`RegBus]		Dispatch_rd,
	input  wire	[`ROBBus]		Dispatch_ROBpos,

	//ROB
	input  wire					ROB_write_S,
	input  wire	[`RegBus] 		ROB_rd,
	input  wire	[`ROBBus]		ROB_Reorder,
	input  wire	[`DataBus]		ROB_result
);

reg	[`DataBus]					V[`RegSize];
reg	[`ROBBus]					Q[`RegSize];
reg 							T[`RegSize];

integer							i;

//send the information of 'rs1' to Dispatch
always @(*) begin
	Dispatch_rs1_S=`Disable;
	Dispatch_rs1_type=`Null;
	Dispatch_rs1_value=`Null;
	if (ID_rs1_S==`Disable) begin
		Dispatch_rs1_S=`Disable;
	end
	else begin
		Dispatch_rs1_S=`Enable;
		if (T[ID_rs1]==1'b0) begin
			Dispatch_rs1_type=1'b0;
			Dispatch_rs1_value=V[ID_rs1];
		end
		else begin
			if (ROB_write_S==`Enable&&ROB_Reorder==Q[ID_rs1]) begin
				Dispatch_rs1_type=1'b0;
				Dispatch_rs1_value=ROB_result;
			end
			else begin
				Dispatch_rs1_type=1'b1;
				Dispatch_rs1_value={27'b0,Q[ID_rs1]};
			end
		end
	end
end

//send the information of 'rs2' to Dispatch
always @(*) begin
	Dispatch_rs2_S=`Disable;
	Dispatch_rs2_type=`Null;
	Dispatch_rs2_value=`Null;
	if (ID_rs2_S==`Disable) begin
		Dispatch_rs2_S=`Disable;
	end
	else begin
		Dispatch_rs2_S=`Enable;
		if (T[ID_rs2]==1'b0) begin
			Dispatch_rs2_type=1'b0;
			Dispatch_rs2_value=V[ID_rs2];
		end
		else begin
			if (ROB_write_S==`Enable&&ROB_Reorder==Q[ID_rs2]) begin
				Dispatch_rs2_type=1'b0;
				Dispatch_rs2_value=ROB_result;
			end
			else begin
				Dispatch_rs2_type=1'b1;
				Dispatch_rs2_value={27'b0,Q[ID_rs2]};
			end
		end
	end
end

//update the information of Regfile after ROB's commit
always @(posedge clk) begin
	if (rst) begin
		for (i=0;i<`RegSIZE;i=i+1) begin
			V[i]<=0;
			T[i]<=1'b0;
		end
	end
	else if (clr) begin
		for (i=0;i<`RegSIZE;i=i+1) begin
			T[i]<=1'b0;
		end
		if (ROB_write_S==`Enable&&ROB_rd!=0) begin
			V[ROB_rd]<=ROB_result;
		end
	end
	else if (rdy) begin
		if (ROB_write_S==`Enable&&ROB_rd!=0&&Dispatch_writeQ_S==`Enable&&Dispatch_rd!=0) begin
			V[ROB_rd]<=ROB_result;
			if (ROB_rd!=Dispatch_rd&&Q[ROB_rd]==ROB_Reorder) begin
				T[ROB_rd]<=1'b0;
			end
			Q[Dispatch_rd]<=Dispatch_ROBpos;
			T[Dispatch_rd]<=1'b1;
		end
		else begin
			if (ROB_write_S==`Enable&&ROB_rd!=0) begin
				V[ROB_rd]<=ROB_result;
				if (Q[ROB_rd]==ROB_Reorder) begin
					T[ROB_rd]<=1'b0;
				end
			end
			if (Dispatch_writeQ_S==`Enable&&Dispatch_rd!=0) begin
				Q[Dispatch_rd]<=Dispatch_ROBpos;
				T[Dispatch_rd]<=1'b1;
			end
		end
	end
end

endmodule //Regfile