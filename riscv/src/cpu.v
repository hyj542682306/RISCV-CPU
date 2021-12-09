// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/Definition.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/hci.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/ram.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/Mem_ctrl.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/ALU.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/Dispatch.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/ICache.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/ID.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/IF.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/IQ.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/LSB.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/Regfile.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/ROB.v"
`include "/mnt/d/2021-2022-1/system/work/CPU/riscv/src/RS.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire clr;

//Mem_ctrl <-> ICache
wire                IC_Mem_S;
wire [`AddrBus]     IC_Mem_pc;
wire                Mem_IC_success;
wire [`InstBus]     Mem_IC_Inst;

//Mem_ctrl <-> LSB
wire                LSB_Mem_S;
wire                LSB_Mem_type;
wire [`AddrBus]     LSB_Mem_pc;
wire [`InstLen]     LSB_Mem_len;
wire [`DataBus]     LSB_Mem_result;
wire                Mem_LSB_success;
wire [`DataBus]     Mem_LSB_value;

//CDB_ALU
wire                CDB_ALU_S;
wire [`ROBBus]      CDB_ALU_Reorder;
wire [`DataBus]     CDB_ALU_Value;
wire                CDB_ALU_Jump_S;
wire [`AddrBus]     CDB_ALU_Jump;

//RS -> ALU
wire                RS_ALU_S;
wire [`OpBus]       RS_ALU_Op;
wire [`DataBus]     RS_ALU_Vj;
wire [`DataBus]     RS_ALU_Vk;
wire [`ROBBus]      RS_ALU_Reorder;
wire [`DataBus]     RS_ALU_A;
wire [`AddrBus]     RS_ALU_pc;

//ID -> Dispatch
wire                ID_Dispatch_S;
wire [`DataBus]     ID_Dispatch_A;
wire [`RegBus]      ID_Dispatch_rd;
wire [`OpBus]       ID_Dispatch_Op;
wire [`AddrBus]     ID_Dispatch_pc;

//Dispatch
wire [`OpBus]       Dispatch_Op;
wire [`DataBus]     Dispatch_A;
wire [`RegBus]		  Dispatch_rd;
wire [`ROBBus]		  Dispatch_Reorder;
wire [`AddrBus]		  Dispatch_pc;
wire                Dispatch_Type_j;
wire [`DataBus]		  Dispatch_Value_j;
wire 				        Dispatch_Type_k;
wire [`DataBus]		  Dispatch_Value_k;

//Dispatch <-> Regfile
wire                Reg_Dispatch_rs1_S;
wire 				        Reg_Dispatch_rs1_type;
wire [`DataBus]		  Reg_Dispatch_rs1_value;
wire 				        Reg_Dispatch_rs2_S;
wire					      Reg_Dispatch_rs2_type;
wire [`DataBus]		  Reg_Dispatch_rs2_value;
wire					      Dispatch_Reg_writeQ_S;

//Dispatch <-> RS
wire [`RSBus]       RS_Dispatch_las_pos;
wire                RS_Dispatch_las_ready;
wire [`RSBus]		    RS_Dispatch_las_ready_pos;
wire					      Dispatch_RS_S;
wire [`RSBus]		    Dispatch_RS_pos;
wire					      Dispatch_RS_ready;
wire [`DataBus]     Dispatch_RS_ready_pos;

//Dispatch -> LSB
wire                Dispatch_LSB_S;

//Dispatch <-> ROB
wire [`ROBBus]      ROB_Dispatch_nxtpos;
wire                Dispatch_ROB_S;
wire					      ROB_Dispatch_rs1_already;
wire [`DataBus]		  ROB_Dispatch_rs1_value;
wire					      ROB_Dispatch_rs2_already;
wire [`DataBus]		  ROB_Dispatch_rs2_value;
wire				      	Dispatch_ROB_rs1_S;
wire [`ROBBus]	  	Dispatch_ROB_rs1_Reorder;
wire 			        	Dispatch_ROB_rs2_S;
wire [`ROBBus]	  	Dispatch_ROB_rs2_Reorder;

