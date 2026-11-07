module imem(input  [31:0] a,
            output [31:0] rd1,
            output [31:0] rd2);

  reg [31:0] RAM[63:0];

  reg [1023:0] prog;  // program file, chosen with +prog=<file>

  integer i;

  initial begin
    // empty words read as 0 (decoded as a bubble), so the second fetch port
    // never sees x past the end of the program
    for (i = 0; i < 64; i = i + 1) RAM[i] = 32'b0;
    if (!$value$plusargs("prog=%s", prog)) prog = "./isa.mem";
    $readmemh(prog, RAM);
  end

  assign rd1 = RAM[a[31:2]];  // word aligned
  assign rd2 = RAM[a[31:2]+1];

endmodule
