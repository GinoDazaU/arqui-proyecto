module flopenrc (input  clk, reset, clear, en,
                 input  [WIDTH-1:0] d,
                 output reg [WIDTH-1:0] q);

  parameter WIDTH = 8;

  always @(posedge clk or posedge reset) begin
    if (reset)         q <= 0;
    else if (en) begin
      if (clear)       q <= 0;
      else             q <= d;
    end
  end

endmodule
