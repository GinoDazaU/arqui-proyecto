module top(// clock / reset
           input         clk, reset,
           // data memory interface (to testbench)
           output [31:0] DataAdr, WriteData,
           output        MemWrite);

  wire [31:0] PC, Instr_0, Instr_1, ReadData;

  // instantiate processor and memories
  riscv rvpipe(
    .clk       (clk),
    .reset     (reset),
    .PCF       (PC),
    .InstrF_0  (Instr_0),
    .InstrF_1  (Instr_1),
    .MemWriteM (MemWrite),
    .ALUResultM(DataAdr),
    .WriteDataM(WriteData),
    .ReadDataM (ReadData)
  );

  imem imem(
    .a  (PC),
    .rd1(Instr_0),
    .rd2(Instr_1)
  );

  dmem dmem(
    .clk(clk),
    .we (MemWrite),
    .a  (DataAdr),
    .wd (WriteData),
    .rd (ReadData)
  );

endmodule
