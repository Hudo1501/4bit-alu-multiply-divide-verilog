`timescale 1ns / 1ps
// ============================================================
// muldiv_unit.v
// Sequential multiplier and divider built from SHIFTING plus
// ONE 4-bit adder/subtractor. The adder is not inside this
// module: it is the ALU's own adder, borrowed while busy = 1.
// So MUL and DIV add only registers and a few muxes to the ALU.
//
// Registers
//   acc : MUL -> upper half of product   | DIV -> remainder
//   q   : MUL -> multiplier, becomes the lower half of product
//         DIV -> dividend, becomes the quotient
//   m   : MUL -> multiplicand            | DIV -> divisor
//
// MULTIPLY (shift-and-add), 4 steps, one per clock:
//   if q[0] == 1 : acc = acc + m      (add multiplicand)
//   shift {carry, acc, q} right by 1
//   after 4 steps: product = {acc, q}
//
// DIVIDE (restoring, shift-and-subtract), 4 steps:
//   shift {acc, q} left by 1          (bring down next dividend bit)
//   try acc - m
//   if it fits (no borrow): acc = acc - m, q[0] = 1
//   else                   : keep acc,      q[0] = 0
//   after 4 steps: quotient = q, remainder = acc
//
// Protocol: put a, b on the inputs, pulse start for one clock.
// busy goes high for 4 clocks, then done goes high and the
// result is held until the next start.
// Divide by zero: div_by_zero = 1, quotient = 1111, remainder = a.
// ============================================================
module muldiv_unit (
    input  wire       clk,
    input  wire       rst,        // active-high asynchronous reset
    input  wire       start,      // pulse for one clock to begin
    input  wire       is_div,     // 0 = multiply, 1 = divide
    input  wire [3:0] a,
    input  wire [3:0] b,

    // connection to the shared adder/subtractor
    output wire [3:0] add_a,
    output wire [3:0] add_b,
    output wire       add_sub,
    input  wire [3:0] add_sum,
    input  wire       add_c4,     // carry out (for SUB: 1 = no borrow)

    output wire [3:0] hi,         // MUL: product[7:4]  DIV: remainder
    output wire [3:0] lo,         // MUL: product[3:0]  DIV: quotient
    output wire       busy,
    output reg        done,
    output reg        div_by_zero
);
    reg [3:0] acc, q, m;
    reg [1:0] count;              // counts the 4 steps (0..3)
    reg       running;
    reg       mode_div;           // operation latched at start

    // divide: {acc, q} shifted left by one
    wire [3:0] r_shift = {acc[2:0], q[3]};
    wire       r_top   = acc[3];              // bit shifted out of acc
    wire       fits    = r_top | add_c4;      // remainder >= divisor ?

    // drive the shared adder
    assign add_a   = mode_div ? r_shift : acc;
    assign add_b   = m;
    assign add_sub = mode_div;                // subtract when dividing

    assign busy = running;
    assign hi   = acc;
    assign lo   = q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc <= 4'd0;  q <= 4'd0;  m <= 4'd0;
            count <= 2'd0;  running <= 1'b0;  mode_div <= 1'b0;
            done <= 1'b0;  div_by_zero <= 1'b0;
        end
        else if (start && !running) begin
            // load
            running     <= 1'b1;
            done        <= 1'b0;
            mode_div    <= is_div;
            count       <= 2'd0;
            acc         <= 4'd0;
            q           <= is_div ? a : b;    // dividend  / multiplier
            m           <= is_div ? b : a;    // divisor   / multiplicand
            div_by_zero <= is_div && (b == 4'd0);
        end
        else if (running) begin
            if (!mode_div) begin
                // ---- one multiply step: add (if q[0]) then shift right
                if (q[0])
                    {acc, q} <= {add_c4, add_sum, q[3:1]};
                else
                    {acc, q} <= {1'b0,   acc,     q[3:1]};
            end
            else begin
                // ---- one divide step: shift left, subtract if it fits
                if (fits) begin
                    acc <= add_sum;           // r_shift - m
                    q   <= {q[2:0], 1'b1};
                end
                else begin
                    acc <= r_shift;           // restore (keep)
                    q   <= {q[2:0], 1'b0};
                end
            end

            count <= count + 2'd1;
            if (count == 2'd3) begin
                running <= 1'b0;
                done    <= 1'b1;
            end
        end
    end
endmodule
