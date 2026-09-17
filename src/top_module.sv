module top_module (
    input  [4:0] A,
    input  [4:0] B,
    input  [1:0] bshift,
    input  [2:0] AluControl,
    output [4:0] Result,
    output [3:0] AluFlags
);

    // shift - ALU
    wire [4:0] A_desplazado;

    shift u_shift (
        .A(A),
        .bshift(bshift),
        .A_desplazado(A_desplazado)
    );

    alu u_alu (
        .a(A_desplazado),    
        .b(B),              
        .ALUControl(AluControl),
        .Result(Result),
        .ALUFlags(AluFlags)
    );

endmodule
