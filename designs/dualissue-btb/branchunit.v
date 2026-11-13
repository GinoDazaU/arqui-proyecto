// Branch Unit: the single branch resolution resource, shared by both lanes (Execute).
// The issue unit never sends two branches/jumps in the same pair, so at most one
// lane holds a control instruction. The unit takes the operands of that lane,
// compares them (beq) with one comparator and computes the target with one adder.
// It also checks the prediction made in Fetch and drives the BTB update.
//   BrLaneE = 0: the branch/jump is in lane 0 (or there is none)
//   BrLaneE = 1: the branch/jump is in lane 1
module branchunit(// from controller (Execute)
                  input         BranchE_0, JumpE_0,
                  input         BranchE_1, JumpE_1,
                  // from datapath (Execute, operands already forwarded)
                  input  [31:0] PCE_0, PCPlus4E_0, ImmExtE_0, SrcAE_0, WriteDataE_0,
                  input  [31:0] PCE_1, PCPlus4E_1, ImmExtE_1, SrcAE_1, WriteDataE_1,
                  // prediction made in Fetch
                  input         PredE_0, PredE_1,
                  input  [31:0] TargetE_0, TargetE_1,
                  // to Fetch and hazard unit
                  output        MispredictE,
                  output        FlushLane1E,
                  output [31:0] PCCorrectE,
                  // to BTB
                  output        CtrlE, JumpE, PCSrcE,
                  output [31:0] PCE, PCTargetE);

  localparam WIDTH = 32; // bus width

  wire [31:0] PCPlus4E, ImmExtE, SrcAE, SrcBE, PredTargetE;
  wire        BranchE, EqualE, PredTakenE;

  // lane that owns the branch unit this cycle
  wire BrLaneE = BranchE_1 | JumpE_1;

  // ================= OPERAND SELECTION =================
  mux2 #(WIDTH) pcmux  (.d0(PCE_0),        .d1(PCE_1),        .s(BrLaneE), .y(PCE));
  mux2 #(WIDTH) pc4mux (.d0(PCPlus4E_0),   .d1(PCPlus4E_1),   .s(BrLaneE), .y(PCPlus4E));
  mux2 #(WIDTH) immmux (.d0(ImmExtE_0),    .d1(ImmExtE_1),    .s(BrLaneE), .y(ImmExtE));
  mux2 #(WIDTH) amux   (.d0(SrcAE_0),      .d1(SrcAE_1),      .s(BrLaneE), .y(SrcAE));
  mux2 #(WIDTH) bmux   (.d0(WriteDataE_0), .d1(WriteDataE_1), .s(BrLaneE), .y(SrcBE));
  mux2 #(1)     predmux(.d0(PredE_0),      .d1(PredE_1),      .s(BrLaneE), .y(PredTakenE));
  mux2 #(WIDTH) tgtmux (.d0(TargetE_0),    .d1(TargetE_1),    .s(BrLaneE), .y(PredTargetE));

  // at most one lane is active, so an OR is enough
  assign BranchE = BranchE_0 | BranchE_1;
  assign JumpE   = JumpE_0   | JumpE_1;
  assign CtrlE   = BranchE | JumpE;

  // ================= RESOLUTION =================
  // one comparator (beq: rs1 == rs2) and one target adder (PC + imm)
  assign EqualE = (SrcAE == SrcBE);

  adder pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  assign PCSrcE = (BranchE & EqualE) | JumpE;

  // ================= VERIFICATION =================
  // wrong direction, or taken to a different target
  assign MispredictE = CtrlE & ((PCSrcE != PredTakenE) | (PCSrcE & (PCTargetE != PredTargetE)));

  mux2 #(WIDTH) correctmux(
    .d0(PCPlus4E),
    .d1(PCTargetE),
    .s (PCSrcE),
    .y (PCCorrectE)
  );

  // mispredicted branch in lane 0: lane 1 is younger and on the wrong path
  assign FlushLane1E = MispredictE & ~BrLaneE;

endmodule
