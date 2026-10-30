module datapath(// clock / reset
                input  clk, reset,
                // from controller
                input  [1:0]  ResultSrc,
                input  PCSrc,
                input  ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc,
                input  [2:0]  ALUControl,
                // to controller
                output Zero,
                // instruction memory
                output [31:0] PCF,
                input  [31:0] InstrF,
                // data memory
                output [31:0] ALUResult, WriteData,
                input  [31:0] ReadData);

  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4F, PCTarget;
  wire [31:0] ImmExt;
  wire [31:0] SrcA, SrcB;
  wire [31:0] Result;
  wire [31:0] InstrD, PCD, PCPlus4D;

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .d(PCNext),
    .q(PCF)
  );

  adder       pcadd4(
    .a(PCF),
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4F)
  );

  adder       pcaddbranch(
    .a(PCF),
    .b(ImmExt),
    .y(PCTargetE)
  );

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNext)
  );

  flopr #(96) regD(.clk(clk), .reset(reset),
                   .d({InstrF, PCF, PCPlus4F}),
                   .q({InstrD, PCD, PCPlus4D}));

  // register file logic
  regfile     rf(
    .clk(clk),
    .we3(RegWrite),
    .a1(Instr[19:15]),
    .a2(Instr[24:20]),
    .a3(Instr[11:7]),
    .wd3(Result),
    .rd1(SrcA),
    .rd2(WriteData)
  );

  extend      ext(
    .instr(Instr[31:7]),
    .immsrc(ImmSrc),
    .immext(ImmExt)
  );

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(WriteData),
    .d1(ImmExt),
    .s(ALUSrc),
    .y(SrcB)
  );

  alu         alu(
    .a(SrcA),
    .b(SrcB),
    .alucontrol(ALUControl),
    .result(ALUResult),
    .zero(Zero)
  );

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResult),
    .d1(ReadData),
    .d2(PCPlus4),
    .s(ResultSrc),
    .y(Result)
  );
endmodule
