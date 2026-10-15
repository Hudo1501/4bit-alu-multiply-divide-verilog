`timescale 1ns / 1ps
// ============================================================
// flag_unit.v
// Status flags.
//   carry    : ADD -> carry out, SUB -> 1 = no borrow,
//              SHL/SHR -> bit shifted out, others -> 0
//   overflow : signed overflow on ADD/SUB (C3 xor C4), others 0
//   zero     : whole 8-bit result is 0
//   negative : result[3] for 4-bit ops (sign bit);
//              0 for MUL/DIV (unsigned)
// ============================================================
module flag_unit (
    input  wire [7:0] result,
    input  wire       arith,
    input  wire       is_shl,
    input  wire       is_shr,
    input  wire       is_muldiv,
    input  wire       c3,
    input  wire       c4,
    input  wire       shl_out_bit,
    input  wire       shr_out_bit,
    output wire       carry,
    output wire       zero,
    output wire       overflow,
    output wire       negative
);
    assign carry    = (arith  & c4)
                    | (is_shl & shl_out_bit)
                    | (is_shr & shr_out_bit);
    assign overflow = arith & (c3 ^ c4);
    assign zero     = ~|result;              // NOR of all 8 bits
    assign negative = ~is_muldiv & result[3];
endmodule
