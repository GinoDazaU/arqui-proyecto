module alu (
    input [4:0] a, b,           // inputs 5 bits
    input [1:0] ALUControl,     // control 2 bits
    output reg [4:0] Result,    // 5 bits result
    output wire [3:0] ALUFlags  // flags {N, Z, C, V}
);

    wire neg, zero, carry, overflow;
    wire [4:0] condinvb;
    wire [5:0] sum; // 6 bits carry out

    // sum
    assign condinvb = ALUControl[0] ? ~b : b; 
    assign sum = a + condinvb + ALUControl[0];

    // multiplexer
    always @(*) begin
        case (ALUControl)
            2'b00: Result = sum[4:0]; // Suma
            2'b01: Result = sum[4:0]; // Resta
            2'b10: Result = a & b;    // AND
            2'b11: Result = a | b;    // OR
            default: Result = 5'b00000;
        endcase
    end

    // flags assigns
    assign neg = Result[4]; 
    assign zero = (Result == 5'b00000); 
    assign carry = (ALUControl[1] == 1'b0) & sum[5]; 
    assign overflow = (ALUControl[1] == 1'b0) & 
                      ~(a[4] ^ b[4] ^ ALUControl[0]) & // detector de signo
                      (a[4] ^ sum[4]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule
