module riscv(input         clk, reset,
             // instruction memory
             output [31:0] PCF,
             input  [31:0] InstrF_0,
             input  [31:0] InstrF_1,
             // data memory
             output [31:0] ALUResultM,
             output [31:0] WriteDataM,
             output        MemWriteM,
             input  [31:0] ReadDataM);

  // controller <-> datapath
  wire [31:0] InstrD_0, InstrD_1;
  wire        BranchE_0, JumpE_0, BranchE_1, JumpE_1;  // controller -> branch unit
  wire        MispredictE, FlushLane1E;                // branch unit -> hazard unit
  wire        MemLaneM;                                // controller -> datapath
  wire        RegWriteW_0, RegWriteW_1;  // also used by hazard unit
  wire [1:0]  ImmSrcD_0, ImmSrcD_1;
  wire        ALUSrcE_0, ALUSrcE_1;
  wire [2:0]  ALUControlE_0, ALUControlE_1;
  wire [1:0]  ResultSrcW_0, ResultSrcW_1;

  // controller -> hazard unit
  wire        ResultSrcEb0_0, ResultSrcEb0_1;
  wire        RegWriteM_0, RegWriteM_1;

  // issue unit -> hazard unit
  wire        LoadUseD_0, IssueOneD;

  // hazard unit -> controller and datapath
  wire        FlushE_0, FlushE_1, FlushM_1;   // used by controller and datapath

  // hazard unit -> datapath
  wire        StallF, StallD, FlushD, RegroupD;
  wire [2:0]  ForwardAE_0, ForwardBE_0, ForwardAE_1, ForwardBE_1;

  // datapath -> hazard unit
  wire [4:0]  Rs1D_0, Rs2D_0, Rs1E_0, Rs2E_0, RdE_0, RdM_0, RdW_0;
  wire [4:0]  Rs1D_1, Rs2D_1, Rs1E_1, Rs2E_1, RdE_1, RdM_1, RdW_1;

  controller c(
    .clk           (clk),
    .reset         (reset),
    // from instruction
    .op_0          (InstrD_0[6:0]),
    .funct3_0      (InstrD_0[14:12]),
    .funct7b5_0    (InstrD_0[30]),
    .op_1          (InstrD_1[6:0]),
    .funct3_1      (InstrD_1[14:12]),
    .funct7b5_1    (InstrD_1[30]),
    // from hazard unit
    .FlushE_0      (FlushE_0),
    .FlushE_1      (FlushE_1),
    .FlushM_1      (FlushM_1),
    // to datapath
    .RegWriteW_0   (RegWriteW_0),
    .ImmSrcD_0     (ImmSrcD_0),
    .ALUSrcE_0     (ALUSrcE_0),
    .ResultSrcW_0  (ResultSrcW_0),
    .ALUControlE_0 (ALUControlE_0),
    .RegWriteW_1   (RegWriteW_1),
    .ImmSrcD_1     (ImmSrcD_1),
    .ALUSrcE_1     (ALUSrcE_1),
    .ResultSrcW_1  (ResultSrcW_1),
    .ALUControlE_1 (ALUControlE_1),
    // to branch unit (inside the datapath)
    .BranchE_0     (BranchE_0),
    .JumpE_0       (JumpE_0),
    .BranchE_1     (BranchE_1),
    .JumpE_1       (JumpE_1),
    // to datapath
    .MemLaneM      (MemLaneM),
    // to hazard unit
    .ResultSrcEb0_0(ResultSrcEb0_0),
    .RegWriteM_0   (RegWriteM_0),
    .ResultSrcEb0_1(ResultSrcEb0_1),
    .RegWriteM_1   (RegWriteM_1),
    // to data memory
    .MemWriteM     (MemWriteM)
  );

  datapath dp(
    .clk         (clk),
    .reset       (reset),
    // from controller
    .BranchE_0   (BranchE_0),
    .JumpE_0     (JumpE_0),
    .BranchE_1   (BranchE_1),
    .JumpE_1     (JumpE_1),
    .MemLaneM    (MemLaneM),
    .RegWriteW_0 (RegWriteW_0),
    .ImmSrcD_0   (ImmSrcD_0),
    .ALUSrcE_0   (ALUSrcE_0),
    .ALUControlE_0(ALUControlE_0),
    .ResultSrcW_0(ResultSrcW_0),
    .RegWriteW_1 (RegWriteW_1),
    .ImmSrcD_1   (ImmSrcD_1),
    .ALUSrcE_1   (ALUSrcE_1),
    .ALUControlE_1(ALUControlE_1),
    .ResultSrcW_1(ResultSrcW_1),
    // to controller / issue unit
    .InstrD_0    (InstrD_0),
    .InstrD_1    (InstrD_1),
    // to hazard unit (from the branch unit)
    .MispredictE (MispredictE),
    .FlushLane1E (FlushLane1E),
    // from hazard unit
    .StallF      (StallF),
    .StallD      (StallD),
    .FlushD      (FlushD),
    .FlushE_0    (FlushE_0),
    .FlushE_1    (FlushE_1),
    .FlushM_1    (FlushM_1),
    .RegroupD    (RegroupD),
    .ForwardAE_0 (ForwardAE_0),
    .ForwardBE_0 (ForwardBE_0),
    .ForwardAE_1 (ForwardAE_1),
    .ForwardBE_1 (ForwardBE_1),
    // to hazard unit
    .Rs1D_0      (Rs1D_0),
    .Rs2D_0      (Rs2D_0),
    .Rs1E_0      (Rs1E_0),
    .Rs2E_0      (Rs2E_0),
    .RdE_0       (RdE_0),
    .RdM_0       (RdM_0),
    .RdW_0       (RdW_0),
    .Rs1D_1      (Rs1D_1),
    .Rs2D_1      (Rs2D_1),
    .Rs1E_1      (Rs1E_1),
    .Rs2E_1      (Rs2E_1),
    .RdE_1       (RdE_1),
    .RdM_1       (RdM_1),
    .RdW_1       (RdW_1),
    // instruction memory
    .PCF         (PCF),
    .InstrF_0    (InstrF_0),
    .InstrF_1    (InstrF_1),
    // data memory
    .ALUResultM  (ALUResultM),
    .WriteDataM  (WriteDataM),
    .ReadDataM   (ReadDataM)
  );

  issue iu(
    // pair in Decode
    .InstrD_0      (InstrD_0),
    .InstrD_1      (InstrD_1),
    // instructions in Execute
    .RdE_0         (RdE_0),
    .RdE_1         (RdE_1),
    .ResultSrcEb0_0(ResultSrcEb0_0),
    .ResultSrcEb0_1(ResultSrcEb0_1),
    // to hazard unit
    .LoadUseD_0    (LoadUseD_0),
    .IssueOneD     (IssueOneD)
  );

   hazard hu(
    // from datapath
    .Rs1E_0        (Rs1E_0),
    .Rs2E_0        (Rs2E_0),
    .RdM_0         (RdM_0),
    .RdW_0         (RdW_0),
    .Rs1E_1        (Rs1E_1),
    .Rs2E_1        (Rs2E_1),
    .RdM_1         (RdM_1),
    .RdW_1         (RdW_1),
    // from the branch unit and the controller
    .MispredictE   (MispredictE),
    .FlushLane1E   (FlushLane1E),
    .RegWriteM_0   (RegWriteM_0),
    .RegWriteW_0   (RegWriteW_0),
    .RegWriteM_1   (RegWriteM_1),
    .RegWriteW_1   (RegWriteW_1),
    // from issue unit
    .LoadUseD_0    (LoadUseD_0),
    .IssueOneD     (IssueOneD),
    // to datapath
    .ForwardAE_0   (ForwardAE_0),
    .ForwardBE_0   (ForwardBE_0),
    .ForwardAE_1   (ForwardAE_1),
    .ForwardBE_1   (ForwardBE_1),
    .StallF        (StallF),
    .StallD        (StallD),
    .FlushD        (FlushD),
    .RegroupD      (RegroupD),
    // to datapath and controller
    .FlushE_0      (FlushE_0),
    .FlushE_1      (FlushE_1),
    .FlushM_1      (FlushM_1)
  );

endmodule
