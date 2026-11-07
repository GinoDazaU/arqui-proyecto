module imem(input  [31:0] a,
            output [31:0] rd);

  reg [31:0] RAM[63:0];

  reg [1023:0] prog;  // program file, chosen with +prog=<file>

  integer i;

  initial begin
    // empty words read as 0 (decoded as a bubble), never x
    for (i = 0; i < 64; i = i + 1) RAM[i] = 32'b0;
    if (!$value$plusargs("prog=%s", prog)) prog = "./isa.mem";
    $readmemh(prog, RAM);
  end

  assign rd = RAM[a[31:2]];  // word aligned

endmodule
