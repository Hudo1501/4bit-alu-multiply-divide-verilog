`timescale 1ns / 1ps
// ============================================================
// alu_4bit_tb.v  --  Self-checking testbench for alu_4bit
//
// Student : Truong Dong Hung        Roll No : SE201121
//
// IDEA: drive the ALU inputs, compute the correct answer inside
// the testbench, compare it with the ALU outputs. Mismatches are
// printed; the LAST line printed is "PASS: ..." or "FAIL: ...".
//
// PART 1 - Examples
//   One readable example for every operation (incl. MUL, DIV and
//   divide by zero). Each example is held for one clock so it is
//   easy to read in the waveform. The results are also checked.
//
// PART 2 - Self-checking tests
//   2.1 Reset
//   2.2 The 14 single-cycle opcodes (ADD..SHR + 6 unused opcodes),
//       each one with all 256 (a,b) pairs      -> 14 x 256 = 3584 cases
//   2.3 MUL and DIV, each one with all 256 (a,b) pairs
//                                              ->  2 x 256 =  512 cases
//       (also checks: latency in clocks, and that changing a/b after
//        'start' does not change the result)
//   2.4 Protocol scenarios: start while busy, start with a wrong
//       opcode, opcode changed while running, done/result held,
//       divide by zero, reset in the middle
//
// Exhaustive: 16 opcodes x 256 (a,b) pairs = 4096 cases, nothing skipped.
//
// HOW TO RUN IN VIVADO: Run Behavioral Simulation, then type
//   run all
// in the Tcl Console (the default run time of 1000 ns is too short).
// ============================================================

// ---- Student information (printed at the start and before the PASS line) ----
`define STUDENT_NAME "Truong Dong Hung"
`define STUDENT_ID   "SE201121"

module alu_4bit_tb;

  // ---------- 1. Signals and DUT ----------
  reg        clk = 0, rst = 1, start = 0;
  reg  [3:0] a = 0, b = 0, opcode = 0;
  wire [7:0] result;
  wire       carry, zero, overflow, negative, div_by_zero, busy, done;

  alu_4bit dut (
    .clk(clk), .rst(rst), .start(start),
    .a(a), .b(b), .opcode(opcode),
    .result(result), .carry(carry), .zero(zero),
    .overflow(overflow), .negative(negative),
    .div_by_zero(div_by_zero), .busy(busy), .done(done)
  );

  always #5 clk = ~clk;                  // 10 ns clock period

  localparam OP_ADD = 4'b0000, OP_SUB = 4'b0001, OP_AND = 4'b0010,
             OP_OR  = 4'b0011, OP_XOR = 4'b0100, OP_NOT = 4'b0101,
             OP_SHL = 4'b0110, OP_SHR = 4'b0111,
             OP_MUL = 4'b1000, OP_DIV = 4'b1001;

  // ---------- 2. Counters and compare helpers ----------
  integer errors = 0;          // total number of errors
  integer checks = 0;          // total number of comparisons
  integer n_comb = 0;          // single-cycle cases executed (must be 3584)
  integer n_md   = 0;          // MUL/DIV cases executed      (must be  512)
  integer sec_errors, sec_checks;

  task expect_bit;                       // compare 1 bit
    input actual, expected;
    input [8*24-1:0] what;
    begin
      checks = checks + 1;
      if (actual !== expected) begin
        errors = errors + 1;
        if (errors <= 10)
          $display("ERROR t=%0t: %0s = %b, expected %b", $time, what, actual, expected);
      end
    end
  endtask

  task expect_byte;                      // compare 8 bits
    input [7:0] actual, expected;
    input [8*24-1:0] what;
    begin
      checks = checks + 1;
      if (actual !== expected) begin
        errors = errors + 1;
        if (errors <= 10)
          $display("ERROR t=%0t: %0s = %b (%0d), expected %b (%0d)  [op=%b a=%0d b=%0d]",
                   $time, what, actual, actual, expected, expected, opcode, a, b);
      end
    end
  endtask

  task section_begin;
    begin sec_errors = errors; sec_checks = checks; end
  endtask

  task section_end;
    input [8*44-1:0] name;
    begin
      if (errors == sec_errors) $display("  [PASS] %0s  (%0d comparisons)", name, checks - sec_checks);
      else                      $display("  [FAIL] %0s  (%0d errors)", name, errors - sec_errors);
    end
  endtask

  // ---------- 3. Expected answer for single-cycle opcodes ----------
  reg [7:0] exp_res;
  reg       exp_c, exp_v, exp_z, exp_n;

  task calc_expected;
    input [3:0] op, x, y;
    integer sx, sy, s;
    reg [3:0] r;
    begin
      sx = x[3] ? x - 16 : x;            // signed value, -8..7
      sy = y[3] ? y - 16 : y;
      r = 0; exp_c = 0; exp_v = 0;
      case (op)
        OP_ADD: begin
          r = x + y;
          exp_c = (x + y > 15);          // carry: sum does not fit in 4 bits
          s = sx + sy;
          exp_v = (s > 7) || (s < -8);   // overflow: signed sum outside -8..7
        end
        OP_SUB: begin
          r = x - y;
          exp_c = (x >= y);              // carry = 1 means "no borrow"
          s = sx - sy;
          exp_v = (s > 7) || (s < -8);
        end
        OP_AND: r = x & y;
        OP_OR : r = x | y;
        OP_XOR: r = x ^ y;
        OP_NOT: r = ~x;
        OP_SHL: begin r = x << 1; exp_c = x[3]; end   // carry = bit shifted out
        OP_SHR: begin r = x >> 1; exp_c = x[0]; end
        default: r = 0;                  // unused opcode -> result 0
      endcase
      exp_res = {4'b0000, r};
      exp_z   = (r == 0);
      exp_n   = r[3];
    end
  endtask

  // Compare every ALU output with the expected answer (inputs already applied)
  task compare_comb;
    input [3:0] op, x, y;
    begin
      calc_expected(op, x, y);
      expect_byte(result,   exp_res, "result");
      expect_bit (carry,    exp_c,   "carry");
      expect_bit (overflow, exp_v,   "overflow");
      expect_bit (zero,     exp_z,   "zero");
      expect_bit (negative, exp_n,   "negative");
      expect_bit (div_by_zero, 1'b0, "div_by_zero (must be 0)");
      expect_bit (busy,        1'b0, "busy (must be 0)");
    end
  endtask

  // Apply (op,a,b) to the ALU, then compare every output
  task check_comb;
    input [3:0] op, x, y;
    begin
      opcode = op; a = x; b = y; start = 0;
      #1;                                // let the combinational logic settle
      compare_comb(op, x, y);
    end
  endtask

  // ---------- 4. Expected answer for MUL / DIV ----------
  task calc_md;
    input [3:0] op, x, y;
    begin
      if (op == OP_MUL)  exp_res = x * y;
      else if (y == 0)   exp_res = {x, 4'hF};          // divide by 0: quotient=1111, remainder=a
      else begin exp_res[7:4] = x % y; exp_res[3:0] = x / y; end   // {remainder, quotient}
    end
  endtask

  // Check the MUL/DIV result (call when done = 1)
  task check_md;
    input [3:0] op, x, y;
    begin
      calc_md(op, x, y);
      expect_bit (done,     1'b1,    "done");
      expect_bit (busy,     1'b0,    "busy");
      expect_byte(result,   exp_res, "result MUL/DIV");
      expect_bit (carry,    1'b0,    "carry");
      expect_bit (overflow, 1'b0,    "overflow");
      expect_bit (negative, 1'b0,    "negative");
      expect_bit (zero,     (exp_res == 0), "zero");
      expect_bit (div_by_zero, (op == OP_DIV) && (y == 0), "div_by_zero");
    end
  endtask

  // Wait for done, at most 10 clocks (bounded so the simulation can never hang)
  integer cycles;
  task wait_done;
    begin
      while (done !== 1'b1 && cycles < 10) begin
        @(negedge clk); cycles = cycles + 1;
      end
    end
  endtask

  // Run one MUL/DIV: 1-clock start pulse, wait for done, check
  task run_muldiv;
    input [3:0] op, x, y;
    begin
      @(negedge clk); opcode = op; a = x; b = y; start = 1;   // clock 0: start
      #1 expect_bit(busy, 1'b0, "busy not yet high");         // busy may only rise AFTER the clock edge
      @(negedge clk); start = 0; a = ~x; b = ~y;   // change a,b: result must NOT change
      cycles = 1;
      wait_done;
      expect_byte(cycles, 5, "clocks start->done");   // 1 load + 4 steps = 5
      check_md(op, x, y);
    end
  endtask

  // ---------- 4b. Part 1 helpers: print one example ----------
  // A single-cycle example is held for one full clock (10 ns) so it is
  // easy to see in the waveform. The result is compared as well.
  task show_comb;
    input [3:0] op, x, y;
    input [8*4-1:0] name;
    begin
      @(negedge clk); opcode = op; a = x; b = y; start = 0;
      #1 compare_comb(op, x, y);
      #1 $display("  %s %b | %2d %2d | %b (%3d) | C=%b Z=%b V=%b N=%b",
                  name, op, x, y, result, result, carry, zero, overflow, negative);
    end
  endtask

  task show_md;
    input [3:0] op, x, y;
    input [8*4-1:0] name;
    begin
      run_muldiv(op, x, y);              // runs AND checks the operation
      if (op == OP_MUL)
        $display("  %s %b | %2d %2d | %b (%3d) | product = %0d, %0d clocks",
                 name, op, x, y, result, result, result, cycles);
      else
        $display("  %s %b | %2d %2d | %b       | quotient = %0d, remainder = %0d, dbz=%b, %0d clocks",
                 name, op, x, y, result, result[3:0], result[7:4], div_by_zero, cycles);
    end
  endtask

  task part1_examples;
    begin
      $display("  Op   code |  A  B | result         | flags / notes");
      $display("  ----------+-------+----------------+------------------------------");
      show_comb(OP_ADD,  5,  3, "ADD ");
      show_comb(OP_ADD, 15,  1, "ADD ");
      show_comb(OP_SUB,  5,  3, "SUB ");
      show_comb(OP_SUB,  3,  5, "SUB ");
      show_comb(OP_AND, 12, 10, "AND ");
      show_comb(OP_OR,  12, 10, "OR  ");
      show_comb(OP_XOR, 12, 10, "XOR ");
      show_comb(OP_NOT, 12,  0, "NOT ");
      show_comb(OP_SHL, 11,  0, "SHL ");
      show_comb(OP_SHR, 11,  0, "SHR ");
      show_md  (OP_MUL, 13, 11, "MUL ");
      show_md  (OP_MUL, 15, 15, "MUL ");
      show_md  (OP_DIV, 13,  4, "DIV ");
      show_md  (OP_DIV, 15,  3, "DIV ");
      show_md  (OP_DIV,  9,  0, "DIV ");
    end
  endtask

  // ---------- 5. Test groups ----------
  integer i, op_i;

  task test_reset;
    begin
      rst = 1; repeat (2) @(negedge clk); rst = 0; #1;
      expect_bit(busy, 0, "busy after reset");
      expect_bit(done, 0, "done after reset");
      expect_bit(div_by_zero, 0, "div_by_zero after reset");
    end
  endtask

  task test_single_cycle;                // 14 opcodes x 256 (a,b) pairs
    begin
      for (op_i = 0; op_i < 16; op_i = op_i + 1)
        if (op_i != 8 && op_i != 9)      // 8,9 are MUL/DIV, tested separately
          for (i = 0; i < 256; i = i + 1) begin
            check_comb(op_i, i[7:4], i[3:0]);
            n_comb = n_comb + 1;
          end
    end
  endtask

  task test_muldiv;                      // MUL and DIV, 256 (a,b) pairs each
    begin
      for (i = 0; i < 256; i = i + 1) begin
        run_muldiv(OP_MUL, i[7:4], i[3:0]);
        run_muldiv(OP_DIV, i[7:4], i[3:0]);   // includes divide by zero
        n_md = n_md + 2;
      end
    end
  endtask

  task test_start_while_busy;            // a 2nd start while running must be ignored
    begin
      @(negedge clk); opcode = OP_MUL; a = 13; b = 3; start = 1;   // real start: 13*3
      @(negedge clk); a = 15; b = 15; start = 1;                   // fake start while busy
      @(negedge clk); start = 0;
      cycles = 3; wait_done;
      check_md(OP_MUL, 13, 3);           // must be 39, not 15*15 = 225
    end
  endtask

  task test_start_wrong_opcode;          // start with an opcode that is not MUL/DIV
    begin
      for (op_i = 0; op_i < 16; op_i = op_i + 1)
        if (op_i != 8 && op_i != 9) begin
          @(negedge clk); opcode = op_i; a = 9; b = 7; start = 1;
          #1 expect_bit(busy, 0, "busy right after start");
          @(negedge clk); start = 0;
          expect_bit(busy, 0, "busy after 1 clock");
          repeat (4) begin @(negedge clk); expect_bit(busy, 0, "busy"); end
        end
    end
  endtask

  task test_opcode_change;               // change the opcode while the operation runs
    begin
      @(negedge clk); opcode = OP_MUL; a = 13; b = 11; start = 1;  // clock 0
      @(negedge clk); start = 0; opcode = OP_DIV;                  // clock 1
      @(negedge clk); opcode = OP_ADD;                             // clock 2
      @(negedge clk); opcode = OP_SUB;                             // clock 3
      @(negedge clk); opcode = OP_MUL;                             // clock 4: back to MUL
      @(negedge clk);                                              // clock 5: done
      check_md(OP_MUL, 13, 11);          // must still be 143
    end
  endtask

  task test_done_hold;                   // done and result stay until the next start
    input [3:0] op, x, y;
    begin
      run_muldiv(op, x, y);
      calc_md(op, x, y);
      repeat (10) begin
        @(negedge clk);
        expect_bit (done, 1, "done held");
        expect_byte(result, exp_res, "result held");
      end
      @(negedge clk); start = 1; a = 2; b = 2;                     // new start
      @(negedge clk); start = 0;
      expect_bit(done, 0, "done cleared on start");
      expect_bit(busy, 1, "busy on new start");
      cycles = 1; wait_done;
    end
  endtask

  task test_divide_by_zero;              // div_by_zero only matters for the DIV opcode
    begin
      run_muldiv(OP_DIV, 9, 0);          // latch div_by_zero = 1
      @(negedge clk); opcode = OP_ADD;  #1 expect_bit(div_by_zero, 0, "dbz with ADD");
      @(negedge clk); opcode = OP_DIV;  #1 expect_bit(div_by_zero, 1, "dbz with DIV");
      run_muldiv(OP_MUL, 3, 3);          // a new operation clears the flag
      @(negedge clk); opcode = OP_DIV;  #1 expect_bit(div_by_zero, 0, "dbz after MUL");
    end
  endtask

  task test_reset_midway;                // reset while running / after finishing
    begin
      @(negedge clk); opcode = OP_MUL; a = 9; b = 9; start = 1;    // clock 0
      @(negedge clk); start = 0;                                   // clock 1
      @(negedge clk);                                              // clock 2
      expect_bit(busy, 1, "busy before reset");
      rst = 1; #1;                       // asynchronous reset: takes effect immediately
      expect_bit(busy, 0, "busy after reset");
      expect_bit(done, 0, "done after reset");
      #1 rst = 0;
      run_muldiv(OP_MUL, 15, 15);        // works normally after reset

      run_muldiv(OP_DIV, 9, 0);          // done = 1, div_by_zero = 1
      rst = 1; #1;
      expect_bit(done, 0, "done after late reset");
      expect_bit(div_by_zero, 0, "dbz after reset");
      #1 rst = 0;
      run_muldiv(OP_DIV, 15, 4);
    end
  endtask

  // ---------- 6. Main program ----------
  initial begin
    $display("");
    $display("============================================================");
    $display("  4-bit ALU testbench");
    $display("  Student : %0s        Roll No : %0s", `STUDENT_NAME, `STUDENT_ID);
    $display("============================================================");

    // power-on reset (2 clocks), then release
    rst = 1; repeat (2) @(negedge clk); rst = 0;

    // ---------------- PART 1 ----------------
    $display("\nPART 1 - Examples (one per operation)");
    part1_examples;

    // ---------------- PART 2 ----------------
    $display("\nPART 2 - Self-checking tests");

    section_begin;  test_reset;
    section_end("2.1 Reset");

    run_muldiv(OP_DIV, 9, 0);            // latch div_by_zero=1 to check it does not leak
    section_begin;  test_single_cycle;
    section_end("2.2 14 single-cycle opcodes x 256 cases");

    section_begin;  test_muldiv;
    section_end("2.3 MUL/DIV x 256 cases each");

    section_begin;
    test_start_while_busy;
    test_start_wrong_opcode;
    test_opcode_change;
    test_done_hold(OP_MUL, 12, 12);
    test_done_hold(OP_DIV, 13, 4);
    test_divide_by_zero;
    test_reset_midway;
    section_end("2.4 Protocol scenarios");

    // make sure every case was really executed
    if (n_comb != 3584 || n_md != 512) begin
      errors = errors + 1;
      $display("ERROR: not all cases executed (%0d/3584, %0d/512)", n_comb, n_md);
    end

    // ---------------- summary: the LAST line is PASS or FAIL ----------------
    $display("\n------------------------------------------------------------");
    $display("  Executed    : %0d single-cycle + %0d MUL/DIV = %0d / 4096 input combinations",
             n_comb, n_md, n_comb + n_md);
    $display("  Comparisons : %0d      Errors : %0d", checks, errors);
    $display("  Student     : %0s        Roll No : %0s", `STUDENT_NAME, `STUDENT_ID);
    if (errors == 0)
      $display("PASS: all 4096 input combinations verified, 0 errors");
    else
      $display("FAIL: %0d errors found", errors);
    $finish;
  end

endmodule