// Final-report testbench, shared by the three designs (same ifdefs as tb/perf_tb.v):
//   iverilog -g2012              -o A.out designs/pipeline/*.v      docs/informes/informe-final/waves/final_tb.v
//   iverilog -g2012 -DDUAL       -o B.out designs/dualissue/*.v     docs/informes/informe-final/waves/final_tb.v
//   iverilog -g2012 -DDUAL -DOPT -o C.out designs/dualissue-btb/*.v docs/informes/informe-final/waves/final_tb.v
//   vvp -n C.out +prog=tb/programs/final/programa.mem [+trace]
//
// 1) Stage checks of the professor's program (docs/programa.pdf). A stage closes when its last
//    instruction (the store that ends it) reaches WB; at that moment every older instruction has
//    written its register and memory, and the testbench compares the 31 registers and the 14 data
//    words at x1 = 1536 against the reference state of the statement. The comparison uses the
//    register file as it was *before* a younger instruction that retires in the same cycle (lane 1)
//    wrote it, so the state is exactly the one of the program order.
//      chk   = stage that closes in this cycle (1..4 = A..D, 0 = none)
//      ok    = result of that comparison (1 = equal to the reference)
// 2) Metrics with the same criterion as perf_tb (cycle 1 = first cycle after reset, end = halt in
//    WB) and, as the statement asks, excluding the final loop `fin` (end = stage D closes).
// 3) With +trace (dual-issue designs) one line per cycle for the waveforms (waves.py).
module final_tb;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  top dut(.clk(clk), .reset(reset), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));

  `define DP dut.rvpipe.dp
  `define HU dut.rvpipe.hu
  localparam HALT = 32'h0000006F;  // jal x0, 0  (fin: jal x0, fin)
  localparam BASE = 1536 / 4;      // word index of x1 = 1536

  // last instruction of each stage
  localparam [31:0] END_A = 32'h00A0A423,   // sw x10, 8(x1)
                    END_B = 32'h0120AA23,   // sw x18, 20(x1)
                    END_C = 32'h0380A023,   // sw x24, 32(x1)
                    END_D = 32'h03F0AA23;   // sw x31, 52(x1)

