// Branch Unit: the single branch resolution resource, shared by both lanes (Execute).
// The issue unit never sends two branches/jumps in the same pair, so at most one
// lane holds a control instruction. The unit takes the operands of that lane,
// compares them (beq) with one comparator and computes the target with one adder.
//   BrLaneE = 0: the branch/jump is in lane 0 (or there is none)
//   BrLaneE = 1: the branch/jump is in lane 1
module branchunit(// from controller (Execute)
                  input         BranchE_0, JumpE_0,
                  input         BranchE_1, JumpE_1,
                  // from datapath (Execute, operands already forwarded)
                  input  [31:0] PCE_0, ImmExtE_0, SrcAE_0, WriteDataE_0,
                  input  [31:0] PCE_1, ImmExtE_1, SrcAE_1, WriteDataE_1,
                  // to Fetch and hazard unit
                  output        PCSrcE,
                  output        TakenE_0,
                  output [31:0] PCTargetE);

  localparam WIDTH = 32; // bus width

  wire [31:0] PCE, ImmExtE, SrcAE, SrcBE;
  wire        BranchE, JumpE, EqualE;

  // lane that owns the branch unit this cycle
  wire BrLaneE = BranchE_1 | JumpE_1;

  // ================= OPERAND SELECTION =================
  mux2 #(WIDTH) pcmux (.d0(PCE_0),        .d1(PCE_1),        .s(BrLaneE), .y(PCE));
  mux2 #(WIDTH) immmux(.d0(ImmExtE_0),    .d1(ImmExtE_1),    .s(BrLaneE), .y(ImmExtE));
  mux2 #(WIDTH) amux  (.d0(SrcAE_0),      .d1(SrcAE_1),      .s(BrLaneE), .y(SrcAE));
  mux2 #(WIDTH) bmux  (.d0(WriteDataE_0), .d1(WriteDataE_1), .s(BrLaneE), .y(SrcBE));

  // at most one lane is active, so an OR is enough
  assign BranchE = BranchE_0 | BranchE_1;
  assign JumpE   = JumpE_0   | JumpE_1;

  // ================= RESOLUTION =================
  // one comparator (beq: rs1 == rs2) and one target adder (PC + imm)
  assign EqualE = (SrcAE == SrcBE);

  adder pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  assign PCSrcE   = (BranchE & EqualE) | JumpE;
  // taken in lane 0: the other instruction of the pair (lane 1) is younger -> FlushM_1
  assign TakenE_0 = PCSrcE & ~BrLaneE;

endmodule
