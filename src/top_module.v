module top_module (
    input  [4:0] a,
    input  [4:0] b,
    input  [1:0] shift_amount,
    input  [2:0] alu_control,
    output [4:0] result,
    output [3:0] alu_flags
);

    // Shift to ALU connection
    wire [4:0] shifted_a;

    shift u_shift (
        .a(a),
        .shift_amount(shift_amount),
        .shifted_a(shifted_a)
    );

    alu u_alu (
        .a(shifted_a),    
        .b(b),              
        .alu_control(alu_control),
        .result(result),
        .alu_flags(alu_flags)
    );

endmodule
