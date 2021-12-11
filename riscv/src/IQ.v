module IQ (
	input  wire					clk,
	input  wire					rst,  
	input  wire 				rdy,

	input  wire 				clr,

	//IQ
	output	reg					IQ_full,

	//IF
	input  wire					IF_S,
	input  wire	[`InstBus]		IF_Inst,
	input  wire	[`AddrBus]		IF_pc,

	//ID
	input  wire					ID_Success,
	output	reg					ID_S,
	output	reg	[`InstBus]		ID_Inst,
	output	reg	[`AddrBus]		ID_pc 
);

reg	[`InstBus]					Inst_queue[`IQSize];
reg	[`AddrBus]					pc_queue[`IQSize];
reg	[`IQBus]					head;
reg	[`IQBus]					tail;

integer							qSize;

//whether the IQ is empty or full
always @(*) begin
	IQ_full=(qSize==`SIZE);
end

always @(posedge clk) begin
	if (rst||clr) begin
		head<=0;
		tail<=0;
		qSize<=0;
		ID_S<=`Disable;
	end
	else if (rdy) begin
		if (qSize-ID_Success>0) begin
			ID_S<=`Enable;
			ID_Inst<=Inst_queue[head+ID_Success];
			ID_pc<=pc_queue[head+ID_Success];
		end
		else begin
			ID_S<=`Disable;
		end

		if (ID_Success) begin
			head<=head+1'b1;
		end

		if (IF_S) begin
			Inst_queue[tail]<=IF_Inst;
			pc_queue[tail]<=IF_pc;
			tail<=tail+1'b1;
		end

		qSize<=qSize+IF_S-ID_Success;
	end
	else begin
		ID_S<=`Disable;
	end
end

endmodule //IQ