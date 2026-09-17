module alu (
    input  [4:0] a, b,
    input  [2:0] alu_control,
    output reg [4:0] result,
    output wire [3:0] alu_flags
);

    wire neg, zero, carry, overflow;
    wire [4:0] condinvb;
    wire [5:0] sum; 

    assign condinvb = alu_control[0] ? ~b : b;
    assign sum = a + condinvb + alu_control[0];

    // 3-bit alu_control
    always @(*) begin
        case (alu_control)
            3'b000: result = sum[4:0]; // Addition
            3'b001: result = sum[4:0]; // Subtraction
            3'b010: result = a & b;    // AND
            3'b011: result = a | b;    // OR
            3'b100: result = a ^ b;    // XOR
            default: result = 5'b00000;
        endcase
    end

    // Carry and overflow only in addition/subtraction (when alu_control[2:1] is 00)
    assign neg = result[4];
    assign zero = (result == 5'b00000);
    assign carry = (alu_control[2:1] == 2'b00) & sum[5];
    assign overflow = (alu_control[2:1] == 2'b00) & 
                      ~(a[4] ^ b[4] ^ alu_control[0]) & 
                      (a[4] ^ sum[4]);

    assign alu_flags = {neg, zero, carry, overflow};

endmodule
