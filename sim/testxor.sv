module tb_alu;
    reg [4:0] a;
    reg [4:0] b;
    reg [2:0] ALUControl; // 3 bits para incluir el XOR

    wire [4:0] Result;
    wire [3:0] ALUFlags; // {N, Z, C, V}

    // Instanciar el Unit Under Test (UUT)
    alu uut (
        .a(a), 
        .b(b), 
        .ALUControl(ALUControl), 
        .Result(Result), 
        .ALUFlags(ALUFlags)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);

        $display("--- INICIANDO SIMULACION ALU ---");

        // Caso 1: 3 + 5
        a = 5'd3; b = 5'd5; ALUControl = 3'b000; #10;
        $display("Caso 1 (Suma): 3 + 5 = %d | Flags(NZCV) = %b", Result, ALUFlags);

        // Caso 2: 5 - 5
        a = 5'd5; b = 5'd5; ALUControl = 3'b001; #10;
        $display("Caso 2 (Resta): 5 - 5 = %d | Flags(NZCV) = %b", Result, ALUFlags);

        // Caso 3: 8 AND 1
        a = 5'd8; b = 5'd1; ALUControl = 3'b010; #10;
        $display("Caso 3 (AND): 8 & 1 = %d | Flags(NZCV) = %b", Result, ALUFlags);

        // Caso 4: 5 OR 7
        a = 5'd5; b = 5'd7; ALUControl = 3'b011; #10;
        $display("Caso 4 (OR): 5 | 7 = %d | Flags(NZCV) = %b", Result, ALUFlags);

        // Caso 5 (Pregunta 3): 9 XOR 6
        a = 5'd9; b = 5'd6; ALUControl = 3'b100; #10;
        $display("Caso 5 (XOR): 9 ^ 6 = %d | Flags(NZCV) = %b", Result, ALUFlags);

        $display("--- FIN DE LA SIMULACION ---");
        $finish;
    end

endmodule
