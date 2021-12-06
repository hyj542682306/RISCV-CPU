`include "Definition.v"

module Mem_ctrl (
	input  wire					clk,
	input  wire					rst,
	input  wire					rdy,

	//hci
	input  wire [ 7:0]			mem_din,
	output	reg [ 7:0]			mem_dout,

	//IF
	input  wire					IF_S,
	input  wire					IF_type,
	input  wire [`AddrBus]		IF_pos,
	input  wire	[`InstLen]		IF_len,
	output	reg					IF_success,
	output	reg	[`DataBus]		IF_value,

	//LSB
	input  wire					LSB_S,
	input  wire					LSB_type,
	input  wire	[`AddrBus]		LSB_pos,
	input  wire	[`InstLen]		LSB_len,
	output	reg					LSB_success,
	output	reg	[`DataBus]		LSB_value
);

always @(posedge clk) begin
	;
end

endmodule //Mem_ctrl