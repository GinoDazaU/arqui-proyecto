module alu (
    input  [4:0] a, b,
    input  [2:0] ALUControl,    // add encoding for xor
    output reg [4:0] Result,
    output wire [3:0] ALUFlags
);

    wire neg, zero, carry, overflow;
    wire [4:0] condinvb;
    wire [5:0] sum; 

    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum = a + condinvb + ALUControl[0];

    // 3 bit ALUControl
    always @(*) begin
        case (ALUControl)
            3'b000: Result = sum[4:0]; // Suma
            3'b001: Result = sum[4:0]; // Resta
            3'b010: Result = a & b;    // AND
            3'b011: Result = a | b;    // OR
            3'b100: Result = a ^ b;    // XOR (Pregunta 3)
            default: Result = 5'b00000;
        endcase
    end

    // carry y overflow solo en suma/resta (cuando ALUControl[2:1] es 00)
    assign neg = Result[4];
    assign zero = (Result == 5'b00000);
    assign carry = (ALUControl[2:1] == 2'b00) & sum[5];
    assign overflow = (ALUControl[2:1] == 2'b00) & 
                      ~(a[4] ^ b[4] ^ ALUControl[0]) & 
                      (a[4] ^ sum[4]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule
