module tb_alu;
    reg [4:0] a;
    reg [4:0] b;
    reg [2:0] alu_control;

    wire [4:0] result;
    wire [3:0] alu_flags; // {N, Z, C, V}

    // Instantiate the Unit Under Test (UUT)
    alu uut (
        .a(a), 
        .b(b), 
        .alu_control(alu_control), 
        .result(result), 
        .alu_flags(alu_flags)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);

        $display("--- STARTING ALU SIMULATION ---");

        // Case 1: 3 + 5
        a = 5'd3; b = 5'd5; alu_control = 3'b000; #10;
        $display("Case 1 (Addition): 3 + 5 = %d | Flags(NZCV) = %b", result, alu_flags);

        // Case 2: 5 - 5
        a = 5'd5; b = 5'd5; alu_control = 3'b001; #10;
        $display("Case 2 (Subtraction): 5 - 5 = %d | Flags(NZCV) = %b", result, alu_flags);

        // Case 3: 8 AND 1
        a = 5'd8; b = 5'd1; alu_control = 3'b010; #10;
        $display("Case 3 (AND): 8 & 1 = %d | Flags(NZCV) = %b", result, alu_flags);

        // Case 4: 5 OR 7
        a = 5'd5; b = 5'd7; alu_control = 3'b011; #10;
        $display("Case 4 (OR): 5 | 7 = %d | Flags(NZCV) = %b", result, alu_flags);

        // Case 5: 9 XOR 6
        a = 5'd9; b = 5'd6; alu_control = 3'b100; #10;
        $display("Case 5 (XOR): 9 ^ 6 = %d | Flags(NZCV) = %b", result, alu_flags);

        $display("--- END OF SIMULATION ---");
        $finish;
    end

endmodule
