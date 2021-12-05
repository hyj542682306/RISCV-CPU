`include "D:\2021-2022-1\system\work\CPU\riscv\src\Definition.v"

module Dispatch (
	//ID
	input  wire				Dispatch_S,
	input  wire				A,
	input  wire 			rd,
	input  wire[`OpBus] 	Op,
	input  wire[`AddrBus]	pc,

	//Regfile
	input  wire 			rs1_S,
	input  wire 			rs1_type,
	input  wire[`DataBus]	rs1_value,
	input  wire 			rs2_S,
	input  wire[`DataBus]	rs2_type,
	input  wire 			rs2_value,
	
	//ROB
	input  wire				,
	input  wire
);

endmodule //Dispatch