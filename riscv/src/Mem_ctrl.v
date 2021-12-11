module Mem_ctrl (
	input  wire					clk,
	input  wire					rst,
	input  wire					rdy,

	input  wire					clr,

	//hci
	input  wire [ 7:0]			mem_din,
	output	reg [ 7:0]			mem_dout,
	output	reg [31:0]			mem_a,
	output	reg					mem_wr,

	input  wire					io_buffer_full,

	//ICache
	input  wire					IC_S,
	input  wire [`AddrBus]		IC_pos,
	output	reg					IC_success,
	output	reg	[`DataBus]		IC_value,

	//LSB
	input  wire					LSB_S,
	input  wire					LSB_type,
	input  wire	[`AddrBus]		LSB_pos,
	input  wire	[`InstLen]		LSB_len,
	input  wire [`DataBus]		LSB_result,
	output	reg					LSB_success,
	output	reg	[`DataBus]		LSB_value
);

integer							stall;

reg								work;
reg								boss; //0: LSB, 1:IF
reg 							type;
reg	[`AddrBus]					startpos;
reg [`InstLen]					len;
reg [`DataBus]					result;
reg [`InstLen]					done;
reg [`DataBus]					data;

always @(posedge clk) begin
	if (rst) begin
		work<=`False;
		stall<=0;
		IC_success<=`False;
		LSB_success<=`False;
		type<=0;
		startpos<=0;
		mem_wr<=0;
		mem_a<=`Null;
	end
	else if (clr) begin
		if (work&&type==1) begin
			if (startpos[17:16]==2'b11) begin
				IC_success<=`False;
				LSB_success<=`True;
				work<=`False;
				mem_wr<=0;
				mem_a<=`Null;
			end
			else begin
				if (done==len-3'b001) begin
					IC_success<=`False;
					LSB_success<=`True;
					work<=`False;
					mem_wr<=0;
					mem_a<=`Null;
					// $display("Mem WRITE SUCCESS! startpos: %h result: %h",startpos,data);
				end
				else begin
					LSB_success<=`False;
					IC_success<=`False;
					mem_wr<=1;
					case (done)
						3'b000: begin
							mem_dout<=result[15:8];
							mem_a<=startpos+3'b001;
						end
						3'b001: begin
							mem_dout<=result[23:16];
							mem_a<=startpos+3'b010;
						end
						3'b010: begin
							mem_dout<=result[31:24];
							mem_a<=startpos+3'b011;
						end
					endcase
					done<=done+3'b001;
				end
			end
		end
		else begin
			work<=`False;
			stall<=0;
			IC_success<=`False;
			LSB_success<=`False;
			type<=0;
			startpos<=0;
			mem_wr<=0;
			mem_a<=`Null;
		end
	end
	else if (rdy) begin
		if (work) begin
			//read (IC/LSB) -> 0 stall
			if (type==0) begin
				if (done==len+1'b1) begin
					if (boss==0) begin
						LSB_success<=`True;
						LSB_value<=data;
						IC_success<=`False;
					end
					else begin
						IC_success<=`True;
						IC_value<=data;
						LSB_success<=`False;
					end
					// $display("Mem READ SUCCESS! startpos: %h; data: %h",startpos,data);
					work<=`False;
					mem_wr<=0;
					mem_a<=`Null;
				end
				else begin
					LSB_success<=`False;
					IC_success<=`False;
					mem_wr<=0;
					case (done)
						3'b000: begin
							mem_a<=startpos+3'b001;
						end
						3'b001: begin
							data[7:0]<=mem_din;
							mem_a<=startpos+3'b010;
						end
						3'b010: begin
							data[15:8]<=mem_din;
							mem_a<=startpos+3'b011;
						end
						3'b011: begin
							data[23:16]<=mem_din;
							mem_a<=`Null;
						end
						3'b100: begin
							data[31:24]<=mem_din;
							mem_a<=`Null;
						end
					endcase
					done<=done+3'b001;
				end
			end
			//I/O write (LSB) only SB -> !io_buffer_full
			else if (type==1&&startpos[17:16]==2'b11) begin
				IC_success<=`False;
				LSB_success<=`True;
				work<=`False;
				mem_wr<=0;
				mem_a<=`Null;
			end
			//mem write (LSB) -> 0 stall
			else begin
				if (done==len-3'b001) begin
					IC_success<=`False;
					LSB_success<=`True;
					work<=`False;
					mem_wr<=0;
					mem_a<=`Null;
				end
				else begin
					LSB_success<=`False;
					IC_success<=`False;
					mem_wr<=1;
					case (done)
						3'b000: begin
							mem_dout<=result[15:8];
							mem_a<=startpos+3'b001;
						end
						3'b001: begin
							mem_dout<=result[23:16];
							mem_a<=startpos+3'b010;
						end
						3'b010: begin
							mem_dout<=result[31:24];
							mem_a<=startpos+3'b011;
						end
					endcase
					done<=done+3'b001;
				end
			end
		end
		else begin
			if (LSB_S) begin
				//now I/O write -> 3 stalls
				if (LSB_pos[17:16]==2'b11&&LSB_type==1) begin
					if (stall>=2'b11&&(!io_buffer_full)) begin
						stall<=0;
						work<=`True;
						boss<=0;
						type<=LSB_type;
						startpos<=LSB_pos;
						len<=LSB_len;
						result<=LSB_result;
						done<=0;
						data<=0;
						mem_wr<=LSB_type;
						mem_a<=LSB_pos;
						mem_dout<=LSB_result[7:0];
						IC_success<=`False;
						LSB_success<=`False;
					end
					else begin
						stall<=stall+1'b1;
						IC_success<=`False;
						LSB_success<=`False;
						mem_wr<=0;
						mem_a<=`Null;
						mem_dout<=`Null;
					end
				end
				//else -> 1 stall
				else begin
					if (stall>=1) begin
						stall<=0;
						work<=`True;
						boss<=0;
						type<=LSB_type;
						startpos<=LSB_pos;
						len<=LSB_len;
						result<=LSB_result;
						done<=0;
						data<=0;
						mem_wr<=LSB_type;
						mem_a<=LSB_pos;
						mem_dout<=LSB_result[7:0];
						IC_success<=`False;
						LSB_success<=`False;
					end
					else begin
						stall<=stall+1'b1;
						IC_success<=`False;
						LSB_success<=`False;
						mem_wr<=0;
						mem_a<=`Null;
						mem_dout<=`Null;
					end
				end
			end
			//IC read - 1 stall
			else if (IC_S) begin
				if (stall>=1) begin
					stall<=0;
					work<=`True;
					boss<=1;
					type<=0;
					startpos<=IC_pos;
					len<=3'b100;
					done<=0;
					data<=0;
					mem_wr<=0;
					mem_a<=IC_pos;
					IC_success<=`False;
					LSB_success<=`False;
				end
				else begin
					stall<=stall+1'b1;
					IC_success<=`False;
					LSB_success<=`False;
					mem_wr<=0;
					mem_a<=`Null;
					mem_dout<=`Null;
				end
			end
			else begin
				IC_success<=`False;
				LSB_success<=`False;
				mem_wr<=0;
				mem_a<=`Null;
				mem_dout<=`Null;
			end
		end
	end
	else begin
		IC_success<=`False;
		LSB_success<=`False;
		mem_wr<=0;
		mem_a<=`Null;
	end
end

endmodule //Mem_ctrl