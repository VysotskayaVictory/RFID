// $Id:  $

/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST 28147-89 CryptoCore project     //
//                                                                 //
//   Copyright (c) 2014 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns 

module tb ();

// clock generator settings:
parameter cycles_reset =  2;  // rst active  (clk)
parameter clk_period   = 10;  // clk period ns
parameter clk_delay    =  0;  // clk initial delay

reg clk;    // clock
reg rst;    // sync reset 
    
reg [2:0] cmd;
wire done;
reg [1:0] control;

reg [63:0] inp;
reg [63:0] out; 

reg [255:0] key = 256'hffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff; 

// instance connect
SIMON_CIPHER simon(        
    .clk(clk), 
    .rst(rst),  
    .done(done),
    .block_input(inp),
    .block_output(out),
    .key(key),
    .control(control)
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
    //pdata = 64'h0;
    clk_counter = 0; 
    control = 2'b0;
  // Reset
  #0           rst   = 1'bX;
  #0           rst   = 1'b0;
  # ( 2*clk_period *cycles_reset) rst   = 1'b1;
  # ( 2*clk_period *cycles_reset) rst   = 1'b0;

  // key load
 
  //  Crypt mode
  //@ ( posedge clk ) #1 mode = 0;
  //  #1  pdata          = swapdata(64'h0DF82802_B741A292); pvalid = 1;
   // #1  reference_data = swapdata(64'h07F9027D_F7F7DF89);
  //@ ( posedge clk )

  #( 10 * clk_period)
  //  Decrypt mode
  control = 2'b0;
  control = 2'b1; 
  # (1*clk_period);
  control = 2'b0;

  @ ( posedge done );
  # (3*clk_period);

  control = 2'b10; 
  inp = 64'h92def06b3c130a59;
  # (2*clk_period);
  control = 2'b0;
  
  @ ( posedge done );
  # (3*clk_period);

  control = 2'b10; 
  inp = 64'hdb54c704f8189d20;
  # (2*clk_period);
  control = 2'b0;
  
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
    $dumpfile("simon_new.vcd");
    $dumpvars(0,tb);
end
///////////////////////////////////////




endmodule
// eof
