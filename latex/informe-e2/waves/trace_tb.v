// Prints one line per cycle with the signals used by the E2 waveforms (dual-issue design).
// Cycle k = [10k, 10k+10), clk rises at 10k; signals are sampled at 10k+8 (stable,
// after the falling-edge register file write). Run from the repo root:
//   iverilog -g2012 -o t.out designs/dualissue/*.v latex/informe-e2/waves/trace_tb.v
//   vvp -n t.out +prog=tb/programs/dualissue/alu_pair.mem
module trace_tb;
  reg clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  top dut(.clk(clk), .reset(reset), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));

  `define DP dut.rvpipe.dp
  `define HU dut.rvpipe.hu
  `define IU dut.rvpipe.iu
  `define CT dut.rvpipe.c

  initial begin reset = 1; #22; reset = 0; end
  initial clk = 1;
  always #5 clk = ~clk;

  integer cyc = 0, left = -1;
  initial begin
    $display("cycle reset PCF InstrF_0 InstrF_1 InstrD_0 InstrD_1 PCD_0 PCD_1 InstrE_0 InstrE_1 InstrM_0 InstrM_1 InstrW_0 InstrW_1 IssueOneD LoadUseD_0 RegroupD StallF StallD FlushD FlushE_0 FlushE_1 FlushM_1 ForwardAE_0 ForwardBE_0 ForwardAE_1 ForwardBE_1 SrcAE_0 SrcBE_0 ALUResultE_0 SrcAE_1 SrcBE_1 ALUResultE_1 BranchE_0 JumpE_0 BranchE_1 JumpE_1 BrLaneE PCSrcE TakenE_0 PCTargetE MemLaneM MemWrite DataAdr WriteData ReadDataM RegWriteW_0 RdW_0 ResultW_0 RegWriteW_1 RdW_1 ResultW_1 Rs1E_0 Rs2E_0 Rs1E_1 Rs2E_1 RdM_0 RdM_1 RdE_0 RdE_1 x3");
    forever begin
      #8;
      $display("%0d %b %h %h %h %h %h %h %h %h %h %h %h %h %h %b %b %b %b %b %b %b %b %b %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %b %b %b %b %b %b %b %h %b %b %0d %0d %0d %b %0d %0d %b %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
        cyc, reset, `DP.PCF, `DP.InstrF_0, `DP.InstrF_1, `DP.InstrD_0, `DP.InstrD_1, `DP.PCD_0, `DP.PCD_1,
        `DP.InstrE_0, `DP.InstrE_1, `DP.InstrM_0, `DP.InstrM_1, `DP.InstrW_0, `DP.InstrW_1,
        `IU.IssueOneD, `IU.LoadUseD_0, `HU.RegroupD, `HU.StallF, `HU.StallD, `HU.FlushD,
        `HU.FlushE_0, `HU.FlushE_1, `HU.FlushM_1,
        `HU.ForwardAE_0, `HU.ForwardBE_0, `HU.ForwardAE_1, `HU.ForwardBE_1,
        $signed(`DP.SrcAE_0), $signed(`DP.SrcBE_0), $signed(`DP.ALUResultE_0),
        $signed(`DP.SrcAE_1), $signed(`DP.SrcBE_1), $signed(`DP.ALUResultE_1),
        `CT.BranchE_0, `CT.JumpE_0, `CT.BranchE_1, `CT.JumpE_1, `DP.bu.BrLaneE,
        `DP.PCSrcE, `DP.TakenE_0, `DP.PCTargetE,
        `DP.MemLaneM, MemWrite, $signed(DataAdr), $signed(WriteData), $signed(dut.ReadData),
        `DP.RegWriteW_0, `DP.RdW_0, $signed(`DP.ResultW_0),
        `DP.RegWriteW_1, `DP.RdW_1, $signed(`DP.ResultW_1),
        `DP.Rs1E_0, `DP.Rs2E_0, `DP.Rs1E_1, `DP.Rs2E_1, `DP.RdM_0, `DP.RdM_1, `DP.RdE_0, `DP.RdE_1,
        $signed(`DP.rf.rf[3]));
      // stop two cycles after the halt (jal x0,0) reaches WB
      if (left < 0 && (`DP.InstrW_0 == 32'h6F || `DP.InstrW_1 == 32'h6F)) left = 1;
      else if (left > 0) left = left - 1;
      else if (left == 0) $finish;
      #2; cyc = cyc + 1;
    end
  end
  initial #3000 $finish;
endmodule
