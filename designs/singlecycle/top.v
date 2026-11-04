module top(// clock / reset
           input         clk, reset,
           // data memory interface (to testbench)
           output [31:0] DataAdr, WriteData,
           output        MemWrite);

  wire [31:0] PC, Instr, ReadData;

  // instantiate processor and memories
  riscvsingle rvsingle(
    .clk      (clk),
    .reset    (reset),
    .PC       (PC),
    .Instr    (Instr),
    .MemWrite (MemWrite),
    .DataAdr  (DataAdr),
    .WriteData(WriteData),
    .ReadData (ReadData)
  );

  imem imem(
    .a (PC),
    .rd(Instr)
  );

  dmem dmem(
    .clk(clk),
    .we (MemWrite),
    .a  (DataAdr),
    .wd (WriteData),
    .rd (ReadData)
  );

endmodule
