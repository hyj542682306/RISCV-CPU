`include "Definition.v"

module ALU (
	//ALU
	output reg  			CDB_ALU_S,
	output reg[`ROBBus]		CDB_ALU_Reorder,
	output reg[`DataBus]	CDB_ALU_Value,
	output reg 				CDB_ALU_Jump_S,
	output reg[`DataBus]	CDB_ALU_Jump,

	//RS
	input  wire 			ALU_S,
	input  wire[`OpBus]		Op,
	input  wire[`DataBus]	Vj,
	input  wire[`DataBus]	Vk,
	input  wire[`RegBus]	Reorder,
	input  wire[`DataBus]	A,
	input  wire[`AddrBus]	pc
);

always @(*) begin
	CDB_ALU_Reorder=`Null;
	CDB_ALU_Value=`Null;
	CDB_ALU_Jump_S=`Disable;
	CDB_ALU_Jump=`Null;
	if (ALU_S==`Disable) begin
		CDB_ALU_S=`Disable;
	end
	else begin
		CDB_ALU_S=`Enable;
		CDB_ALU_Reorder=Reorder;
		case (Op)

			`LUI: CDB_ALU_Value=A;

			`AUIPC: CDB_ALU_Value=pc+A;

			`JAL: begin
				CDB_ALU_Value=pc+3'b100;
				CDB_ALU_Jump_S=`Enable;
				CDB_ALU_Jump=pc+A;
			end

			`JALR: begin
				CDB_ALU_Value=pc+3'b100;
				CDB_ALU_Jump_S=`Enable;
				CDB_ALU_Jump=(Vj+A)&~1'b1;
			end

			`BEQ: begin
				if (Vj==Vk) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`BNE: begin
				if (Vj!=Vk) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`BLT: begin
				if ($signed(Vj)<$signed(Vk)) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`BGE: begin
				if ($signed(Vj)>=$signed(Vk)) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`BLTU: begin
				if (Vj<Vk) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`BGEU: begin
				if (Vj>=Vk) begin
					CDB_ALU_Jump_S=`Enable;
					CDB_ALU_Jump=pc+A;
				end
			end

			`ADDI: CDB_ALU_Value=Vj+A;

			`SLTI: CDB_ALU_Value=$signed(Vj)<$signed(A);

			`SLTIU: CDB_ALU_Value=Vj<A;

			`XORI: CDB_ALU_Value=Vj^A;

			`ORI: CDB_ALU_Value=Vj|A;

			`ANDI: CDB_ALU_Value=Vj&A;

			`SLLI: CDB_ALU_Value=Vj<<A[5:0];

			`SRLI: CDB_ALU_Value=Vj>>A[5:0];

			`SRAI: CDB_ALU_Value=$signed(Vj)>>A[5:0];

			`ADD: CDB_ALU_Value=Vj+Vk;

			`SUB: CDB_ALU_Value=Vj-Vk;

			`SLL: CDB_ALU_Value=Vj<<Vk[5:0];

			`SLT: CDB_ALU_Value=$signed(Vj)<$signed(Vk);

			`SLTU: CDB_ALU_Value=Vj^Vk;

			`SRL: CDB_ALU_Value=Vj>>Vk[5:0];

			`SRA: CDB_ALU_Value=$signed(Vj)>>Vk[5:0];

			`OR: CDB_ALU_Value=Vj|Vk;

			`AND: CDB_ALU_Value=Vj&Vk;

		endcase
	end
end

endmodule //ALU