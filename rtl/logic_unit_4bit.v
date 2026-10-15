`timescale 1ns / 1ps
// ============================================================
// logic_unit_4bit.v
// Bitwise logic operations, all computed in parallel.
// The result multiplexer picks the one the opcode asks for.
// ============================================================
module logic_unit_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] and_out,   // a & b
    output wire [3:0] or_out,    // a | b
    output wire [3:0] xor_out,   // a ^ b
    output wire [3:0] not_out    // ~a
);
    assign and_out = a & b;
    assign or_out  = a | b;
    assign xor_out = a ^ b;
    assign not_out = ~a;
endmodule
