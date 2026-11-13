module datapath(input         clk, reset,
                // from controller
                input         BranchE_0, JumpE_0,
                input         BranchE_1, JumpE_1,
                input         MemLaneM,
                input         RegWriteW_0,
                input  [1:0]  ImmSrcD_0,
                input         ALUSrcE_0,
                input  [2:0]  ALUControlE_0,
                input  [1:0]  ResultSrcW_0,
                input         RegWriteW_1,
                input  [1:0]  ImmSrcD_1,
                input         ALUSrcE_1,
                input  [2:0]  ALUControlE_1,
                input  [1:0]  ResultSrcW_1,
                // to controller / issue unit
                output [31:0] InstrD_0,
                output [31:0] InstrD_1,
                // to hazard unit (from the branch unit)
                output        MispredictE,
                output        FlushLane1E,
                // from hazard unit
                input         StallF,
                input         StallD,
                input         FlushD,
                input         FlushE_0,
                input         FlushE_1,
                input         FlushM_1,
                input         RegroupD,
                input  [2:0]  ForwardAE_0,
                input  [2:0]  ForwardBE_0,
                input  [2:0]  ForwardAE_1,
                input  [2:0]  ForwardBE_1,
                // to hazard unit
                output [4:0]  Rs1D_0,
                output [4:0]  Rs2D_0,
                output [4:0]  Rs1E_0,
                output [4:0]  Rs2E_0,
                output [4:0]  RdE_0,
                output [4:0]  RdM_0,
                output [4:0]  RdW_0,
                output [4:0]  Rs1D_1,
                output [4:0]  Rs2D_1,
                output [4:0]  Rs1E_1,
                output [4:0]  Rs2E_1,
                output [4:0]  RdE_1,
                output [4:0]  RdM_1,
                output [4:0]  RdW_1,
                // instruction memory
                output [31:0] PCF,
                input  [31:0] InstrF_0,
                input  [31:0] InstrF_1,
                // data memory
                output [31:0] ALUResultM,
                output [31:0] WriteDataM,
                input  [31:0] ReadDataM);

  localparam WIDTH = 32; // bus width

  // ================= FETCH =================
  wire [31:0] PCNextF, PCPlus4F, PCPlus8F;
  wire [31:0] PCCorrectE;  // comes from the branch unit (Execute)
  wire        PredF_0, PredF_1;
  wire [31:0] TargetF_0, TargetF_1;
  wire        CtrlE, JumpE, PCSrcE;   // from the branch unit, to update the BTB
  wire [31:0] PCE, PCTargetE;

  btb #(4) predictor(
    .clk        (clk),
    .reset      (reset),
    .pc_0       (PCF),
    .pc_1       (PCPlus4F),
    .predtaken_0(PredF_0),
    .predtaken_1(PredF_1),
    .target_0   (TargetF_0),
    .target_1   (TargetF_1),
    .update     (CtrlE),
    .upc        (PCE),
    .utaken     (PCSrcE),
    .ujump      (JumpE),
    .utarget    (PCTargetE)
  );

  // priority: misprediction, slot 0 predicted taken, regroup, slot 1 predicted taken
  assign PCNextF = MispredictE ? PCCorrectE :
                   PredF_0     ? TargetF_0  :
                   RegroupD    ? PCPlus4F   :
                   PredF_1     ? TargetF_1  :
                                 PCPlus8F;

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

  adder pcadd8(
    .a(PCF),
    .b(32'd8),
    .y(PCPlus8F)
  );

  // ================= IF/ID =================
  wire [31:0] PCD_0, PCD_1, PCPlus4D_0, PCPlus4D_1;
  wire        PredD_0, PredD_1;
  wire [31:0] TargetD_0, TargetD_1;

  // slot 0 predicted taken: the fetched slot 1 is younger and is not on the predicted path
  wire        AnnulF_1 = PredF_0 & ~RegroupD;

  // regroup: only slot 0 issued -> the waiting slot 1 becomes the new slot 0,
  // and the first instruction fetched becomes the new slot 1
  wire [31:0] InstrN_0   = RegroupD ? InstrD_1   : InstrF_0;
  wire [31:0] InstrN_1   = RegroupD ? InstrF_0   : AnnulF_1 ? 32'b0 : InstrF_1;
  wire [31:0] PCN_0      = RegroupD ? PCD_1      : PCF;
  wire [31:0] PCN_1      = RegroupD ? PCF        : PCPlus4F;
  wire [31:0] PCPlus4N_0 = RegroupD ? PCPlus4D_1 : PCPlus4F;
  wire [31:0] PCPlus4N_1 = RegroupD ? PCPlus4F   : PCPlus8F;
  wire [32:0] PredN_0    = RegroupD ? {PredD_1, TargetD_1} : {PredF_0, TargetF_0};
  wire [32:0] PredN_1    = RegroupD ? {PredF_0, TargetF_0} : AnnulF_1 ? 33'b0 : {PredF_1, TargetF_1};

  flopenrc #(258) regD(
    .clk  (clk),
    .reset(reset),
    .en   (~StallD),
    .clear(FlushD),
    .d    ({InstrN_0, InstrN_1, PCN_0, PCN_1, PCPlus4N_0, PCPlus4N_1, PredN_0, PredN_1}),
    .q    ({InstrD_0, InstrD_1, PCD_0, PCD_1, PCPlus4D_0, PCPlus4D_1,
            PredD_0, TargetD_0, PredD_1, TargetD_1})
  );

  // ================= DECODE =================
  wire [31:0] RD1D_0, RD2D_0, ImmExtD_0;
  wire [4:0]  RdD_0;
  wire [31:0] ResultW_0;  // comes from Writeback stage

  wire [31:0] RD1D_1, RD2D_1, ImmExtD_1;
  wire [4:0]  RdD_1;
  wire [31:0] ResultW_1;  // comes from Writeback stage


  assign Rs1D_0 = InstrD_0[19:15];
  assign Rs2D_0 = InstrD_0[24:20];
  assign RdD_0  = InstrD_0[11:7];

  assign Rs1D_1 = InstrD_1[19:15];
  assign Rs2D_1 = InstrD_1[24:20];
  assign RdD_1  = InstrD_1[11:7];


  regfile rf(
    .clk(clk),
    .we3(RegWriteW_0),
    .a1 (Rs1D_0),
    .a2 (Rs2D_0),
    .a3 (RdW_0),
    .rd1(RD1D_0),
    .rd2(RD2D_0),
    .wd3(ResultW_0),
    .we6(RegWriteW_1),
    .a4(Rs1D_1),
    .a5(Rs2D_1),
    .a6(RdW_1),
    .rd4(RD1D_1),
    .rd5(RD2D_1),
    .wd6(ResultW_1)
);

  extend ext_0(
    .instr (InstrD_0[31:7]),
    .immsrc(ImmSrcD_0),
    .immext(ImmExtD_0)
  );

  extend ext_1(
    .instr (InstrD_1[31:7]),
    .immsrc(ImmSrcD_1),
    .immext(ImmExtD_1)
  );

  // ================= ID/EX =================
  wire [31:0] RD1E_0, RD2E_0, PCE_0, ImmExtE_0, PCPlus4E_0;
  wire [31:0] InstrE_0;  // debug: only for the waveform
  wire        PredE_0;
  wire [31:0] TargetE_0;

  wire [31:0] RD1E_1, RD2E_1, PCE_1, ImmExtE_1, PCPlus4E_1;
  wire [31:0] InstrE_1;  // debug: only for the waveform
  wire        PredE_1;
  wire [31:0] TargetE_1;

  floprc #(240) regE_0(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE_0),
    .d    ({RD1D_0, RD2D_0, PCD_0, Rs1D_0, Rs2D_0, RdD_0, ImmExtD_0, PCPlus4D_0, InstrD_0,
            PredD_0, TargetD_0}),
    .q    ({RD1E_0, RD2E_0, PCE_0, Rs1E_0, Rs2E_0, RdE_0, ImmExtE_0, PCPlus4E_0, InstrE_0,
            PredE_0, TargetE_0})
  );

  floprc #(240) regE_1(
    .clk  (clk),
    .reset(reset),
    .clear(FlushE_1),
    .d    ({RD1D_1, RD2D_1, PCD_1, Rs1D_1, Rs2D_1, RdD_1, ImmExtD_1, PCPlus4D_1, InstrD_1,
            PredD_1, TargetD_1}),
    .q    ({RD1E_1, RD2E_1, PCE_1, Rs1E_1, Rs2E_1, RdE_1, ImmExtE_1, PCPlus4E_1, InstrE_1,
            PredE_1, TargetE_1})
  );


  // ================= EXECUTE =================
  wire [31:0] SrcAE_0, SrcBE_0;
  wire [31:0] WriteDataE_0;
  wire [31:0] ALUResultE_0;
  wire [31:0] ALUResultM_0;  // from EX/MEM, used by forwarding
  wire [31:0] ALUResultM_1;  // from EX/MEM lane 1, used by forwarding

  // ---------- lane 0 ----------

  // forwarding muxes: 000 = register file, 001 = WB lane 0, 010 = WB lane 1,
  //                   011 = MEM lane 0,   100 = MEM lane 1
  mux5 #(WIDTH) faemux_0(
    .d0(RD1E_0),
    .d1(ResultW_0),
    .d2(ResultW_1),
    .d3(ALUResultM_0),
    .d4(ALUResultM_1),
    .s (ForwardAE_0),
    .y (SrcAE_0)
  );

  mux5 #(WIDTH) fbemux_0(
    .d0(RD2E_0),
    .d1(ResultW_0),
    .d2(ResultW_1),
    .d3(ALUResultM_0),
    .d4(ALUResultM_1),
    .s (ForwardBE_0),
    .y (WriteDataE_0)
  );

  mux2 #(WIDTH) srcbmux_0(
    .d0(WriteDataE_0),
    .d1(ImmExtE_0),
    .s (ALUSrcE_0),
    .y (SrcBE_0)
  );

  alu alu_0(
    .a         (SrcAE_0),
    .b         (SrcBE_0),
    .alucontrol(ALUControlE_0),
    .result    (ALUResultE_0)
  );

  // ---------- lane 1 ----------
  wire [31:0] SrcAE_1, SrcBE_1;
  wire [31:0] WriteDataE_1;
  wire [31:0] ALUResultE_1;

  mux5 #(WIDTH) faemux_1(
    .d0(RD1E_1),
    .d1(ResultW_0),
    .d2(ResultW_1),
    .d3(ALUResultM_0),
    .d4(ALUResultM_1),
    .s (ForwardAE_1),
    .y (SrcAE_1)
  );

  mux5 #(WIDTH) fbemux_1(
    .d0(RD2E_1),
    .d1(ResultW_0),
    .d2(ResultW_1),
    .d3(ALUResultM_0),
    .d4(ALUResultM_1),
    .s (ForwardBE_1),
    .y (WriteDataE_1)
  );

  mux2 #(WIDTH) srcbmux_1(
    .d0(WriteDataE_1),
    .d1(ImmExtE_1),
    .s (ALUSrcE_1),
    .y (SrcBE_1)
  );

  alu alu_1(
    .a         (SrcAE_1),
    .b         (SrcBE_1),
    .alucontrol(ALUControlE_1),
    .result    (ALUResultE_1)
  );

   // ---------- shared branch unit ----------
  branchunit bu(
    // from controller
    .BranchE_0   (BranchE_0),
    .JumpE_0     (JumpE_0),
    .BranchE_1   (BranchE_1),
    .JumpE_1     (JumpE_1),
    // lane 0 operands
    .PCE_0       (PCE_0),
    .PCPlus4E_0  (PCPlus4E_0),
    .ImmExtE_0   (ImmExtE_0),
    .SrcAE_0     (SrcAE_0),
    .WriteDataE_0(WriteDataE_0),
    .PredE_0     (PredE_0),
    .TargetE_0   (TargetE_0),
    // lane 1 operands
    .PCE_1       (PCE_1),
    .PCPlus4E_1  (PCPlus4E_1),
    .ImmExtE_1   (ImmExtE_1),
    .SrcAE_1     (SrcAE_1),
    .WriteDataE_1(WriteDataE_1),
    .PredE_1     (PredE_1),
    .TargetE_1   (TargetE_1),
    // results
    .MispredictE (MispredictE),
    .FlushLane1E (FlushLane1E),
    .PCCorrectE  (PCCorrectE),
    // to BTB
    .CtrlE       (CtrlE),
    .JumpE       (JumpE),
    .PCSrcE      (PCSrcE),
    .PCE         (PCE),
    .PCTargetE   (PCTargetE)
  );

  // ================= EX/MEM =================
  wire [31:0] WriteDataM_0;
  wire [31:0] PCPlus4M_0;
  wire [31:0] InstrM_0;  // debug: only for the waveform

  flopr #(133) regM_0(
    .clk  (clk),
    .reset(reset),
    .d    ({ALUResultE_0, WriteDataE_0, RdE_0, PCPlus4E_0, InstrE_0}),
    .q    ({ALUResultM_0, WriteDataM_0, RdM_0, PCPlus4M_0, InstrM_0})
  );

  // lane 1: cleared when the older branch in lane 0 is taken (FlushM_1)
  wire [31:0] WriteDataM_1;
  wire [31:0] PCPlus4M_1;
  wire [31:0] InstrM_1;  // debug: only for the waveform

  floprc #(133) regM_1(
    .clk  (clk),
    .reset(reset),
    .clear(FlushM_1),
    .d    ({ALUResultE_1, WriteDataE_1, RdE_1, PCPlus4E_1, InstrE_1}),
    .q    ({ALUResultM_1, WriteDataM_1, RdM_1, PCPlus4M_1, InstrM_1})
  );

  // ================= MEMORY =================
  // data memory is outside the datapath (ReadDataM comes as input)
  // single port: the lane that holds the lw/sw (MemLaneM) owns it
  mux2 #(WIDTH) memaddrmux(
    .d0(ALUResultM_0),
    .d1(ALUResultM_1),
    .s (MemLaneM),
    .y (ALUResultM)
  );

  mux2 #(WIDTH) memdatamux(
    .d0(WriteDataM_0),
    .d1(WriteDataM_1),
    .s (MemLaneM),
    .y (WriteDataM)
  );

  // ================= MEM/WB =================
  wire [31:0] ALUResultW_0, ReadDataW_0, PCPlus4W_0;
  wire [31:0] InstrW_0;  // debug: only for the waveform

  flopr #(133) regW_0(
    .clk  (clk),
    .reset(reset),
    .d    ({ALUResultM_0, ReadDataM, RdM_0, PCPlus4M_0, InstrM_0}),
    .q    ({ALUResultW_0, ReadDataW_0, RdW_0, PCPlus4W_0, InstrW_0})
  );

  wire [31:0] ALUResultW_1, ReadDataW_1, PCPlus4W_1;
  wire [31:0] InstrW_1;  // debug: only for the waveform

  flopr #(133) regW_1(
    .clk  (clk),
    .reset(reset),
    .d    ({ALUResultM_1, ReadDataM, RdM_1, PCPlus4M_1, InstrM_1}),
    .q    ({ALUResultW_1, ReadDataW_1, RdW_1, PCPlus4W_1, InstrW_1})
  );

  // ================= WRITEBACK =================
  mux3 #(WIDTH) resultmux_0(
    .d0(ALUResultW_0),
    .d1(ReadDataW_0),
    .d2(PCPlus4W_0),
    .s (ResultSrcW_0),
    .y (ResultW_0)
  );

  mux3 #(WIDTH) resultmux_1(
    .d0(ALUResultW_1),
    .d1(ReadDataW_1),
    .d2(PCPlus4W_1),
    .s (ResultSrcW_1),
    .y (ResultW_1)
  );

endmodule
