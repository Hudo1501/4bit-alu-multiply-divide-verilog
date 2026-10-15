`timescale 1ns / 1ps
// ============================================================
// control_unit.v
// Decodes the 4-bit opcode into the control signals used by
// the rest of the ALU.
//
//   opcode | operation | type
//   -------+-----------+---------------------------
//    0000  | ADD       | single cycle
//    0001  | SUB       | single cycle
//    0010  | AND       | single cycle
//    0011  | OR        | single cycle
//    0100  | XOR       | single cycle
//    0101  | NOT A     | single cycle
//    0110  | SHL       | single cycle
//    0111  | SHR       | single cycle
//    1000  | MUL       | multi-cycle (shift-and-add)
//    1001  | DIV       | multi-cycle (shift-and-subtract)
//    1010-1111 | unused -> result 0
// ============================================================
module control_unit (
    input  wire [3:0] opcode,
    output wire       sub,       // 1 for SUB            (0001)
    output wire       arith,     // 1 for ADD or SUB     (000x)
    output wire       is_shl,    // 1 for shift left     (0110)
    output wire       is_shr,    // 1 for shift right    (0111)
    output wire       is_div,    // 1 for divide         (1001)
    output wire       is_muldiv  // 1 for MUL or DIV     (100x)
);
    assign sub       = (opcode == 4'b0001);
    assign arith     = (opcode[3:1] == 3'b000);
    assign is_shl    = (opcode == 4'b0110);
    assign is_shr    = (opcode == 4'b0111);
    assign is_div    = (opcode == 4'b1001);
    assign is_muldiv = (opcode[3:1] == 3'b100);
endmodule