`ifdef DUAL
  wire [31:0] InstrW_0 = `DP.InstrW_0, InstrW_1 = `DP.InstrW_1;
  wire        youngW   = `DP.RegWriteW_1;  // lane 1 is younger than lane 0
  wire [4:0]  youngRd  = `DP.RdW_1;
`else
  wire [31:0] InstrW_0 = `DP.InstrW, InstrW_1 = 32'b0;
  wire        youngW   = 1'b0;
  wire [4:0]  youngRd  = 5'b0;
`endif

  // ================= REFERENCE STATE (docs/programa.pdf) =================
  // -1 = word not written yet; registers not listed = 0
  integer expR [1:4][1:31];
  integer expM [1:4][0:13];
  integer s, r, w;
  initial begin
    for (s = 1; s <= 4; s = s + 1) begin
      for (r = 1; r <= 31; r = r + 1) expR[s][r] = 0;
      for (w = 0; w < 14; w = w + 1) expM[s][w] = -1;
    end
    // A
    expR[1][1]=1536; expR[1][2]=1; expR[1][3]=8; expR[1][4]=3; expR[1][5]=11; expR[1][6]=5;
    expR[1][7]=16;   expR[1][8]=2; expR[1][9]=7; expR[1][10]=12;
    expM[1][0]=11; expM[1][1]=5; expM[1][2]=12;
    // B = A + ...
    for (r = 1; r <= 31; r = r + 1) expR[2][r] = expR[1][r];
    for (w = 0; w < 14; w = w + 1)  expM[2][w] = expM[1][w];
    expR[2][11]=11; expR[2][12]=16; expR[2][13]=5; expR[2][14]=12; expR[2][15]=7; expR[2][16]=7;
    expR[2][17]=16; expR[2][18]=23;
    expM[2][3]=7; expM[2][4]=16; expM[2][5]=23;
    // C = B + ...
    for (r = 1; r <= 31; r = r + 1) expR[3][r] = expR[2][r];
    for (w = 0; w < 14; w = w + 1)  expM[3][w] = expM[2][w];
    expR[3][19]=12; expR[3][20]=12; expR[3][21]=24; expR[3][22]=18; expR[3][24]=24; expR[3][26]=6;
    expM[3][6]=24; expM[3][7]=18; expM[3][8]=24;
    // D = C + ...
    for (r = 1; r <= 31; r = r + 1) expR[4][r] = expR[3][r];
    for (w = 0; w < 14; w = w + 1)  expM[4][w] = expM[3][w];
    expR[4][19]=6; expR[4][20]=6; expR[4][25]=4; expR[4][26]=4; expR[4][27]=1560; expR[4][28]=74;
    expR[4][29]=4; expR[4][30]=23; expR[4][31]=1;
    expM[4][9]=74; expM[4][10]=4; expM[4][11]=0; expM[4][12]=1; expM[4][13]=1;
  end

  // ================= CLOCK AND RESET =================
  initial begin reset = 1; #22; reset = 0; end
  initial clk = 1;
  always #5 clk = ~clk;

  // register file just before the falling-edge write of the current cycle
  reg [31:0] snap [1:31];
  always @(posedge clk) #4 for (r = 1; r <= 31; r = r + 1) snap[r] = `DP.rf.rf[r];

  // architectural value of register i in program order at the end of the stage
  function [31:0] arch(input integer i, input integer lane);
    // lane = lane of the closing store; a younger lane-1 write in the same cycle is undone
    arch = (lane == 0 && youngW && youngRd == i) ? snap[i] : `DP.rf.rf[i];
  endfunction

  function integer val(input [31:0] v);  // x (never written) reads as 0 for registers
    val = (^v === 1'bx) ? 0 : $signed(v);
  endfunction

  // ================= PER-CYCLE SAMPLING =================
  integer cyc, retired, retNoFin, cycNoFin, nbad, lane, i, stage, done;
  integer okStage [1:4], cycStage [1:4];
  reg     ok;
  reg     tracing;

  initial begin
    cyc = 0; retired = 0; retNoFin = 0; cycNoFin = 0; done = 0;
    for (s = 1; s <= 4; s = s + 1) begin okStage[s] = 0; cycStage[s] = 0; end
    tracing = $test$plusargs("trace");
    if (tracing) header;
    // cycle k = [10k+10, 10k+20): cycle 1 is the first one after reset (as in perf_tb)
    #18;
    forever begin
      sample;
      #10;
    end
  end

  task sample;
    begin
      if (!reset) cyc = cyc + 1;
      stage = 0; ok = 0; lane = 0;
      if (InstrW_0 == END_A || InstrW_1 == END_A) stage = 1;
      if (InstrW_0 == END_B || InstrW_1 == END_B) stage = 2;
      if (InstrW_0 == END_C || InstrW_1 == END_C) stage = 3;
      if (InstrW_0 == END_D || InstrW_1 == END_D) stage = 4;
      if (stage != 0) begin
        lane = (InstrW_1 == END_A || InstrW_1 == END_B || InstrW_1 == END_C || InstrW_1 == END_D);
        nbad = 0;
        for (i = 1; i <= 31; i = i + 1)
          if (val(arch(i, lane)) != expR[stage][i]) begin
            nbad = nbad + 1;
            $display("  stage %c: x%0d = %0d, expected %0d", "@" + stage, i, val(arch(i, lane)), expR[stage][i]);
          end
        for (w = 0; w < 14; w = w + 1)
          if (expM[stage][w] == -1 ? (^dut.dmem.RAM[BASE + w] !== 1'bx)
                                   : (dut.dmem.RAM[BASE + w] !== expM[stage][w])) begin
            nbad = nbad + 1;
            $display("  stage %c: MEM[x1+%0d] = %0d, expected %0d", "@" + stage, 4 * w,
                     $signed(dut.dmem.RAM[BASE + w]), expM[stage][w]);
          end
        ok = (nbad == 0);
        okStage[stage] = ok; cycStage[stage] = cyc;
      end
      if (!reset && !done) begin
        // retired = instructions that reach WB (bubbles are 0), as in perf_tb
        if (InstrW_0 != 0) retired = retired + 1;
        if (InstrW_1 != 0) retired = retired + 1;
        if (stage == 4) begin  // end of D: count only up to the closing store
          cycNoFin = cyc;
          retNoFin = retired - ((lane == 0 && InstrW_1 != 0) ? 1 : 0);
        end
      end
      if (tracing) line;
      if (!reset && !done && (InstrW_0 == HALT || InstrW_1 == HALT)) begin
        done = 1;
        report;
        #25 $finish;  // a couple more trace lines after the halt
      end
    end
  endtask

  task report;
    begin
      for (s = 1; s <= 4; s = s + 1)
        $display("  STAGE %c: cycle=%0d %0s", "@" + s, cycStage[s],
                 cycStage[s] == 0 ? "NOT REACHED" : okStage[s] ? "OK" : "FAIL");
      $display("  cycles=%0d retired=%0d IPC=%0.3f CPI=%0.3f", cyc, retired,
               1.0 * retired / cyc, 1.0 * cyc / retired);
      if (cycNoFin)
        $display("  nofin_cycles=%0d nofin_retired=%0d nofin_IPC=%0.3f nofin_CPI=%0.3f", cycNoFin, retNoFin,
                 1.0 * retNoFin / cycNoFin, 1.0 * cycNoFin / retNoFin);
    end
  endtask

  // ================= TRACE (+trace, dual-issue designs) =================
`ifdef DUAL
  `define BU `DP.bu
