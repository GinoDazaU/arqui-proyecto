module datapath(input         clk, reset,
                // from controller
                input         PCSrcE,
                input         RegWriteW,
                input  [1:0]  ImmSrcD,
                input         ALUSrcE,
                input  [2:0]  ALUControlE,
                input  [1:0]  ResultSrcW,
                // to controller
                output        ZeroE,
                output [31:0] InstrD,
                // from hazard unit
                input         StallF,
                input         StallD,
                input         FlushD,
                input         FlushE,
                input  [1:0]  ForwardAE,
                input  [1:0]  ForwardBE,
                // to hazard unit
                output [4:0]  Rs1D,
                output [4:0]  Rs2D,
                output [4:0]  Rs1E,
                output [4:0]  Rs2E,
                output [4:0]  RdE,
                output [4:0]  RdM,
                output [4:0]  RdW,
                // instruction memory
                output [31:0] PCF,
                input  [31:0] InstrF,
                // data memory
                output [31:0] ALUResultM,
                output [31:0] WriteDataM,
                input  [31:0] ReadDataM);

  localparam WIDTH = 32; // bus width

  // ================= FETCH =================
  wire [31:0] PCNextF, PCPlus4F;
  wire [31:0] PCTargetE;  // comes from Execute stage

  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s (PCSrcE),
    .y (PCNextF)
  );

  flopenr #(WIDTH) pcreg(
    .clk  (clk),
    .reset(reset),
    .en   (~StallF),
    .d    (PCNextF),
    .q    (PCF)
  );

  adder pcadd4(
    .a(PCF),
    .b(32'd4),
    .y(PCPlus4F)
  );

  // ================= IF/ID =================
  wire [31:0] PCD, PCPlus4D;

  flopenrc #(96) regD(
    .clk  (clk),
    .reset(reset),
    .en   (~StallD),
    .clear(FlushD),
    .d    ({InstrF, PCF, PCPlus4F}),
    .q    ({InstrD, PCD, PCPlus4D})
  );

  // ================= DECODE =================
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0]  RdD;
  wire [31:0] ResultW;  // comes from Writeback stage

  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  regfile rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1 (Rs1D),
    .a2 (Rs2D),
    .a3 (RdW),
    .wd3(ResultW),
    .rd1(RD1D),
    .rd2(RD2D)
  );

  extend ext(
    .instr (InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ImmExtD)
  );

  // ================= ID/EX =================
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;

  floprc #(175) regE(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE),
    .d    ({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D}),
    .q    ({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E})
  );

  // ================= EXECUTE =================
  wire [31:0] SrcAE, SrcBE;
  wire [31:0] WriteDataE;
  wire [31:0] ALUResultE;

  // forwarding muxes: 00 = register file, 01 = Writeback, 10 = Memory
  mux3 #(WIDTH) faemux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s (ForwardAE),
    .y (SrcAE)
  );

  mux3 #(WIDTH) fbemux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s (ForwardBE),
    .y (WriteDataE)
  );

  mux2 #(WIDTH) srcbmux(
    .d0(WriteDataE),
    .d1(ImmExtE),
    .s (ALUSrcE),
    .y (SrcBE)
  );

  alu alu(
    .a         (SrcAE),
    .b         (SrcBE),
    .alucontrol(ALUControlE),
    .result    (ALUResultE),
    .zero      (ZeroE)
  );

  adder pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  // ================= EX/MEM =================
  wire [31:0] PCPlus4M;

  flopr #(101) regM(
    .clk  (clk),
    .reset(reset),
    .d    ({ALUResultE, WriteDataE, RdE, PCPlus4E}),
    .q    ({ALUResultM, WriteDataM, RdM, PCPlus4M})
  );

  // ================= MEMORY =================
  // data memory is outside the datapath (ReadDataM comes as input)

  // ================= MEM/WB =================
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;

  flopr #(101) regW(
    .clk  (clk),
    .reset(reset),
    .d    ({ALUResultM, ReadDataM, RdM, PCPlus4M}),
    .q    ({ALUResultW, ReadDataW, RdW, PCPlus4W})
  );

  // ================= WRITEBACK =================
  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s (ResultSrcW),
    .y (ResultW)
  );

endmodule
