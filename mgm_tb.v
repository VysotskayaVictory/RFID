// $Id:  $

/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST 28147-89 CryptoCore project     //
//                                                                 //
//   Copyright (c) 2014 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns
`include "mgm.vh"

module tb ();

// clock generator settings:
parameter cycles_reset =  2;  // rst active  (clk)
parameter clk_period   = 10;  // clk period ns
parameter clk_delay    =  0;  // clk initial delay

reg clk;    // clock
reg rst;    // sync reset 
    
reg [5:0] cmd;
wire done;

reg [`KEY_WIDTH-1:0] key;
reg [`WIDTH-1:0] A;
reg [`WIDTH-1:0] M;
reg [`WIDTH-2:0] nonce;
reg [`LEN_WIDTH-1:0] len_A;
reg [`LEN_WIDTH-1:0] len_M;
wire [`WIDTH-1:0] C;
wire [`WIDTH-1:0] T;


// instance connect
mgm
  u ( 
    .clk(clk),       // Input clock signal
    .rst(rst),       // Syncronous Reset
    .len_A(len_A),
    .len_M(len_M),
    .cmd(cmd),
    .done(done), 
    .key(key), 
    .A(A), 
    .M(M), 
    .C(C), 
    .T(T), 
    .nonce(nonce)
  );


 reg [24:0] clk_counter; // just clock counter for debug

// Clock generation
 always begin
 # (clk_delay);
   forever # (clk_period/2) clk = ~clk;
 end

// Initial statement
initial begin
 #0 clk  = 1'b0;  
    key = 256'h0;
    nonce = 63'h12DEF06B3C130A59;
    //pdata = 64'h0;
    clk_counter = 0; 
    cmd = `CMD_NONE;
  // Reset
  #0           rst   = 1'bX;
  #0           rst   = 1'b0;
  # ( 2*clk_period *cycles_reset) rst   = 1'b1;
  # ( 2*clk_period *cycles_reset) rst   = 1'b0;

  // key load
  @ ( posedge clk ) begin
    #1  key = swapkey(256'hFFEEDDCCBBAA99887766554433221100F0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF);
     
    end
  //  Crypt mode
  //@ ( posedge clk ) #1 mode = 0;
  //  #1  pdata          = swapdata(64'h0DF82802_B741A292); pvalid = 1;
   // #1  reference_data = swapdata(64'h07F9027D_F7F7DF89);
  //@ ( posedge clk )

  //  Decrypt mode
  cmd = `CMD_NONE;
  cmd = `CMD_START_A;
  # (clk_period);
  cmd = `CMD_NONE;

  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = 64'h0101010101010101;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = 64'h0202020202020202;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = 64'h0303030303030303;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = 64'h0404040404040404;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = 64'h0505050505050505;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_FIN_A;
  A = 64'hEA00000000000000;
  len_A = 64'd8;  
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);


  cmd = `CMD_START_M; 
  # (clk_period);
  cmd = `CMD_NONE;

  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'hFFEEDDCCBBAA9988;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'h1122334455667700;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'h8899AABBCCEEFF0A;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'h0011223344556677;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'h99AABBCCEEFF0A00;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);


  cmd = `CMD_DOUBLE_M;
  M = 64'h1122334455667788;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'hAABBCCEEFF0A0011;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_DOUBLE_M;
  M = 64'h2233445566778899;
  len_M = 64'd64;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_FIN_M;
  M = 64'hAABBCC0000000000;
  len_M = 64'd24;
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_FIN;  
  # (clk_period);


  cmd = `CMD_NONE; 
  @ ( posedge done );
  # (3*clk_period);


  @ ( posedge clk )
  #1 $stop;
end


always begin
 @( posedge clk );
    clk_counter <=  clk_counter + 1;
end


/////////////// dumping ///////////////
initial begin
    $dumpfile("code.vcd");
    $dumpvars(0,tb);
end
///////////////////////////////////////



// ======= swap4(x) =======
function [31:0] swap4( input [31:0] x );
begin
  swap4 = {x[7:0],x[15:8],x[23:16],x[31:24]};
end
endfunction

// ======= swapdate(data) =======
function [63:0] swapdata( input [63:0] data );
begin
  swapdata = data;//swap4(data[31:0]),swap4(data[63:32])};
end
endfunction

// ======= swapkey(key) =======
function [255:0] swapkey( input [255:0] key );
reg [31:0] K [0:7];
begin
    K[0] = swap4(key[255:224]);
    K[1] = swap4(key[223:192]);
    K[2] = swap4(key[191:160]);
    K[3] = swap4(key[159:128]);
    K[4] = swap4(key[127:96]);
    K[5] = swap4(key[95:64]);
    K[6] = swap4(key[63:32]);
    K[7] = swap4(key[31:0]);
 swapkey = key;
end
endfunction

endmodule
// eof
