module datapath(input         clk, reset,
                // from controller
                input  [1:0]  ResultSrc,
                input         PCSrc,
                input         ALUSrc,
                input         RegWrite,
                input  [1:0]  ImmSrc,
                input  [2:0]  ALUControl,
                // to controller
                output        Zero,
                // instruction memory
                output [31:0] PC,
                input  [31:0] Instr,
                // data memory
                output [31:0] ALUResult, WriteData,
                input  [31:0] ReadData);

  localparam WIDTH = 32;  // bus width

  wire [31:0] PCNext, PCPlus4, PCTarget;
  wire [31:0] ImmExt;
  wire [31:0] SrcA, SrcB;
  wire [31:0] Result;

  // ================= NEXT PC =================
  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4),
    .d1(PCTarget),
    .s (PCSrc),
    .y (PCNext)
  );

  flopr #(WIDTH) pcreg(
    .clk  (clk),
    .reset(reset),
    .d    (PCNext),
    .q    (PC)
  );

  adder pcadd4(
    .a(PC),
    .b(32'd4),
    .y(PCPlus4)
  );

  adder pcaddbranch(
    .a(PC),
    .b(ImmExt),
    .y(PCTarget)
  );

  // ================= REGISTER FILE =================
  regfile rf(
    .clk(clk),
    .we3(RegWrite),
    .a1 (Instr[19:15]),
    .a2 (Instr[24:20]),
    .a3 (Instr[11:7]),
    .wd3(Result),
    .rd1(SrcA),
    .rd2(WriteData)
  );

  extend ext(
    .instr (Instr[31:7]),
    .immsrc(ImmSrc),
    .immext(ImmExt)
  );

  // ================= ALU =================
  mux2 #(WIDTH) srcbmux(
    .d0(WriteData),
    .d1(ImmExt),
    .s (ALUSrc),
    .y (SrcB)
  );

  alu alu(
    .a         (SrcA),
    .b         (SrcB),
    .alucontrol(ALUControl),
    .result    (ALUResult),
    .zero      (Zero)
  );

  // ================= WRITE BACK =================
  mux3 #(WIDTH) resultmux(
    .d0(ALUResult),
    .d1(ReadData),
    .d2(PCPlus4),
    .s (ResultSrc),
    .y (Result)
  );

endmodule
