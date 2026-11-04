module hazard(// from datapath
              input  [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
              input  [4:0] RdE, RdM, RdW,
              // from controller
              input        PCSrcE,
              input        ResultSrcEb0,
              input        RegWriteM, RegWriteW,
              // to datapath
              output reg [1:0] ForwardAE, ForwardBE,
              output           StallF, StallD,
              output           FlushD,
              // to datapath and controller
              output           FlushE);

  wire lwStallD;

  // ================= FORWARDING =================
  // 00 = register file, 01 = Writeback, 10 = Memory (Memory has priority)
  always @(*) begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    if (Rs1E != 5'b0) begin
      if      ((Rs1E == RdM) & RegWriteM) ForwardAE = 2'b10;
      else if ((Rs1E == RdW) & RegWriteW) ForwardAE = 2'b01;
    end

    if (Rs2E != 5'b0) begin
      if      ((Rs2E == RdM) & RegWriteM) ForwardBE = 2'b10;
      else if ((Rs2E == RdW) & RegWriteW) ForwardBE = 2'b01;
    end
  end

  // ================= STALLS AND FLUSHES =================
  // lw stall: lw in Execute, its destination is used by the instruction in Decode
  assign lwStallD = ResultSrcEb0 & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallD   = lwStallD;
  assign StallF   = lwStallD;

  // taken branch/jump: discard the wrongly fetched instructions
  assign FlushD   = PCSrcE;
  assign FlushE   = lwStallD | PCSrcE;  // also inserts the bubble for the lw stall

endmodule
