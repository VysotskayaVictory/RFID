// File simon.vhd translated with vhd2vl v2.5 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 1995

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002, 2005, 2008-2010, 2015 Larry Doolittle - LBNL
//     http://doolittle.icarus.com/~larry/vhd2vl/
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// Simon.vhd
// Copyright 2016 Michael Calvin McCoy
// calvin.mccoy@gmail.com
// see LICENSE.md
// no timescale needed


module SIMON_CIPHER(
    clk,
    rst,
    done,
    control,
    key,
    block_input,
    block_output
);

parameter [31:0] KEY_SIZE=256;
parameter [31:0] BLOCK_SIZE=64;
parameter [31:0] ROUND_LIMIT=48;

// -------------------------------------------------------------
// -- Cipher Constants
parameter WORD_SIZE = BLOCK_SIZE / 2;
parameter K_SEGMENTS = KEY_SIZE /  WORD_SIZE;

parameter [WORD_SIZE - 6:0] ROUND_CONSTANT_HI = {(WORD_SIZE - 5){1'b1}}; 
parameter [3:0] ROUND_CONSTANT_LO = 4'hC;
// -------------------------------------------------------------

integer i;

input clk, rst;
input [1:0] control;
input [KEY_SIZE - 1:0] key;
input [BLOCK_SIZE - 1:0] block_input;
output reg [BLOCK_SIZE - 1:0] block_output;
output wire done;

reg busy;

assign done = !busy;

wire [61:0] ZJ = 62'b11110111001001010011000011101000000100011011010110011110001011;

reg [61:0] z_shift;

// -- Key Schedule Storage Array
reg [WORD_SIZE - 1 : 0] key_schedule [0:ROUND_LIMIT-1]; 
reg [WORD_SIZE - 1 : 0] round_key;

wire [WORD_SIZE - 1 : 0] round_constant;

reg [WORD_SIZE - 1:0] key_gen[0:K_SEGMENTS - 1]; 
reg cipher_direction; 

//----------------------------------------------------
// Fiestel Structure Signals
reg [WORD_SIZE - 1:0] b_buf;
reg [WORD_SIZE - 1:0] a_buf;
wire [WORD_SIZE - 1:0] b_lft1;
wire [WORD_SIZE - 1:0] b_lft8;
wire [WORD_SIZE - 1:0] b_lft2;
wire [WORD_SIZE - 1:0] b_and;
wire [WORD_SIZE - 1:0] b_xor;
wire [WORD_SIZE - 1:0] a_xor;
wire [WORD_SIZE - 1:0] key_xor;

//------------------------------------------------------
// key Generation Signals
wire [WORD_SIZE - 1:0] key_temp_1;
wire [WORD_SIZE - 1:0] key_temp_2;
wire [WORD_SIZE - 1:0] rs3;
wire [WORD_SIZE - 1:0] rs1;
wire [WORD_SIZE - 1:0] zji;
parameter [3:0]
  Reset = 0,
  Idle = 1,
  Key_Schedule_Generation_Run = 2,
  Key_Schedule_Generation_Finish = 3,
  Cipher_Start = 4,
  Cipher_Run = 5,
  Cipher_Finish_1 = 6,
  Cipher_Finish_2 = 7,
  Cipher_Latch = 8;

reg [3:0] pr_state; reg [3:0] nx_state;
reg [31:0] round_count;
reg [31:0] inv_round_count;
wire [31:0] round_count_mux;
wire [WORD_SIZE - 1:0] key_feedback;

  //--------------------------------------------------------------------
  // State Machine Processes
  //--------------------------------------------------------------------
  always @(posedge clk) begin
  //--State Machine Master control

    if((rst == 1'b 1)) begin
      pr_state <= Reset;
      for (i=0;i<ROUND_LIMIT;i=i+1) begin
        key_schedule[i] <= 0;
      end
    end
    else begin
      pr_state <= nx_state;
    end
  end

  // State_Machine_Head
  always @(control or round_count or pr_state) begin
  //-State Machine State Definitions

    case (pr_state)
        Reset : begin
          //Master Reset State
          nx_state <= Idle;
        end
        Idle : begin
          if((control == 2'b01)) begin
            nx_state <= Key_Schedule_Generation_Run;
          end
          else if((control == 2'b11 || control == 2'b10)) begin
            nx_state <= Cipher_Start;
          end
          else begin
            nx_state <= Idle;
          end
        end
        Key_Schedule_Generation_Run : begin
          if((round_count == (ROUND_LIMIT - 2))) begin
            nx_state <= Key_Schedule_Generation_Finish;
          end
          else begin
            nx_state <= Key_Schedule_Generation_Run;
          end
        end
        Key_Schedule_Generation_Finish : begin
          nx_state <= Idle;
        end
        Cipher_Start : begin
          nx_state <= Cipher_Run;
        end
        Cipher_Run : begin
          if((round_count == (ROUND_LIMIT - 2))) begin
            nx_state <= Cipher_Finish_1;
          end
          else begin
            nx_state <= Cipher_Run;
          end
        end
        Cipher_Finish_1 : begin
          nx_state <= Cipher_Finish_2;
        end
        Cipher_Finish_2 : begin
          nx_state <= Cipher_Latch;
        end
        Cipher_Latch : begin
          nx_state <= Idle;
        end
    endcase
  end

  //--------------------------------------------------------------------
  // END State Machine Processes
  //--------------------------------------------------------------------
  //--------------------------------------------------------------------
  // Register Processes
  //--------------------------------------------------------------------
  always @(posedge clk) begin
    if((pr_state == Reset)) begin
      cipher_direction <= 1'b0;
    end
    else if((pr_state == Idle)) begin
      cipher_direction <= control[0];
    end
  end

  always @(posedge clk) begin
    if((pr_state == Reset || (pr_state == Idle && control != 2'b00))) begin
      busy <= 1'b1;
    end
    else if(((pr_state == Idle && control == 2'b00) || pr_state == Cipher_Latch || pr_state == Key_Schedule_Generation_Finish)) begin
      busy <= 1'b0;
    end
  end

  genvar j;
  wire [WORD_SIZE - 1:0] key_gen_wire[0:K_SEGMENTS - 1];
  generate
      for (j=0; j < K_SEGMENTS; j = j + 1) begin
        assign key_gen_wire[j] = key[(j + 1) * WORD_SIZE - 1 : j * WORD_SIZE];
      end
  endgenerate

  // Busy_Flag_Generator
  always @(posedge clk) begin
    if((pr_state == Idle)) begin
      for (i=0; i <= (K_SEGMENTS - 1); i = i + 1) begin
        key_gen[i] <= key_gen_wire[i];
      end
      // Update_Gen_Regs
      z_shift <= ZJ;
    end
    else if((pr_state == Key_Schedule_Generation_Run || pr_state == Key_Schedule_Generation_Finish)) begin
      key_gen[K_SEGMENTS - 1] <= key_feedback;
      for (i=0; i <= (K_SEGMENTS - 2); i = i + 1) begin
        key_gen[i] <= key_gen[i + 1];
      end
      z_shift <= {z_shift[0],z_shift[61:1]};
    end
  end

  // Key_Schedule_Generator
  always @(posedge clk) begin
    if((pr_state == Idle)) begin
      // Load for Encryption
      if((control == 2'b11)) begin
        a_buf <= block_input[WORD_SIZE - 1:0];
        b_buf <= block_input[BLOCK_SIZE - 1:WORD_SIZE];
        // Load for Decryption
      end
      else if((control == 2'b10)) begin
        a_buf <= block_input[BLOCK_SIZE - 1:WORD_SIZE];
        b_buf <= block_input[WORD_SIZE - 1:0];
      end
      // Run Cipher Engine
    end
    else if((pr_state == Cipher_Run || pr_state == Cipher_Finish_1 || pr_state == Cipher_Finish_2)) begin
      a_buf <= b_buf;
      b_buf <= key_xor;
    end
  end

  // Fiestel_Round
  always @(posedge clk) begin
    if((pr_state == Cipher_Latch)) begin
      if((cipher_direction == 1'b1)) begin
        block_output <= {b_buf,a_buf};
      end
      else begin
        block_output <= {a_buf,b_buf};
      end
    end
  end

  // Output_Buffer
  //--------------------------------------------------------------------
  // END Register Processes
  //--------------------------------------------------------------------
  //--------------------------------------------------------------------
  // RAM Processes
  //--------------------------------------------------------------------
  always @(posedge clk) begin
    round_key <= key_schedule[round_count_mux];
    if((pr_state == Key_Schedule_Generation_Run || pr_state == Key_Schedule_Generation_Finish)) begin
      key_schedule[round_count] <= key_gen[0];
    end
  end

  //--------------------------------------------------------------------
  // End RAM Processes
  //--------------------------------------------------------------------
  //--------------------------------------------------------------------
  // Counter Processes
  //--------------------------------------------------------------------
  always @(posedge clk) begin
    if((pr_state == Reset)) begin
      round_count <= 0;
      inv_round_count <= 0;
    end
    else if((pr_state == Idle)) begin
      round_count <= 0;
      inv_round_count <= ROUND_LIMIT - 1;
    end
    else if((pr_state == Cipher_Start || pr_state == Cipher_Run || pr_state == Key_Schedule_Generation_Run)) begin
      round_count <= round_count + 1;
      inv_round_count <= inv_round_count - 1;
    end
  end

  //--------------------------------------------------------------------
  // END Counter Processes
  //--------------------------------------------------------------------
  //--------------------------------------------------------------------
  // Async Signals
  //--------------------------------------------------------------------

  assign round_count_mux = cipher_direction == 1'b1 ? round_count : inv_round_count;
  // Fiestel Round
  assign b_lft1 = {b_buf[(WORD_SIZE - 2):0],b_buf[WORD_SIZE - 1]};
  assign b_lft8 = {b_buf[(WORD_SIZE - 9):0],b_buf[WORD_SIZE - 1:(WORD_SIZE - 8)]};
  assign b_lft2 = {b_buf[(WORD_SIZE - 3):0],b_buf[WORD_SIZE - 1:(WORD_SIZE - 2)]};
  assign b_and = b_lft1 & b_lft8;
  assign b_xor = b_and ^ b_lft2;
  assign a_xor = a_buf ^ b_xor;
  assign key_xor = round_key ^ a_xor;
  // key Schedule Generation Logic
  assign rs3 = {key_gen[K_SEGMENTS - 1][2:0],key_gen[K_SEGMENTS - 1][WORD_SIZE - 1:3]};
  generate if ((K_SEGMENTS != 4)) begin: Key_Feedback_1
      assign key_temp_1 = rs3;
  end
  endgenerate
  generate if ((K_SEGMENTS == 4)) begin: Key_Feedback_2
      assign key_temp_1 = rs3 ^ key_gen[1];
  end
  endgenerate
  assign rs1 = {key_temp_1[0],key_temp_1[WORD_SIZE - 1:1]};
  assign key_temp_2 = ((key_gen[0] ^ key_temp_1)) ^ rs1;
  assign round_constant = {ROUND_CONSTANT_HI,ROUND_CONSTANT_LO};
  assign zji = {round_constant[WORD_SIZE - 1:1],z_shift[0]};
  assign key_feedback = key_temp_2 ^ zji;

endmodule
