`timescale 1ns / 1ps
// ============================================================
// result_mux.v
// Chooses which unit's output becomes the ALU result.
// The result is 8 bits wide so it can hold a full product.
//   single-cycle ops : result = {0000, 4-bit answer}
//   MUL              : result = {product high, product low}
//   DIV              : result = {remainder, quotient}
// ============================================================
module result_mux (
    input  wire [3:0] opcode,
    input  wire [3:0] sum,
    input  wire [3:0] and_out, or_out, xor_out, not_out,
    input  wire [3:0] shl, shr,
    input  wire [3:0] md_hi, md_lo,
    output reg  [7:0] result
);
    always @(*) begin
        case (opcode)
            4'b0000, 4'b0001: result = {4'b0000, sum};
            4'b0010:          result = {4'b0000, and_out};
            4'b0011:          result = {4'b0000, or_out};
            4'b0100:          result = {4'b0000, xor_out};
            4'b0101:          result = {4'b0000, not_out};
            4'b0110:          result = {4'b0000, shl};
            4'b0111:          result = {4'b0000, shr};
            4'b1000, 4'b1001: result = {md_hi, md_lo};
            default:          result = 8'b0000_0000;
        endcase
    end
endmodule