//IF <-> ICache
wire                IF_IC_S;
wire [`AddrBus]     IF_IC_pc;
wire                IC_IF_success;
wire [`InstBus]     IC_IF_Inst;

//ID <-> IQ
wire                IQ_ID_S;
wire [`InstBus]     IQ_ID_Inst;
wire [`AddrBus]     IQ_ID_pc;
wire                ID_IQ_success;

//ID -> Regfile
wire                ID_Reg_rs1_S;
wire [`RegBus]      ID_Reg_rs1;
wire                ID_Reg_rs2_S;
wire [`RegBus]      ID_Reg_rs2;

//ID <-> ROB
wire                ROB_ID_full;
wire                ID_ROB_S;

//ID <-> RS
wire                RS_ID_full;
wire                ID_RS_S;

//ID <-> LSB
wire                LSB_ID_full;

//IF <-> IQ
wire                IQ_IF_full;
wire                IF_IQ_S;
wire [`InstBus]     IF_IQ_Inst;
wire [`InstBus]     IF_IQ_pc;

//ROB -> IF
wire                ROB_IF_Jump_S;
wire [`AddrBus]     ROB_IF_Jump;

//CDB_LSB
wire                CDB_LSB_S;
wire [`ROBBus]      CDB_LSB_Reorder;
wire [`DataBus]     CDB_LSB_Value;

//ROB -> LSB
wire 		        		ROB_LSB_store_S;
wire [`ROBBus]  		ROB_LSB_store_Reorder;
wire			      		ROB_LSB_Update1_S;
wire [`ROBBus]	  	ROB_LSB_Update1_Reorder;
wire [`DataBus]	  	ROB_LSB_Update1_Value;
wire				      	ROB_LSB_Update2_S;
wire [`ROBBus]	  	ROB_LSB_Update2_Reorder;
wire [`DataBus]	  	ROB_LSB_Update2_Value;

