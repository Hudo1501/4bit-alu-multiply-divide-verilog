`timescale 1ns / 1ps
// ============================================================
// adder_subtractor_4bit.v
// 4-bit ripple-carry adder / subtractor.
//   sub = 0 : sum = a + b
//   sub = 1 : sum = a - b   (computed as a + ~b + 1, two's complement)
// Each bit of b is XORed with 'sub' (inverts b when subtracting),
// and 'sub' is also the carry-in to bit 0 (the "+1").
// Outputs c3 (carry into MSB) and c4 (carry out) for the flag unit.
// ============================================================
module adder_subtractor_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       sub,
    output wire [3:0] sum,
    output wire       c3,     // carry into bit 3
    output wire       c4      // carry out of bit 3
);
    wire [3:0] b_x;           // b after optional inversion
    wire [4:0] c;             // internal carry chain

    assign c[0] = sub;

    // invert b when subtracting
    xor xb0 (b_x[0], b[0], sub);
    xor xb1 (b_x[1], b[1], sub);
    xor xb2 (b_x[2], b[2], sub);
    xor xb3 (b_x[3], b[3], sub);

    // ripple chain of four full adders
    full_adder fa0 (.a(a[0]), .b(b_x[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder fa1 (.a(a[1]), .b(b_x[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder fa2 (.a(a[2]), .b(b_x[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder fa3 (.a(a[3]), .b(b_x[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));

    assign c3 = c[3];
    assign c4 = c[4];
endmodule
