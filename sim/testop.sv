module tb_top;
    reg [4:0] A;
    reg [4:0] B;
    reg [1:0] bshift;
    reg [2:0] AluControl;

    wire [4:0] Result;
    wire [3:0] AluFlags;

    top_module uut (
        .A(A),
        .B(B),
        .bshift(bshift),
        .AluControl(AluControl),
        .Result(Result),
        .AluFlags(AluFlags)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        $display("--- INICIANDO SIMULACION TOP MODULE (SHIFT + ALU) ---");

        // Configuracion inicial: B = 0, ALU configurada para sumar
        B = 5'd0; 
        AluControl = 3'b000; // Suma

        // Prueba 1: Sin shift (Desplazamiento = 0)
        A = 5'b00011; // 3
        bshift = 2'd0; #10;
        $display("A=3, bshift=0 -> Result = %d", Result);

        // Prueba 2: Shift de 1 bit a la izquierda (Equivale a multiplicar x2)
        A = 5'b00011; 
        bshift = 2'd1; #10;
        $display("A=3, bshift=1 -> Result = %d (Deberia ser 6)", Result);

        // Prueba 3: Shift de 2 bits a la izquierda (Equivale a multiplicar x4)
        A = 5'b00011; 
        bshift = 2'd2; #10;
        $display("A=3, bshift=2 -> Result = %d (Deberia ser 12)", Result);

        $display("--- FIN DE LA SIMULACION ---");
        $finish;
    end

endmodule
