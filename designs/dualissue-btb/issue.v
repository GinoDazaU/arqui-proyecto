// Issue Unit: decides, in Decode, how many instructions of the pair go to Execute.
//   slot 0 = older instruction (PCD_0), slot 1 = younger instruction (PCD_0 + 4)
//   - LoadUseD_0 = 1: slot 0 depends on a lw in Execute -> nothing issues (stall)
//   - IssueOneD  = 1: only slot 0 issues; slot 1 is kept and regrouped as the next slot 0
//   - both 0       : the two instructions issue together
// Memory and branch resources are shared, but either slot can use them: the
// datapath gives the data memory port / branch unit to the lane that needs it.
module issue(// from datapath (pair in Decode)
             input  [31:0] InstrD_0, InstrD_1,
             // from datapath / controller (instructions in Execute)
             input  [4:0]  RdE_0, RdE_1,
             input         ResultSrcEb0_0, ResultSrcEb0_1,  // 1 = lw in Execute
             // to hazard unit
             output        LoadUseD_0,
             output        IssueOneD);

  // ================= DECODE OF THE PAIR =================
  wire [6:0] op_0  = InstrD_0[6:0],   op_1  = InstrD_1[6:0];
  wire [4:0] rs1_0 = InstrD_0[19:15], rs1_1 = InstrD_1[19:15];
  wire [4:0] rs2_0 = InstrD_0[24:20], rs2_1 = InstrD_1[24:20];
  wire [4:0] rd_0  = InstrD_0[11:7];

  wire load_0  = (op_0 == 7'b0000011), load_1  = (op_1 == 7'b0000011);
  wire store_0 = (op_0 == 7'b0100011), store_1 = (op_1 == 7'b0100011);
  wire rtype_0 = (op_0 == 7'b0110011), rtype_1 = (op_1 == 7'b0110011);
  wire itype_0 = (op_0 == 7'b0010011), itype_1 = (op_1 == 7'b0010011);
  wire beq_0   = (op_0 == 7'b1100011), beq_1   = (op_1 == 7'b1100011);
  wire jal_0   = (op_0 == 7'b1101111), jal_1   = (op_1 == 7'b1101111);

  // which source registers each instruction really reads
  wire useRs1_0 = load_0 | store_0 | rtype_0 | itype_0 | beq_0;
  wire useRs2_0 = store_0 | rtype_0 | beq_0;
  wire useRs1_1 = load_1 | store_1 | rtype_1 | itype_1 | beq_1;
  wire useRs2_1 = store_1 | rtype_1 | beq_1;

  wire writes_0 = (load_0 | rtype_0 | itype_0 | jal_0) & (rd_0 != 5'b0);
  wire mem_0    = load_0 | store_0, mem_1  = load_1 | store_1;
  wire ctrl_0   = beq_0  | jal_0,   ctrl_1 = beq_1  | jal_1;

  // ================= ISSUE CONDITIONS =================
  // RAW inside the pair: slot 1 needs the result of slot 0 in the same cycle (cannot forward)
  wire rawD   = writes_0 & ((useRs1_1 & (rs1_1 == rd_0)) | (useRs2_1 & (rs2_1 == rd_0)));
  // structural: one data memory port, one branch unit
  wire memD   = mem_0  & mem_1;
  wire ctrlD  = ctrl_0 & ctrl_1;

  // load-use with a lw in Execute (either lane)
  // (all inputs are function arguments so the assigns re-evaluate when any of them changes)
  function loaduse(input [4:0] rs1, rs2, input u1, u2,
                   input [4:0] rdE0, rdE1, input lwE0, lwE1);
    loaduse = (lwE0 & (rdE0 != 5'b0) & ((u1 & (rs1 == rdE0)) | (u2 & (rs2 == rdE0)))) |
              (lwE1 & (rdE1 != 5'b0) & ((u1 & (rs1 == rdE1)) | (u2 & (rs2 == rdE1))));
  endfunction

  wire luseD_1 = loaduse(rs1_1, rs2_1, useRs1_1, useRs2_1, RdE_0, RdE_1, ResultSrcEb0_0, ResultSrcEb0_1);

  assign LoadUseD_0 = loaduse(rs1_0, rs2_0, useRs1_0, useRs2_0, RdE_0, RdE_1, ResultSrcEb0_0, ResultSrcEb0_1);
  assign IssueOneD  = rawD | memD | ctrlD | luseD_1;

endmodule
