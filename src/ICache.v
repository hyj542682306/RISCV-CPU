module ICache (
	input  wire					clk,
	input  wire					rst,
	input  wire					rdy,

	input  wire					clr,

	//IF
	input  wire					IF_S,
	input  wire	[`AddrBus]		IF_pc,
	output	reg 				IF_success,
	output	reg [`InstBus]		IF_Inst,

	//Mem_ctrl
	input  wire					Mem_success,
	input  wire [`InstBus]		Mem_Inst,
	output	reg					Mem_S,
	output	reg [`AddrBus]		Mem_pc
);

integer							stall;

reg								valid[`ICacheSize];
reg	[`TagBus]					tag[`ICacheSize];
reg	[`DataBus]					data[`ICacheSize];

integer							i;

always @(posedge clk) begin
	if (rst) begin
		for (i=0;i<`CacheSize;i=i+1) begin
			valid[i]<=`False;
		end
		stall<=0;
	end
	else if (clr) begin
		Mem_S<=`Disable;
		IF_success<=`False;
	end
	else if (rdy) begin
		if (IF_S) begin
			// $display("ICache: IFpos: %h; stall: %d",IF_pc,stall);
			if (stall>0) begin
				Mem_S<=`Disable;
				IF_success<=`False;
				stall<=stall-1'b1;
			end
			else begin
				if (valid[IF_pc[`CacheIndex]]&&tag[IF_pc[`CacheIndex]]==IF_pc[`CacheTag]) begin
					Mem_S<=`Disable;
					IF_success<=`True;
					IF_Inst<=data[IF_pc[`CacheIndex]];
					stall<=1;
				end
				else begin
					if (Mem_success) begin
						Mem_S<=`Disable;
						valid[IF_pc[`CacheIndex]]<=`True;
						tag[IF_pc[`CacheIndex]]<=IF_pc[`CacheTag];
						data[IF_pc[`CacheIndex]]<=Mem_Inst;
						IF_success<=`True;
						IF_Inst<=Mem_Inst;
						stall<=1;
					end
					else begin
						Mem_S<=`Enable;
						Mem_pc<=IF_pc;
					end
				end
			end
		end
		else begin
			Mem_S<=`Disable;
			IF_success<=`False;
		end
	end
	else begin
		Mem_S<=`Disable;
		IF_success<=`False;
	end
end

endmodule //ICache