module mux5(input  [WIDTH-1:0] d0, d1, d2, d3, d4,
            input  [2:0]       s,
            output [WIDTH-1:0] y);

  parameter WIDTH = 8;

  assign y = (s == 3'd4) ? d4 :
             (s == 3'd3) ? d3 :
             (s == 3'd2) ? d2 :
             (s == 3'd1) ? d1 : d0;

endmodule
