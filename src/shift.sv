module shift (
    input  [4:0] A,
    input  [1:0] bshift,
    output [4:0] A_desplazado
);

    // left displacement
    assign A_desplazado = A << bshift;

endmodule