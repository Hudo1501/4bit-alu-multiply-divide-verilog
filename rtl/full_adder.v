`timescale 1ns / 1ps
// ============================================================
// full_adder.v
// 1-bit full adder built from basic gates.
//   sum  = a XOR b XOR cin
//   cout = (a AND b) OR ((a XOR b) AND cin)
// ============================================================
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire p;    // propagate = a xor b
    wire g;    // generate  = a and b
    wire pc;   // p and cin

    xor x1 (p,    a, b);
    xor x2 (sum,  p, cin);
    and a1 (g,    a, b);
    and a2 (pc,   p, cin);
    or  o1 (cout, g, pc);
endmodule
