// $Id:  $

/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST 28147-89 CryptoCore project     //
//                                                                 //
//   Copyright (c) 2014 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns
`include "silc_simon.vh"

module tb ();

// clock generator settings:
parameter cycles_reset =  2;  // rst active  (clk)
parameter clk_period   = 10;  // clk period ns
parameter clk_delay    =  0;  // clk initial delay

reg clk;    // clock
reg rst;    // sync reset 
    
reg [2:0] cmd;
wire done;

reg [`KEY_WIDTH-1:0] key;
reg [`WIDTH-1:0] A;
reg [`WIDTH-1:0] M;
reg [7:0] param;
reg [47:0] N;
reg [`LEN_WIDTH-1:0] len_A;
wire [`WIDTH-1:0] C;
wire [`WIDTH-1:0] T;


// instance connect
silc_simon
  u ( 
    .clk(clk),       // Input clock signal
    .rst(rst),       // Syncronous Reset
    .len_A(len_A),
    .cmd(cmd),
    .done(done), 
    .key(key), 
    .A(A), 
    .M(M), 
    .C(C), 
    .T(T), 
    .param(param), 
    .N(N)
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
    N = 48'h0;
    param = 8'h0;
    key = 256'h0;
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
    #1  key = swapkey(256'hBE5EC200_6CFF9DCF_52354959_F1FF0CBF_E95061B5_A648C103_87069C25_997C0672);
    #1  N = 48'hAFCE23_DDE451;
    #1  param = 8'hB1; 
    end
  //  Crypt mode
  //@ ( posedge clk ) #1 mode = 0;
  //  #1  pdata          = swapdata(64'h0DF82802_B741A292); pvalid = 1;
   // #1  reference_data = swapdata(64'h07F9027D_F7F7DF89);
  //@ ( posedge clk )


  //  Decrypt mode
  cmd = `CMD_NONE;
  cmd = `CMD_START;
  # (3*clk_period);
  cmd = `CMD_NONE;

  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_A;
  len_A = 64'd64; 
  A = swapdata(64'h0);
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_FIN_A;
  len_A = 64'd32; 
  A = swapdata({32'h1, 32'h0});
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);


  cmd = `CMD_M; 
  M = swapdata(64'hfedcba0987654321);
  # (clk_period);
  cmd = `CMD_NONE;
  
  @ ( posedge done );
  # (3*clk_period);

  cmd = `CMD_FIN; 
  M = swapdata(64'h1);
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
    $dumpfile("silc_simon.vcd");
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
