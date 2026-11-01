module datapath(input  clk, reset,
                // from controller
                input  PCSrcE,
                input  RegWriteW,
                input  [1:0]  ImmSrcD,
                input  ALUSrcE,
                input  [2:0]  ALUControlE,
                input  [1:0]  ResultSrcW,
                // to controller
                output ZeroE,
                // instruction memory
                output [31:0] PCF,
                input  [31:0] InstrF,
                // instruction in decode (to controller)
                output [31:0] InstrD,
                // data memory
                output [31:0] ALUResultM, WriteDataM,
                input  [31:0] ReadDataM);

  localparam WIDTH = 32; // Define a local parameter for bus width

  // ================= FETCH =================
  wire [31:0] PCNextF, PCPlus4F;
  wire [31:0] PCTargetE; // come from Execute stage

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .d(PCNextF),
    .q(PCF)
  );

  adder       pcadd4(
    .a(PCF),
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4F)
  );

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNextF)
  );

  // ================= IF/ID =================
  wire [31:0] PCD, PCPlus4D;
  flopr #(96) regD(.clk(clk), .reset(reset),
                   .d({InstrF, PCF, PCPlus4F}),
                   .q({InstrD, PCD, PCPlus4D}));

  // ================= DECODE =================
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0] RdD = InstrD[11:7];
  wire [31:0] ResultW; wire [4:0] RdW; // come from Write stage

  // register file logic
  regfile     rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1(InstrD[19:15]),
    .a2(InstrD[24:20]),
    .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D),
    .rd2(RD2D)
  );

  extend      ext(
    .instr(InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ImmExtD)
  );

  // ================= ID/EX =================
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [4:0] RdE;

  flopr #(165) regE(.clk(clk), .reset(reset),
                    .d({RD1D, RD2D, PCD, RdD, ImmExtD, PCPlus4D}),
                    .q({RD1E, RD2E, PCE, RdE, ImmExtE, PCPlus4E}));

  // ================= EXECUTE =================
  wire [31:0] SrcAE = RD1E;
  wire [31:0] SrcBE;
  wire [31:0] ALUResultE;
  wire [31:0] WriteDataE = RD2E;

  // ALU logic
  mux2 #(WIDTH) srcbmux(
    .d0(RD2E),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcBE)
  );

  alu         alu(
    .a(SrcAE),
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  );

  adder       pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  // ================= EX/MEM =================
  wire [31:0] PCPlus4M;
  wire [4:0] RdM;

  flopr #(101) regM(.clk(clk), .reset(reset),
            .d({ALUResultE, WriteDataE, RdE, PCPlus4E}),
            .q({ALUResultM, WriteDataM, RdM, PCPlus4M}));

  // ================= MEMORY =================
  // ReadDataM comes as input

  // ================= MEM/WB =================
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;

  flopr #(101) regW(.clk(clk), .reset(reset),
                   .d({ALUResultM, ReadDataM, RdM, PCPlus4M}),
                   .q({ALUResultW, ReadDataW, RdW, PCPlus4W}));

  // ================= WRITEBACK =================

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );

endmodule
