`include "Definition.v"

module IQ (
	input  wire					clk,
	input  wire					rst,  
	input  wire 				rdy,

	input  wire 				clr,

	//IQ
	output	reg					IQ_empty,
	output	reg					IQ_nxt_full,

	//IF
	input  wire					IF_S,
	input  wire	[`InstBus]		IF_Inst,
	input  wire	[`AddrBus]		IF_pc,

	//ID
	input  wire					ID_Success,
	output	reg	[`InstBus]		ID_Inst,
	output	reg	[`AddrBus]		ID_pc 
);

reg	[`InstBus]					Inst_queue[`IQBus];
reg	[`AddrBus]					pc_queue[`IQBus];
reg	[`IQBus]					head;
reg	[`IQBus]					tail;
reg								empty;

always @(posedge clk) begin
	if (rst||clr) begin
		head<=0;
		tail<=0;
		empty<=`True;
		IQ_empty<=`True;
		IQ_nxt_full<=`False;
		ID_Inst<=`Null;
		ID_pc<=`Null;
	end
	else if (rdy) begin
		IQ_empty<=empty;

		//full - nxt clk / after this clk
		IQ_nxt_full<=(head+ID_Success==tail+IF_S)&&(!empty);
		//empty - nxt clk / after this clk
		empty<=(head+ID_Success==tail+IF_S&&empty)
			 ||(head+ID_Success==tail+IF_S&&ID_Success&&(!IF_S));

		if (!empty) begin
			ID_Inst<=Inst_queue[head];
			ID_pc<=pc_queue[head];
		end
		else begin
			ID_Inst<=`Null;
			ID_pc<=`Null;
		end

		if (ID_Success) begin
			head<=head+1'b1;
		end

		if (IF_S) begin
			Inst_queue[tail]<=IF_Inst;
			pc_queue[tail]<=IF_pc;
			tail<=tail+1'b1;
		end
	end
	else begin
		IQ_empty<=`True;
		ID_Inst<=`Null;
		ID_pc<=`Null;
	end
end

endmodule //IQ