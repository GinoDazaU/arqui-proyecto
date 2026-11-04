module controller(input        clk, reset,
                  // from instruction
                  input  [6:0] op,
                  input  [2:0] funct3,
                  input        funct7b5,
                  // from datapath
                  input        ZeroE,
                  // from hazard unit
                  input        FlushE,
                  // to datapath
                  output       RegWriteW,
                  output [1:0] ImmSrcD,
                  output       ALUSrcE,
                  output [1:0] ResultSrcW,
                  output [2:0] ALUControlE,
                  // to datapath and hazard unit
                  output       PCSrcE,
                  // to hazard unit
                  output       ResultSrcEb0,
                  output       RegWriteM,
                  // to data memory
                  output       MemWriteM);

  // ================= DECODE =================
  wire       RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
  wire [1:0] ResultSrcD;
  wire [2:0] ALUControlD;
  wire [1:0] ALUOp;

  maindec md(
    .op       (op),
    .ResultSrc(ResultSrcD),
    .MemWrite (MemWriteD),
    .Branch   (BranchD),
    .ALUSrc   (ALUSrcD),
    .RegWrite (RegWriteD),
    .Jump     (JumpD),
    .ImmSrc   (ImmSrcD),
    .ALUOp    (ALUOp)
  );

  aludec ad(
    .opb5      (op[5]),
    .funct3    (funct3),
    .funct7b5  (funct7b5),
    .ALUOp     (ALUOp),
    .ALUControl(ALUControlD)
  );

  // ================= ID/EX =================
  wire       RegWriteE, MemWriteE, JumpE, BranchE;
  wire [1:0] ResultSrcE;

  floprc #(10) regE(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE),
    .d    ({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD}),
    .q    ({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE})
  );

  // ================= EXECUTE =================
  assign ResultSrcEb0 = ResultSrcE[0];
  assign PCSrcE       = (BranchE & ZeroE) | JumpE;

  // ================= EX/MEM =================
  wire [1:0] ResultSrcM;

  flopr #(4) regM(
    .clk  (clk),
    .reset(reset),
    .d    ({RegWriteE, ResultSrcE, MemWriteE}),
    .q    ({RegWriteM, ResultSrcM, MemWriteM})
  );

  // ================= MEM/WB =================
  flopr #(3) regW(
    .clk  (clk),
    .reset(reset),
    .d    ({RegWriteM, ResultSrcM}),
    .q    ({RegWriteW, ResultSrcW})
  );

endmodule
