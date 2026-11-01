module riscv(// clock / reset
             input  clk, reset,
             // instruction memory
             output [31:0] PCF,
             input  [31:0] InstrF,
             // data memory
             output [31:0] ALUResultM,
             output [31:0] WriteDataM,
             output MemWriteM,
             input  [31:0] ReadDataM);

  wire [31:0] InstrD;

  wire       ALUSrcE, RegWriteW, ZeroE;
  wire [1:0] ResultSrcW, ImmSrcD;
  wire [2:0] ALUControlE;
  wire       PCSrcE;

  controller c(
    .clk(clk),
    .reset(reset),
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7b5(InstrD[30]),
    .ZeroE(ZeroE),
    .RegWriteW(RegWriteW),
    .ImmSrcD(ImmSrcD),
    .ALUSrcE(ALUSrcE),
    .MemWriteM(MemWriteM),
    .ResultSrcW(ResultSrcW),
    .PCSrcE(PCSrcE),
    .ALUControlE(ALUControlE)
  );

  datapath dp(
    .clk(clk),
    .reset(reset),
    .PCSrcE(PCSrcE),
    .RegWriteW(RegWriteW),
    .ImmSrcD(ImmSrcD),
    .ALUSrcE(ALUSrcE),
    .ALUControlE(ALUControlE),
    .ResultSrcW(ResultSrcW),
    .ZeroE(ZeroE),
    .PCF(PCF),
    .InstrF(InstrF),
    .InstrD(InstrD),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .ReadDataM(ReadDataM)
  );

endmodule
