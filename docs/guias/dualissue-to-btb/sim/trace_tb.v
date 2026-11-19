// One line per cycle with the PCs in each stage and the prediction signals, used to draw
// the execution diagrams of the guide. Works with the dual-issue design (no prediction)
// and, with -DOPT, with the BTB design. Run from the repo root:
//   iverilog -g2012 -DOPT -o t.out designs/dualissue-btb/*.v docs/guias/dualissue-to-btb/sim/trace_tb.v
//   vvp -n t.out +prog=tb/programs/opt/pred_slot0.mem
module trace_tb;
  reg clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  top dut(.clk(clk), .reset(reset), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));

  `define DP dut.rvpipe.dp
  `define HU dut.rvpipe.hu

  initial begin reset = 1; #22; reset = 0; end
  initial clk = 1;
  always #5 clk = ~clk;

  integer cyc = 0, left = -1;
  initial begin
    $display("cyc PCF D0 D1 iD0 iD1 E0 E1 iE0 iE1 iM0 iM1 iW0 iW1 pF0 pF1 an rg st misp fl1 pcn ctr");
    forever begin
      #8;
      if (!reset)
      $display("%0d %0d %0d %0d %h %h %0d %0d %h %h %h %h %h %h %b %b %b %b %b %b %b %0d %s",
        cyc, `DP.PCF, `DP.PCD_0, `DP.PCD_1, `DP.InstrD_0, `DP.InstrD_1,
        `DP.PCE_0, `DP.PCE_1, `DP.InstrE_0, `DP.InstrE_1,
        `DP.InstrM_0, `DP.InstrM_1, `DP.InstrW_0, `DP.InstrW_1,
`ifdef OPT
        `DP.PredF_0, `DP.PredF_1, `DP.AnnulF_1,
`else
        1'b0, 1'b0, 1'b0,
`endif
        `HU.RegroupD, `HU.StallD,
`ifdef OPT
        `DP.MispredictE, `DP.FlushLane1E,
`else
        `DP.PCSrcE, `DP.TakenE_0,
`endif
        `DP.PCNextF, "");
      if (!reset) begin
        if (left < 0 && (`DP.InstrW_0 == 32'h6F || `DP.InstrW_1 == 32'h6F)) left = 1;
        else if (left > 0) left = left - 1;
        else if (left == 0) $finish;
        #2; cyc = cyc + 1;
      end else #2;
    end
  end
  initial #20000 $finish;
endmodule
