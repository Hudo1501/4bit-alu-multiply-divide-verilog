`timescale 1ns / 1ps
// ============================================================
// shifter_4bit.v
// Logical shift by one position (pure wiring, no gates needed).
//   Shift left : every bit moves one place left,  0 enters at bit 0,
//                a[3] falls off  -> shl_out_bit   (a * 2)
//   Shift right: every bit moves one place right, 0 enters at bit 3,
//                a[0] falls off  -> shr_out_bit   (a / 2)
// Example a = 1011 : shl = 0110 (bit out 1), shr = 0101 (bit out 1)
// ============================================================
module shifter_4bit (
    input  wire [3:0] a,
    output wire [3:0] shl,
    output wire [3:0] shr,
    output wire       shl_out_bit,
    output wire       shr_out_bit
);
    assign shl         = {a[2:0], 1'b0};   // join lower 3 bits with a 0
    assign shr         = {1'b0, a[3:1]};   // join a 0 with upper 3 bits
    assign shl_out_bit = a[3];
    assign shr_out_bit = a[0];
endmodule
