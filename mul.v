`include "mgm.vh" 
`timescale 1ns / 100ps

module mul (clk, rst, load, done, v1, v2, v);

input  clk;    // Input clock signal for synchronous design
input  rst;    // Syncronous Reset input 
input  load;   // load plain text and start cipher cycles
output reg done; 
input [`WIDTH-1:0] v1;
input [`WIDTH-1:0] v2;
output reg [`WIDTH-1:0] v;

reg [`WIDTH-1:0] next_v, next_v2, v2_tmp;

reg dummy;    
reg signed [`LOG_WIDTH+1:0] i, j, k, next_i;  
reg [1:0] next_state, state;   

localparam STATE_LAZY = 0;
localparam STATE_PREPARE = 1;
localparam STATE_COUNT = 2;

always @(*) begin
    case (state)
        STATE_LAZY: begin
            next_i = 0;
            next_v2 = v2;
            next_v = v; 
            if (load) next_state = STATE_PREPARE;
            else next_state = STATE_LAZY;             
            done = 0;            
        end
        STATE_PREPARE: begin
            next_state = STATE_COUNT;
            next_v = 64'h0;
            next_i = 0;
            next_v2 = v2;
            done = 0;
        end
        STATE_COUNT: begin 
            if (i < `WIDTH) begin
                next_i = i + 1;
                next_state = STATE_COUNT;
                done = 0;
                next_v = v;
            end else begin
                done = 1;
                next_state = STATE_LAZY;
                next_i = 0;
                next_v = v;
            end
            dummy = v[`WIDTH-1];
            for (j = `WIDTH-1; j >= 1; j = j - 1) begin
                if (j == 1 | j == 3 | j == 4) begin
                    next_v[j] = v[j-1] ^ dummy ^ (v1[j] & v2_tmp[`WIDTH-1]);
                end else begin
                    next_v[j] = v[j-1] ^ (v1[j] & v2_tmp[`WIDTH-1]);
                end
            end
            next_v[0] = 0 ^ dummy ^ (v1[0] & v2_tmp[`WIDTH-1]);
            next_v2 = v2_tmp << 1;
        end  
    endcase
end

always @(posedge clk) begin
  if(rst) begin 
    state <= STATE_LAZY;
    i <= 0; 
    v <= 64'h0;
  end else begin
    v <= next_v; 
    state <= next_state;
    i <= next_i; 
    v2_tmp <= next_v2;
  end
end
endmodule