`ifdef OPT
  wire        PredF_0 = `DP.PredF_0, PredF_1 = `DP.PredF_1, AnnulF_1 = `DP.AnnulF_1;
  wire [31:0] TargetF_0 = `DP.TargetF_0, TargetF_1 = `DP.TargetF_1;
  wire        PredD_0 = `DP.PredD_0, PredD_1 = `DP.PredD_1;
  wire        CtrlE = `BU.CtrlE, PredTakenE = `BU.PredTakenE, MispredictE = `BU.MispredictE;
  wire        FlushLane1E = `BU.FlushLane1E, BtbHitE = `DP.predictor.uhit;
  wire [31:0] PredTargetE = `BU.PredTargetE, PCCorrectE = `BU.PCCorrectE;
  wire [1:0]  CtrE = `DP.predictor.uctr;
  wire [31:0] PCBrE = `BU.PCE;
`else
  // without prediction: always "not taken", a taken branch is the misprediction
  wire        PredF_0 = 0, PredF_1 = 0, AnnulF_1 = 0, PredD_0 = 0, PredD_1 = 0;
  wire [31:0] TargetF_0 = 0, TargetF_1 = 0;
  wire        CtrlE = `BU.BranchE | `BU.JumpE, PredTakenE = 0, MispredictE = `DP.PCSrcE;
  wire        FlushLane1E = `DP.TakenE_0, BtbHitE = 0;
  wire [31:0] PredTargetE = 0, PCCorrectE = `DP.PCTargetE;
  wire [1:0]  CtrE = 0;
  wire [31:0] PCBrE = `BU.BrLaneE ? `DP.PCE_1 : `DP.PCE_0;
`endif

  task header;
    begin
      $write("cycle reset PCF PCNextF InstrF_0 InstrF_1 PCD_0 PCD_1 InstrD_0 InstrD_1 InstrE_0 InstrE_1");
      $write(" InstrM_0 InstrM_1 InstrW_0 InstrW_1 IssueOneD LoadUseD_0 RegroupD StallF StallD FlushD");
      $write(" FlushE_0 FlushE_1 FlushM_1 ForwardAE_0 ForwardBE_0 ForwardAE_1 ForwardBE_1");
      $write(" ALUResultE_0 ALUResultE_1 BrLaneE PCSrcE PCTargetE");
      $write(" PredF_0 PredF_1 TargetF_0 TargetF_1 AnnulF_1 PredD_0 PredD_1 CtrlE PCBrE PredTakenE PredTargetE");
      $write(" MispredictE PCCorrectE FlushLane1E BtbHitE CtrE");
      $write(" MemLaneM MemWrite DataAdr WriteData ReadDataM RegWriteW_0 RdW_0 ResultW_0 RegWriteW_1 RdW_1 ResultW_1");
      $write(" chk ok");
      for (i = 1; i <= 31; i = i + 1) $write(" x%0d", i);
      for (w = 0; w < 14; w = w + 1) $write(" M%0d", 4 * w);
      $write("\n");
    end
  endtask

  task line;
    begin
      $write("%0d %b %h %h %h %h %h %h %h %h %h %h", cyc, reset, `DP.PCF, `DP.PCNextF, `DP.InstrF_0, `DP.InstrF_1,
             `DP.PCD_0, `DP.PCD_1, `DP.InstrD_0, `DP.InstrD_1, `DP.InstrE_0, `DP.InstrE_1);
      $write(" %h %h %h %h %b %b %b %b %b %b", `DP.InstrM_0, `DP.InstrM_1, InstrW_0, InstrW_1,
             dut.rvpipe.iu.IssueOneD, dut.rvpipe.iu.LoadUseD_0, `HU.RegroupD, `HU.StallF, `HU.StallD, `HU.FlushD);
      $write(" %b %b %b %0d %0d %0d %0d", `HU.FlushE_0, `HU.FlushE_1, `HU.FlushM_1,
             `HU.ForwardAE_0, `HU.ForwardBE_0, `HU.ForwardAE_1, `HU.ForwardBE_1);
      $write(" %0d %0d %b %b %h", $signed(`DP.ALUResultE_0), $signed(`DP.ALUResultE_1), `BU.BrLaneE,
             `BU.PCSrcE, `BU.PCTargetE);
      $write(" %b %b %h %h %b %b %b %b %h %b %h", PredF_0, PredF_1, TargetF_0, TargetF_1, AnnulF_1,
             PredD_0, PredD_1, CtrlE, PCBrE, PredTakenE, PredTargetE);
      $write(" %b %h %b %b %b", MispredictE, PCCorrectE, FlushLane1E, BtbHitE, CtrE);
      $write(" %b %b %0d %0d %0d %b %0d %0d %b %0d %0d", `DP.MemLaneM, MemWrite, $signed(DataAdr),
             $signed(WriteData), $signed(dut.ReadData), `DP.RegWriteW_0, `DP.RdW_0, $signed(`DP.ResultW_0),
             `DP.RegWriteW_1, `DP.RdW_1, $signed(`DP.ResultW_1));
      $write(" %0d %b", stage, ok);
      for (i = 1; i <= 31; i = i + 1) $write(" %0d", val(`DP.rf.rf[i]));
      for (w = 0; w < 14; w = w + 1)
        if (^dut.dmem.RAM[BASE + w] === 1'bx) $write(" x"); else $write(" %0d", $signed(dut.dmem.RAM[BASE + w]));
      $write("\n");
    end
  endtask
`else
  task header; endtask
  task line; endtask
`endif

  initial begin
    #2000000 $display("  TIMEOUT: halt never reached WB");
    $finish;
  end
endmodule
