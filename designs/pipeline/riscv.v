module riscv(input         clk, reset,
             // instruction memory
             output [31:0] PCF,
             input  [31:0] InstrF,
             // data memory
             output [31:0] ALUResultM,
             output [31:0] WriteDataM,
             output        MemWriteM,
             input  [31:0] ReadDataM);

  // controller <-> datapath
  wire [31:0] InstrD;
  wire        ZeroE;
  wire        PCSrcE;        // also used by hazard unit
  wire        RegWriteW;     // also used by hazard unit
  wire [1:0]  ImmSrcD;
  wire        ALUSrcE;
  wire [2:0]  ALUControlE;
  wire [1:0]  ResultSrcW;

  // controller -> hazard unit
  wire        ResultSrcEb0;
  wire        RegWriteM;

  // hazard unit -> controller and datapath
  wire        FlushE;        // used by controller and datapath

  // hazard unit -> datapath
  wire        StallF, StallD, FlushD;
  wire [1:0]  ForwardAE, ForwardBE;

  // datapath -> hazard unit
  wire [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

  controller c(
    .clk         (clk),
    .reset       (reset),
    // from instruction
    .op          (InstrD[6:0]),
    .funct3      (InstrD[14:12]),
    .funct7b5    (InstrD[30]),
    // from datapath
    .ZeroE       (ZeroE),
    // from hazard unit
    .FlushE      (FlushE),
    // to datapath
    .RegWriteW   (RegWriteW),
    .ImmSrcD     (ImmSrcD),
    .ALUSrcE     (ALUSrcE),
    .ResultSrcW  (ResultSrcW),
    .ALUControlE (ALUControlE),
    // to datapath and hazard unit
    .PCSrcE      (PCSrcE),
    // to hazard unit
    .ResultSrcEb0(ResultSrcEb0),
    .RegWriteM   (RegWriteM),
    // to data memory
    .MemWriteM   (MemWriteM)
  );

  datapath dp(
    .clk        (clk),
    .reset      (reset),
    // from controller
    .PCSrcE     (PCSrcE),
    .RegWriteW  (RegWriteW),
    .ImmSrcD    (ImmSrcD),
    .ALUSrcE    (ALUSrcE),
    .ALUControlE(ALUControlE),
    .ResultSrcW (ResultSrcW),
    // to controller
    .ZeroE      (ZeroE),
    .InstrD     (InstrD),
    // from hazard unit
    .StallF     (StallF),
    .StallD     (StallD),
    .FlushD     (FlushD),
    .FlushE     (FlushE),
    .ForwardAE  (ForwardAE),
    .ForwardBE  (ForwardBE),
    // to hazard unit
    .Rs1D       (Rs1D),
    .Rs2D       (Rs2D),
    .Rs1E       (Rs1E),
    .Rs2E       (Rs2E),
    .RdE        (RdE),
    .RdM        (RdM),
    .RdW        (RdW),
    // instruction memory
    .PCF        (PCF),
    .InstrF     (InstrF),
    // data memory
    .ALUResultM (ALUResultM),
    .WriteDataM (WriteDataM),
    .ReadDataM  (ReadDataM)
  );

  hazard hu(
    // from datapath
    .Rs1D        (Rs1D),
    .Rs2D        (Rs2D),
    .Rs1E        (Rs1E),
    .Rs2E        (Rs2E),
    .RdE         (RdE),
    .RdM         (RdM),
    .RdW         (RdW),
    // from controller
    .PCSrcE      (PCSrcE),
    .ResultSrcEb0(ResultSrcEb0),
    .RegWriteM   (RegWriteM),
    .RegWriteW   (RegWriteW),
    // to datapath
    .ForwardAE   (ForwardAE),
    .ForwardBE   (ForwardBE),
    .StallF      (StallF),
    .StallD      (StallD),
    .FlushD      (FlushD),
    // to datapath and controller
    .FlushE      (FlushE)
  );

endmodule
