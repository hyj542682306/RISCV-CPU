`include "Definition.v"

module ID (
	//IQ
	input  wire					IQ_Empty,
	input  wire	[`InstBus]		IQ_Inst,
	input  wire	[`AddrBus]		IQ_pc,
	output	reg  				IQ_Success,

	//Regfile
	output	reg  				Reg_rs1_S,
	output	reg	[`RegBus] 		Reg_rs1,
	output	reg  				Reg_rs2_S,
	output	reg	[`RegBus] 		Reg_rs2,

	//Dispatch
	output	reg					Dispatch_S,
	output	reg					Dispatch_A,
	output	reg					Dispatch_rd,
	output	reg	[`OpBus]		Dispatch_Op,
	output	reg	[`AddrBus]		Dispatch_pc,

	//ROB
	input  wire					ROB_Full,
	input  wire	[`ROBBus]		ROB_pos,
	output	reg					ROB_S,

	//RS
	input  wire					RS_Full,
	output	reg					RS_S,

	//LSB
	input  wire 				LSB_Full,
	output	reg					LSB_S
);

always @(*) begin

	Reg_rs1_S=`Disable;
	Reg_rs2_S=`Disable;

	Dispatch_S=`Disable;

	ROB_S=`Disable;
	RS_S=`Disable;
	LSB_S=`Disable;

	if (IQ_Empty==`True||RS_Full==`True||ROB_Full==`True||LSB_Full==`True) begin
		IQ_Success=`False;
	end
	else begin
		ROB_S=`Enable;
		RS_S=`Enable;
		LSB_S=`Enable;
		IQ_Success=`True;
		Dispatch_S=`Enable;
		Dispatch_pc=IQ_pc;
		case (IQ_Inst[6:0])

			7'b0110111: begin
				Dispatch_Op=`LUI;
				Dispatch_A={IQ_Inst[31:12],12'b0};
				Dispatch_rd=IQ_Inst[11:7];
			end

			7'b0010111: begin
				Dispatch_Op=`AUIPC;
				Dispatch_A={IQ_Inst[31:12],12'b0};
				Dispatch_rd=IQ_Inst[11:7];
			end

			7'b1101111: begin
				Dispatch_Op=`JAL;
				Dispatch_A={{12{IQ_Inst[31]}},IQ_Inst[19:12],IQ_Inst[20],IQ_Inst[30:21],1'b0};
				Dispatch_rd=IQ_Inst[11:7];
			end

			7'b1100111: begin
				Dispatch_Op=`JALR;
				Dispatch_A={{21{IQ_Inst[31]}},IQ_Inst[30:20]};
				Dispatch_rd=IQ_Inst[11:7];
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
			end

			7'b1100011: begin
				case (IQ_Inst[14:12])
					3'b000: Dispatch_Op=`BEQ;
					3'b001: Dispatch_Op=`BNE;
					3'b100: Dispatch_Op=`BLT;
					3'b101: Dispatch_Op=`BGE;
					3'b110: Dispatch_Op=`BLTU;
					3'b111: Dispatch_Op=`BGEU;
				endcase
				Dispatch_A={{20{IQ_Inst[31]}},IQ_Inst[7],IQ_Inst[30:25],IQ_Inst[11:8],1'b0};
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
				Reg_rs2_S=`Enable;
				Reg_rs2=IQ_Inst[24:20];
			end

			7'b0000011: begin
				case (IQ_Inst[14:12])
					3'b000: Dispatch_Op=`LB;
					3'b001: Dispatch_Op=`LH;
					3'b010: Dispatch_Op=`LW;
					3'b100: Dispatch_Op=`LBU;
					3'b101: Dispatch_Op=`LHU;
				endcase
				Dispatch_A={{21{IQ_Inst[31]}},IQ_Inst[30:20]};
				Dispatch_rd=IQ_Inst[11:7];
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
			end

			7'b0100011: begin
				case (IQ_Inst[14:12])
					3'b000: Dispatch_Op=`SB;
					3'b001: Dispatch_Op=`SH;
					3'b010: Dispatch_Op=`SW;
				endcase
				Dispatch_A={{21{IQ_Inst[31]}},IQ_Inst[30:25],IQ_Inst[11:7]};
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
				Reg_rs2_S=`Enable;
				Reg_rs2=IQ_Inst[24:20];
			end

			7'b0010011: begin
				case (IQ_Inst[14:12])
					3'b000: Dispatch_Op=`ADDI;
					3'b010: Dispatch_Op=`SLTI;
					3'b011: Dispatch_Op=`SLTIU;
					3'b100: Dispatch_Op=`XORI;
					3'b110: Dispatch_Op=`ORI;
					3'b111: Dispatch_Op=`ANDI;
					3'b001: Dispatch_Op=`SLLI;
					3'b101: begin
						case (IQ_Inst[31:26])
							7'b0000000: Dispatch_Op=`SRLI;
							7'b0100000: Dispatch_Op=`SRAI;
						endcase
					end
				endcase
				Dispatch_A={{21{IQ_Inst[31]}},IQ_Inst[30:20]};
				Dispatch_rd=IQ_Inst[11:7];
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
			end

			7'b0110011: begin
				case (IQ_Inst[14:12])
					3'b000: begin
						case (IQ_Inst[31:26])
							7'b0000000: Dispatch_Op=`ADD;
							7'b0100000: Dispatch_Op=`SUB;
						endcase
					end
					3'b001: Dispatch_Op=`SLL;
					3'b010: Dispatch_Op=`SLT;
					3'b011: Dispatch_Op=`SLTU;
					3'b100: Dispatch_Op=`XOR;
					3'b101: begin
						case (IQ_Inst[31:26])
							7'b0000000: Dispatch_Op=`SRL;
							7'b0100000: Dispatch_Op=`SRA;
						endcase
					end
					3'b110: Dispatch_Op=`OR;
					3'b111: Dispatch_Op=`AND;
				endcase
				Dispatch_rd=IQ_Inst[11:7];
				Reg_rs1_S=`Enable;
				Reg_rs1=IQ_Inst[19:15];
				Reg_rs2_S=`Enable;
				Reg_rs2=IQ_Inst[24:20];
			end

		endcase
	end
end

endmodule //ID