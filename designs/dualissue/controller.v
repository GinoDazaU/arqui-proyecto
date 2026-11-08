module controller(input        clk, reset,
                  // from instruction
                  input  [6:0] op_0,
                  input  [2:0] funct3_0,
                  input        funct7b5_0,
                  input  [6:0] op_1,
                  input  [2:0] funct3_1,
                  input        funct7b5_1,
                  // from datapath
                  input        ZeroE_0,
                  input        ZeroE_1,
                  // from hazard unit
                  input        FlushE_0,
                  input        FlushE_1,
                  input        FlushM_1,
                  // to datapath
                  output       RegWriteW_0,
                  output [1:0] ImmSrcD_0,
                  output       ALUSrcE_0,
                  output [1:0] ResultSrcW_0,
                  output [2:0] ALUControlE_0,
                  output       RegWriteW_1,
                  output [1:0] ImmSrcD_1,
                  output       ALUSrcE_1,
                  output [1:0] ResultSrcW_1,
                  output [2:0] ALUControlE_1,
                  // to datapath and hazard unit
                  output       PCSrcE,
                  output       TakenE_0,
                  output       TakenE_1,
                  output       MemLaneM,
                  // to hazard unit
                  output       ResultSrcEb0_0,
                  output       RegWriteM_0,
                  output       ResultSrcEb0_1,
                  output       RegWriteM_1,
                  // to data memory
                  output       MemWriteM);

  // ================= DECODE =================
  wire       RegWriteD_0, MemWriteD_0, JumpD_0, BranchD_0, ALUSrcD_0;
  wire [1:0] ResultSrcD_0;
  wire [2:0] ALUControlD_0;
  wire [1:0] ALUOp_0;

  wire       RegWriteD_1, MemWriteD_1, JumpD_1, BranchD_1, ALUSrcD_1;
  wire [1:0] ResultSrcD_1;
  wire [2:0] ALUControlD_1;
  wire [1:0] ALUOp_1;

  maindec md_0(
    .op       (op_0),
    .ResultSrc(ResultSrcD_0),
    .MemWrite (MemWriteD_0),
    .Branch   (BranchD_0),
    .ALUSrc   (ALUSrcD_0),
    .RegWrite (RegWriteD_0),
    .Jump     (JumpD_0),
    .ImmSrc   (ImmSrcD_0),
    .ALUOp    (ALUOp_0)
  );

  aludec ad_0(
    .opb5      (op_0[5]),
    .funct3    (funct3_0),
    .funct7b5  (funct7b5_0),
    .ALUOp     (ALUOp_0),
    .ALUControl(ALUControlD_0)
  );

  maindec md_1(
    .op       (op_1),
    .ResultSrc(ResultSrcD_1),
    .MemWrite (MemWriteD_1),
    .Branch   (BranchD_1),
    .ALUSrc   (ALUSrcD_1),
    .RegWrite (RegWriteD_1),
    .Jump     (JumpD_1),
    .ImmSrc   (ImmSrcD_1),
    .ALUOp    (ALUOp_1)
  );

  aludec ad_1(
    .opb5      (op_1[5]),
    .funct3    (funct3_1),
    .funct7b5  (funct7b5_1),
    .ALUOp     (ALUOp_1),
    .ALUControl(ALUControlD_1)
  );

  // ================= ID/EX =================
  wire       RegWriteE_0, MemWriteE_0, JumpE_0, BranchE_0;
  wire [1:0] ResultSrcE_0;

  wire       RegWriteE_1, MemWriteE_1, JumpE_1, BranchE_1;
  wire [1:0] ResultSrcE_1;

  floprc #(10) regE_0(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE_0),
    .d    ({RegWriteD_0, ResultSrcD_0, MemWriteD_0, JumpD_0, BranchD_0, ALUControlD_0, ALUSrcD_0}),
    .q    ({RegWriteE_0, ResultSrcE_0, MemWriteE_0, JumpE_0, BranchE_0, ALUControlE_0, ALUSrcE_0})
  );

  floprc #(10) regE_1(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE_1),
    .d    ({RegWriteD_1, ResultSrcD_1, MemWriteD_1, JumpD_1, BranchD_1, ALUControlD_1, ALUSrcD_1}),
    .q    ({RegWriteE_1, ResultSrcE_1, MemWriteE_1, JumpE_1, BranchE_1, ALUControlE_1, ALUSrcE_1})
  );

  // ================= EXECUTE =================
  assign ResultSrcEb0_0 = ResultSrcE_0[0];
  assign ResultSrcEb0_1 = ResultSrcE_1[0];
  // single branch unit: the issue unit never sends two branches/jumps in the same pair,
  // so at most one lane can take a branch per cycle
  assign TakenE_0       = (BranchE_0 & ZeroE_0) | JumpE_0;
  assign TakenE_1       = (BranchE_1 & ZeroE_1) | JumpE_1;
  assign PCSrcE         = TakenE_0 | TakenE_1;

  // ================= EX/MEM =================
  wire [1:0] ResultSrcM_0;
  wire [1:0] ResultSrcM_1;
  wire       MemWriteM_0, MemWriteM_1;

  flopr #(4) regM_0(
    .clk  (clk),
    .reset(reset),
    .d    ({RegWriteE_0, ResultSrcE_0, MemWriteE_0}),
    .q    ({RegWriteM_0, ResultSrcM_0, MemWriteM_0})
  );

  // lane 1 is annulled when the older branch in lane 0 is taken
  floprc #(4) regM_1(
    .clk  (clk),
    .reset(reset),
    .clear(FlushM_1),
    .d    ({RegWriteE_1, ResultSrcE_1, MemWriteE_1}),
    .q    ({RegWriteM_1, ResultSrcM_1, MemWriteM_1})
  );

  // ================= MEMORY =================
  // single data memory port: owned by the lane that holds the lw/sw (at most one per pair)
  assign MemWriteM = MemWriteM_0 | MemWriteM_1;
  assign MemLaneM  = MemWriteM_1 | (ResultSrcM_1 == 2'b01);

  // ================= MEM/WB =================
  flopr #(3) regW_0(
    .clk  (clk),
    .reset(reset),
    .d    ({RegWriteM_0, ResultSrcM_0}),
    .q    ({RegWriteW_0, ResultSrcW_0})
  );

  flopr #(3) regW_1(
    .clk  (clk),
    .reset(reset),
    .d    ({RegWriteM_1, ResultSrcM_1}),
    .q    ({RegWriteW_1, ResultSrcW_1})
  );

endmodule
