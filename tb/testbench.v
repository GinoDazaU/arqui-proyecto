module testbench;
  reg         clk;
  reg         reset;
  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire        MemWrite;

  // instantiate device to be tested
  top dut(
    .clk      (clk),
    .reset    (reset),
    .WriteData(WriteData),
    .DataAdr  (DataAdr),
    .MemWrite (MemWrite)
  );

  // initialize test
  initial begin
    reset = 1; #22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1;
    # 5; clk = 0; # 5;
  end

  // log every store to data memory (results of the program)
  always @(negedge clk) begin
    if (MemWrite)
      $display("t=%0t  MEM[%0d] <= %0d", $time, DataAdr, WriteData);
  end

  initial begin
    #1000 $stop;
  end

endmodule
