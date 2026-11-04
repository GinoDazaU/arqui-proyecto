module regfile(input         clk,
               // read ports
               input  [4:0]  a1, a2,
               output [31:0] rd1, rd2,
               // write port
               input         we3,
               input  [4:0]  a3,
               input  [31:0] wd3);

  reg [31:0] rf[31:0];

  // write port (A3/WD3/WE3) on falling edge of clock:
  // the value written by WB is visible to the instruction in Decode
  always @(negedge clk) begin
    if (we3) rf[a3] <= wd3;
  end

  // read two ports combinationally (A1/RD1, A2/RD2)
  // register 0 hardwired to 0
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;

endmodule
