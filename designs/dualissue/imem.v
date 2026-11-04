module imem(input  [31:0] a,
            output [31:0] rd1,
            output [31:0] rd2);

  reg [31:0] RAM[63:0];

  reg [1023:0] prog;  // program file, chosen with +prog=<file>

  initial begin
    if (!$value$plusargs("prog=%s", prog)) prog = "./p1_isa.mem";
    $readmemh(prog, RAM);
  end

  assign rd1 = RAM[a[31:2]];  // word aligned
  assign rd2 = RAM[a[31:2]+1];

endmodule
