module shift (
    input  [4:0] a,
    input  [1:0] shift_amount,
    output [4:0] shifted_a
);

    // Left shift
    assign shifted_a = a << shift_amount;

endmodule