//ROB -> Regfile
wire					      ROB_Reg_write_S;
wire [`RegBus] 	   	ROB_Reg_rd;
wire [`ROBBus]	  	ROB_Reg_Reorder;
wire [`DataBus]	  	ROB_Reg_result;

Mem_ctrl  Mem_ctrl(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .clr(clr),

  //hci
  .mem_din(mem_din),
  .mem_dout(mem_dout),
  .mem_a(mem_a),
  .mem_wr(mem_wr),

  .io_buffer_full(io_buffer_full),

  //ICache
  .IC_S(IC_Mem_S),
  .IC_pos(IC_Mem_pc),
  .IC_success(Mem_IC_success),
  .IC_value(Mem_IC_Inst),

  //LSB
  .LSB_S(LSB_Mem_S),
  .LSB_type(LSB_Mem_type),
  .LSB_pos(LSB_Mem_pc),
  .LSB_len(LSB_Mem_len),
  .LSB_result(LSB_Mem_result),
  .LSB_success(Mem_LSB_success),
  .LSB_value(Mem_LSB_value)
);

ALU ALU(
  //ALU
  .CDB_ALU_S(CDB_ALU_S),
  .CDB_ALU_Reorder(CDB_ALU_Reorder),
  .CDB_ALU_Value(CDB_ALU_Value),
  .CDB_ALU_Jump_S(CDB_ALU_Jump_S),
  .CDB_ALU_Jump(CDB_ALU_Jump),

  //RS
  .ALU_S(RS_ALU_S),
  .Op(RS_ALU_Op),
  .Vj(RS_ALU_Vj),
  .Vk(RS_ALU_Vk),
  .Reorder(RS_ALU_Reorder),
  .A(RS_ALU_A),
  .pc(RS_ALU_pc)
);

Dispatch  Dispatch(
  //ID
  .Dispatch_S(ID_Dispatch_S),
  .A(ID_Dispatch_A),
  .rd(ID_Dispatch_rd),
  .Op(ID_Dispatch_Op),
  .pc(ID_Dispatch_pc),

  //Dispatch
  .Dispatch_Op(Dispatch_Op),
  .Dispatch_A(Dispatch_A),
  .Dispatch_rd(Dispatch_rd),
  .Dispatch_Reorder(Dispatch_Reorder),
  .Dispatch_pc(Dispatch_pc),
  .Dispatch_Type_j(Dispatch_Type_j),
  .Dispatch_Value_j(Dispatch_Value_j),
  .Dispatch_Type_k(Dispatch_Type_k),
  .Dispatch_Value_k(Dispatch_Value_k),

  //Regfile
  .rs1_S(Reg_Dispatch_rs1_S),
  .rs1_type(Reg_Dispatch_rs1_type),
  .rs1_value(Reg_Dispatch_rs1_value),
  .rs2_S(Reg_Dispatch_rs2_S),
  .rs2_type(Reg_Dispatch_rs2_type),
  .rs2_value(Reg_Dispatch_rs2_value),
  .Reg_writeQ_S(Dispatch_Reg_writeQ_S),

  //RS
  .RS_las_pos(RS_Dispatch_las_pos),
  .RS_las_ready(RS_Dispatch_las_ready),
  .RS_las_ready_pos(RS_Dispatch_las_ready_pos),
  .RS_S(Dispatch_RS_S),
  .RS_pos(Dispatch_RS_pos),
  .RS_ready(Dispatch_RS_ready),
  .RS_ready_pos(Dispatch_RS_ready_pos),

  //LSB
  .LSB_S(Dispatch_LSB_S),

  //ROB
  .ROB_nxtpos(ROB_Dispatch_nxtpos),
  .ROB_S(Dispatch_ROB_S),

  .ROB_rs1_already(ROB_Dispatch_rs1_already),
  .ROB_rs1_value(ROB_Dispatch_rs1_value),
  .ROB_rs2_already(ROB_Dispatch_rs2_already),
  .ROB_rs2_value(ROB_Dispatch_rs2_value),
  .ROB_rs1_S(Dispatch_ROB_rs1_S),
  .ROB_rs1_Reorder(Dispatch_ROB_rs1_Reorder),
  .ROB_rs2_S(Dispatch_ROB_rs2_S),
  .ROB_rs2_Reorder(Dispatch_ROB_rs2_Reorder)
);

ICache  ICache(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  //IF
  .IF_S(IF_IC_S),
  .IF_pc(IF_IC_pc),
  .IF_success(IC_IF_success),
  .IF_Inst(IC_IF_Inst),

  //Mem_ctrl
  .Mem_success(Mem_IC_success),
  .Mem_Inst(Mem_IC_Inst),
  .Mem_S(IC_Mem_S),
  .Mem_pc(IC_Mem_pc)
);

ID  ID(
  //IQ
  .IQ_S(IQ_ID_S),
  .IQ_Inst(IQ_ID_Inst),
  .IQ_pc(IQ_ID_pc),
  .IQ_Success(ID_IQ_success),

  //Regfile
  .Reg_rs1_S(ID_Reg_rs1_S),
  .Reg_rs1(ID_Reg_rs1),
  .Reg_rs2_S(ID_Reg_rs2_S),
  .Reg_rs2(ID_Reg_rs2),

  //Dispatch
  .Dispatch_S(ID_Dispatch_S),
  .Dispatch_A(ID_Dispatch_A),
  .Dispatch_rd(ID_Dispatch_rd),
  .Dispatch_Op(ID_Dispatch_Op),
  .Dispatch_pc(ID_Dispatch_pc),

  //ROB
  .ROB_Full(ROB_ID_full),
  .ROB_S(ID_ROB_S),

  //RS
  .RS_Full(RS_ID_full),
  .RS_S(ID_RS_S),

  //LSB
  .LSB_Full(LSB_ID_full)
);

IF  IF(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  //ICache
  .IC_success(IC_IF_success),
  .IC_value(IC_IF_Inst),
  .IC_S(IF_IC_S),
  .IC_pc(IF_IC_pc),

  //IQ
  .IQ_full(IQ_ID_full),
  .IQ_S(IF_IQ_S),
  .IQ_Inst(IF_IQ_Inst),
  .IQ_pc(IF_IQ_pc),

  //ROB
  .ROB_Jump_S(ROB_IF_Jump_S),
  .ROB_Jump(ROB_IF_Jump)
);

IQ  IQ(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .clr(clr),

  //IQ
  .IQ_full(IQ_IF_full),

  //IF
  .IF_S(IF_IQ_S),
  .IF_Inst(IF_IQ_Inst),
  .IF_pc(IF_IQ_pc),

  //ID
  .ID_Success(ID_IQ_success),
  .ID_S(IQ_ID_S),
  .ID_Inst(IQ_ID_Inst),
  .ID_pc(IQ_ID_pc)
);

LSB  LSB(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .clr(clr),

  //Mem_ctrl
  .Mem_success(Mem_LSB_success),
  .Mem_value(Mem_LSB_value),
  .Mem_S(LSB_Mem_S),
  .Mem_op(LSB_Mem_type),
  .Mem_pc(LSB_Mem_pc),
  .Mem_len(LSB_Mem_len),
  .Mem_result(LSB_Mem_result),

  //LSB
  .LSB_nxt_full(LSB_ID_full),
  .CDB_LSB_S(CDB_LSB_S),
  .CDB_LSB_Reorder(CDB_LSB_Reorder),
  .CDB_LSB_Value(CDB_LSB_Value),

  //Dispatch
  .Dispatch_S(Dispatch_LSB_S),
  .Dispatch_Op(Dispatch_Op),
  .Dispatch_A(Dispatch_A),
  .Dispatch_Reorder(Dispatch_Reorder),
  .Dispatch_pc(Dispatch_pc),
  .Dispatch_Type_j(Dispatch_Type_j),
  .Dispatch_Value_j(Dispatch_Value_j),
  .Dispatch_Type_k(Dispatch_Type_k),
  .Dispatch_Value_k(Dispatch_Value_k),

  //ROB
  .ROB_store_S(ROB_LSB_store_S),
  .ROB_store_Reorder(ROB_LSB_store_Reorder),
  .ROB_Update1_S(ROB_LSB_Update1_S),
  .ROB_Update1_Reorder(ROB_LSB_Update1_Reorder),
  .ROB_Update1_Value(ROB_LSB_Update1_Value),
  .ROB_Update2_S(ROB_LSB_Update2_S),
  .ROB_Update2_Reorder(ROB_LSB_Update2_Reorder),
  .ROB_Update2_Value(ROB_LSB_Update2_Value)
);

Regfile  Regfile(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .clr(clr),

  //ID
  .ID_rs1_S(ID_Reg_rs1_S),
  .ID_rs1(ID_Reg_rs1),
  .ID_rs2_S(ID_Reg_rs2_S),
  .ID_rs2(ID_Reg_rs2),

  //Dispatch
  .Dispatch_rs1_S(Reg_Dispatch_rs1_S),
  .Dispatch_rs1_type(Reg_Dispatch_rs1_type),
  .Dispatch_rs1_value(Reg_Dispatch_rs1_value),
  .Dispatch_rs2_S(Reg_Dispatch_rs2_S),
  .Dispatch_rs2_type(Reg_Dispatch_rs2_type),
  .Dispatch_rs2_value(Reg_Dispatch_rs2_value),
  .Dispatch_writeQ_S(Dispatch_Reg_writeQ_S),
  .Dispatch_rd(Dispatch_rd),
  .Dispatch_ROBpos(Dispatch_Reorder),

  //ROB
  .ROB_write_S(ROB_Reg_write_S),
  .ROB_rd(ROB_Reg_rd),
  .ROB_Reorder(ROB_Reg_Reorder),
  .ROB_result(ROB_Reg_result)
);

ROB  ROB(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  //ROB
  .ROB_nxt_full(ROB_ID_full),
  .clr(clr),
  .ROB_nxt_pos(ROB_Dispatch_nxtpos),

  //IF
  .IF_Jump_S(ROB_IF_Jump_S),
  .IF_Jump(ROB_IF_Jump),

  //ID
  .ID_S(ID_ROB_S),

  //Dispatch
  .Dispatch_S(Dispatch_ROB_S),
  .Dispatch_Op(Dispatch_Op),
  .Dispatch_rd(Dispatch_rd),
  .Dispatch_pc(Dispatch_pc),
  .Dispatch_rs1_S(Dispatch_ROB_rs1_S),
  .Dispatch_rs1_Reorder(Dispatch_ROB_rs1_Reorder),
  .Dispatch_rs2_S(Dispatch_ROB_rs2_S),
  .Dispatch_rs2_Reorder(Dispatch_ROB_rs2_Reorder),
  .Dispatch_rs1_already(ROB_Dispatch_rs1_already),
  .Dispatch_rs1_value(ROB_Dispatch_rs1_value),
  .Dispatch_rs2_already(ROB_Dispatch_rs2_already),
  .Dispatch_rs2_value(ROB_Dispatch_rs2_value),

  //ALU
  .ALU_S(CDB_ALU_S),
  .ALU_Reorder(CDB_ALU_Reorder),
  .ALU_Value(CDB_ALU_Value),
  .ALU_Jump_S(CDB_ALU_Jump_S),
  .ALU_Jump(CDB_ALU_Jump),

  //Regfile
  .Reg_write_S(ROB_Reg_write_S),
  .Reg_rd(ROB_Reg_rd),
  .Reg_Reorder(ROB_Reg_Reorder),
  .Reg_result(ROB_Reg_result),

  //LSB
  .LSB_load_S(CDB_LSB_S),
  .LSB_load_Reorder(CDB_LSB_Reorder),
  .LSB_load_Value(CDB_LSB_Value),
  .LSB_store_S(ROB_LSB_store_S),
  .LSB_store_Reorder(ROB_LSB_store_Reorder),
  .LSB_Update1_S(ROB_LSB_Update1_S),
  .LSB_Update1_Reorder(ROB_LSB_Update1_Reorder),
  .LSB_Update1_Value(ROB_LSB_Update1_Value),
  .LSB_Update2_S(ROB_LSB_Update2_S),
  .LSB_Update2_Reorder(ROB_LSB_Update2_Reorder),
  .LSB_Update2_Value(ROB_LSB_Update2_Value)
);

RS  RS(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  
  .clr(clr),

  //RS
  .RS_nxt_full(RS_ID_full),
  .RS_nxt_pos(RS_Dispatch_las_pos),
  .RS_nxt_ready(RS_Dispatch_las_ready),
  .RS_nxt_ready_pos(RS_Dispatch_las_ready_pos),

  //ID
  .ID_S(ID_RS_S),

  //Dispatch
  .Dispatch_S(Dispatch_RS_S),
  .Dispatch_pos(Dispatch_RS_pos),
  .Dispatch_Op(Dispatch_Op),
  .Dispatch_A(Dispatch_A),
  .Dispatch_Reorder(Dispatch_Reorder),
  .Dispatch_pc(Dispatch_pc),
  .Dispatch_Type_j(Dispatch_Type_j),
  .Dispatch_Value_j(Dispatch_Value_j),
  .Dispatch_Type_k(Dispatch_Type_k),
  .Dispatch_Value_k(Dispatch_Value_k),
  .Dispatch_ready(Dispatch_RS_ready),
  .Dispatch_ready_pos(Dispatch_RS_ready_pos),

  //ALU
  .ALU_S(RS_ALU_S),
  .ALU_Op(RS_ALU_Op),
  .ALU_Vj(RS_ALU_Vj),
  .ALU_Vk(RS_ALU_Vk),
  .ALU_Reorder(RS_ALU_Reorder),
  .ALU_A(RS_ALU_A),
  .ALU_pc(RS_ALU_pc),
  .CDB_ALU_S(CDB_ALU_S),
  .CDB_ALU_Reorder(CDB_ALU_Reorder),
  .CDB_ALU_Value(CDB_ALU_Value),

  //LSB
  .CDB_LSB_S(CDB_LSB_S),
  .CDB_LSB_Reorder(CDB_LSB_Reorder),
  .CDB_LSB_Value(CDB_LSB_Value)
);

endmodule