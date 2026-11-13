// Performance / equivalence testbench, shared by the three designs.
// Same start and end criteria in all of them:
//   start = first cycle after reset; end = the halt instruction (jal x0, 0) reaches WB.
// Prints the stores, the final register file and data memory, and the metrics.
//   iverilog -g2012 -o pipe.out designs/pipeline/*.v tb/perf_tb.v
//   iverilog -g2012 -DDUAL -o dual.out designs/dualissue/*.v tb/perf_tb.v
//   iverilog -g2012 -DDUAL -DOPT -o opt.out designs/dualissue-btb/*.v tb/perf_tb.v
//   vvp pipe.out +prog=tb/programs/dualissue/regroup.mem
// BTB size of the optimized design: -DBTB_IDXW=<n> for 2^n entries (16 by default).
module perf_tb;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  top dut(
    .clk      (clk),
    .reset    (reset),
    .WriteData(WriteData),
    .DataAdr  (DataAdr),
    .MemWrite (MemWrite)
  );

  localparam HALT = 32'h0000006F;  // jal x0, 0

  `define DP dut.rvpipe.dp

`ifdef DUAL
  wire [31:0] InstrW_0 = `DP.InstrW_0;
  wire [31:0] InstrW_1 = `DP.InstrW_1;
  wire        dualE    = (`DP.InstrE_0 != 0) & (`DP.InstrE_1 != 0);
  wire        oneE     = (`DP.InstrE_0 != 0) ^ (`DP.InstrE_1 != 0);
  wire        stallD   = dut.rvpipe.hu.StallD;
  wire        regroupD = dut.rvpipe.hu.RegroupD;
  wire        flushD   = dut.rvpipe.hu.FlushD;
`else
  wire [31:0] InstrW_0 = `DP.InstrW;
  wire [31:0] InstrW_1 = 32'b0;
  wire        dualE    = 1'b0;
  wire        oneE     = (`DP.InstrE != 0);
  wire        stallD   = dut.rvpipe.hu.StallD;
  wire        regroupD = 1'b0;
  wire        flushD   = dut.rvpipe.hu.FlushD;
`endif

  // branch prediction, sampled in Execute
`ifdef OPT
`ifdef BTB_IDXW
  defparam `DP.predictor.IDXW = `BTB_IDXW;
`endif
  wire        ctrlE    = `DP.bu.CtrlE;
  wire        takenE   = `DP.bu.PCSrcE;
  wire        mispE    = `DP.bu.MispredictE;
  wire        hitE     = `DP.predictor.uhit;
  wire        predE    = `DP.bu.PredTakenE;
`else
  // without prediction a taken branch is a misprediction
`ifdef DUAL
  wire        ctrlE    = `DP.bu.BranchE | `DP.bu.JumpE;
`else
  wire        ctrlE    = dut.rvpipe.c.BranchE | dut.rvpipe.c.JumpE;
`endif
  wire        takenE   = dut.rvpipe.PCSrcE;
  wire        mispE    = takenE;
  wire        hitE     = 1'b0;
  wire        predE    = 1'b0;
`endif

  integer cycles, retired, ndual, nsingle, nstall, nregroup, nflush, i;
  integer nbr, ntaken, nmisp, nhit, npredt;
  reg     done;

  initial begin
    cycles = 0; retired = 0; ndual = 0; nsingle = 0;
    nstall = 0; nregroup = 0; nflush = 0; done = 0;
    nbr = 0; ntaken = 0; nmisp = 0; nhit = 0; npredt = 0;
    reset = 1; #22;
    reset = 0;
  end

  initial clk = 1;
  always #5 clk = ~clk;

  // log every store to data memory
  always @(negedge clk) begin
    if (!reset && !done && MemWrite)
      $display("  MEM[%0d] <= %0d", DataAdr, $signed(WriteData));
  end

  // sample at the end of each cycle (just before the rising edge)
  always @(negedge clk) begin
    if (!reset && !done) begin
      cycles = cycles + 1;
      if (InstrW_0 != 0) retired = retired + 1;
      if (InstrW_1 != 0) retired = retired + 1;
      if (dualE)    ndual    = ndual + 1;
      if (oneE)     nsingle  = nsingle + 1;
      if (stallD)   nstall   = nstall + 1;
      if (regroupD) nregroup = nregroup + 1;
      if (flushD)   nflush   = nflush + 1;
      if (ctrlE) begin
        nbr = nbr + 1;
        if (takenE) ntaken = ntaken + 1;
        if (mispE)  nmisp  = nmisp + 1;
        if (hitE)   nhit   = nhit + 1;
        if (predE)  npredt = npredt + 1;
      end
      if (InstrW_0 == HALT || InstrW_1 == HALT) begin
        done = 1;
        #1 report;
        $finish;
      end
    end
  end

  task report;
    begin
      $display("  REGS:");
      for (i = 1; i < 32; i = i + 1)
        if (`DP.rf.rf[i] !== 32'bx) $display("    x%0d = %0d", i, $signed(`DP.rf.rf[i]));
      $display("  DMEM:");
      for (i = 0; i < 256; i = i + 1)
        if (dut.dmem.RAM[i] !== 32'bx) $display("    [%0d] = %0d", 4 * i, $signed(dut.dmem.RAM[i]));
      $display("  cycles=%0d retired=%0d IPC=%0.3f CPI=%0.3f", cycles, retired,
               1.0 * retired / cycles, 1.0 * cycles / retired);
      $display("  dual_issue=%0d single_issue=%0d stalls=%0d regroups=%0d flushes=%0d",
               ndual, nsingle, nstall, nregroup, nflush);
      $display("  branches=%0d taken=%0d mispredicts=%0d accuracy=%0.3f btb_hits=%0d predicted_taken=%0d",
               nbr, ntaken, nmisp, nbr ? 1.0 * (nbr - nmisp) / nbr : 1.0, nhit, npredt);
    end
  endtask

  initial begin
    #2000000 $display("  TIMEOUT: halt never reached WB");
    $finish;
  end

endmodule
