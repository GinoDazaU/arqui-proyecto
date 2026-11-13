module hazard(// from datapath
              input  [4:0] Rs1E_0, Rs2E_0, RdM_0, RdW_0,
              input  [4:0] Rs1E_1, Rs2E_1, RdM_1, RdW_1,
              // from the branch unit
              input        MispredictE,
              input        FlushLane1E,
              // from controller
              input        RegWriteM_0, RegWriteW_0,
              input        RegWriteM_1, RegWriteW_1,
              // from issue unit
              input        LoadUseD_0,
              input        IssueOneD,
              // to datapath
              output [2:0] ForwardAE_0, ForwardBE_0,
              output [2:0] ForwardAE_1, ForwardBE_1,
              output       StallF, StallD,
              output       FlushD,
              output       RegroupD,
              // to datapath and controller
              output       FlushE_0, FlushE_1,
              output       FlushM_1);

  wire lwStallD;

  // ================= FORWARDING =================
  // sources: 000 = register file, 001 = WB lane 0, 010 = WB lane 1,
  //          011 = MEM lane 0,   100 = MEM lane 1
  // priority = youngest producer first: MEM before WB and, inside the same
  // stage, lane 1 (younger) before lane 0
  // (all inputs are function arguments so the assigns re-evaluate when any of them changes)
  function [2:0] fwd(input [4:0] rs, input [4:0] rdM1, rdM0, rdW1, rdW0,
                     input       weM1, weM0, weW1, weW0);
    if      (rs == 5'b0)            fwd = 3'b000;
    else if ((rs == rdM1) & weM1)   fwd = 3'b100;
    else if ((rs == rdM0) & weM0)   fwd = 3'b011;
    else if ((rs == rdW1) & weW1)   fwd = 3'b010;
    else if ((rs == rdW0) & weW0)   fwd = 3'b001;
    else                            fwd = 3'b000;
  endfunction

  `define FWD(rs) fwd(rs, RdM_1, RdM_0, RdW_1, RdW_0, RegWriteM_1, RegWriteM_0, RegWriteW_1, RegWriteW_0)

  assign ForwardAE_0 = `FWD(Rs1E_0);
  assign ForwardBE_0 = `FWD(Rs2E_0);
  assign ForwardAE_1 = `FWD(Rs1E_1);
  assign ForwardBE_1 = `FWD(Rs2E_1);

  `undef FWD

  // ================= STALLS, REGROUP AND FLUSHES =================
  // a mispredicted branch/jump in Execute has priority: the pair in Decode is wrong-path anyway
  assign lwStallD = LoadUseD_0 & ~MispredictE;
  assign StallD   = lwStallD;
  assign StallF   = lwStallD;

  // only slot 0 issues: slot 1 is kept in IF/ID as the new slot 0, PC advances 4
  assign RegroupD = IssueOneD & ~lwStallD & ~MispredictE;

  // mispredicted branch/jump: discard the younger instructions in Fetch and Decode
  assign FlushD   = MispredictE;
  assign FlushE_0 = lwStallD | MispredictE;             // bubble for the lw stall
  assign FlushE_1 = lwStallD | MispredictE | IssueOneD; // bubble also when slot 1 waits
  // mispredicted branch in lane 0: the other instruction of its pair (lane 1) is younger
  // and is annulled; a branch in lane 1 keeps lane 0 (older)
  assign FlushM_1 = FlushLane1E;

endmodule
