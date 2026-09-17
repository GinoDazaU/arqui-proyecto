module tb_top;
    reg [4:0] a;
    reg [4:0] b;
    reg [1:0] shift_amount;
    reg [2:0] alu_control;

    wire [4:0] result;
    wire [3:0] alu_flags;

    top_module uut (
        .a(a),
        .b(b),
        .shift_amount(shift_amount),
        .alu_control(alu_control),
        .result(result),
        .alu_flags(alu_flags)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        $display("--- STARTING TOP MODULE SIMULATION (SHIFT + ALU) ---");

        // Initial configuration: b = 0, ALU configured for addition
        b = 5'd0; 
        alu_control = 3'b000; // Addition

        // Test 1: No shift (shift_amount = 0)
        a = 5'b00011; // 3
        shift_amount = 2'd0; #10;
        $display("a=3, shift_amount=0 -> result = %d", result);

        // Test 2: Left shift by 1 bit (Equivalent to multiplying by 2)
        a = 5'b00011; 
        shift_amount = 2'd1; #10;
        $display("a=3, shift_amount=1 -> result = %d (Should be 6)", result);

        // Test 3: Left shift by 2 bits (Equivalent to multiplying by 4)
        a = 5'b00011; 
        shift_amount = 2'd2; #10;
        $display("a=3, shift_amount=2 -> result = %d (Should be 12)", result);

        $display("--- END OF SIMULATION ---");
        $finish;
    end

endmodule
