module hazard(// from datapath
              input  [4:0] Rs1D_0, Rs2D_0, Rs1E_0, Rs2E_0,
              input  [4:0] RdE_0, RdM_0, RdW_0,
              input  [4:0] Rs1D_1, Rs2D_1, Rs1E_1, Rs2E_1,
              input  [4:0] RdE_1, RdM_1, RdW_1,
              // from controller
              input        PCSrcE,
              input        ResultSrcEb0_0,
              input        RegWriteM_0, RegWriteW_0,
              input        ResultSrcEb0_1,
              input        RegWriteM_1, RegWriteW_1,
              // to datapath
              output reg [1:0] ForwardAE_0, ForwardBE_0,
              output     [1:0] ForwardAE_1, ForwardBE_1,
              output           StallF, StallD,
              output           FlushD,
              // to datapath and controller
              output           FlushE);

  wire lwStallD;

  // ================= FORWARDING =================
  // 00 = register file, 01 = Writeback, 10 = Memory (Memory has priority)
  always @(*) begin
    ForwardAE_0 = 2'b00;
    ForwardBE_0 = 2'b00;

    if (Rs1E_0 != 5'b0) begin
      if      ((Rs1E_0 == RdM_0) & RegWriteM_0) ForwardAE_0 = 2'b10;
      else if ((Rs1E_0 == RdW_0) & RegWriteW_0) ForwardAE_0 = 2'b01;
    end

    if (Rs2E_0 != 5'b0) begin
      if      ((Rs2E_0 == RdM_0) & RegWriteM_0) ForwardBE_0 = 2'b10;
      else if ((Rs2E_0 == RdW_0) & RegWriteW_0) ForwardBE_0 = 2'b01;
    end
  end

  // lane 1 does not execute yet: no forwarding
  assign ForwardAE_1 = 2'b00;
  assign ForwardBE_1 = 2'b00;

  // ================= STALLS AND FLUSHES =================
  // lw stall: lw in Execute, its destination is used by the instruction in Decode
  assign lwStallD = ResultSrcEb0_0 & ((Rs1D_0 == RdE_0) | (Rs2D_0 == RdE_0));
  assign StallD   = lwStallD;
  assign StallF   = lwStallD;

  // taken branch/jump: discard the wrongly fetched instructions
  assign FlushD   = PCSrcE;
  assign FlushE   = lwStallD | PCSrcE;  // also inserts the bubble for the lw stall

endmodule
