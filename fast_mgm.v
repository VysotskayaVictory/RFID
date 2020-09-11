`include "mgm.vh" 
module mgm(clk, rst, len_A, len_M, cmd, done, key, A, M, C, T, nonce);
    input clk;
    input rst;
    input [`LEN_WIDTH-1:0] len_A; 
    input [`LEN_WIDTH-1:0] len_M; 
    
    input [5:0] cmd;
    output reg done;

    input [`KEY_WIDTH-1:0] key;
    input [`WIDTH-1:0] A;
    input [`WIDTH-1:0] M;  
    output reg [`WIDTH-1:0] C;
    output reg [`WIDTH-1:0] T;
    input [`WIDTH-2:0] nonce;

wire enc_done, mul_done;
reg enc_load, mul_load;
reg [`WIDTH-1:0] pdata;
wire [`WIDTH-1:0] cdata;  
reg [`WIDTH-1:0] v1,v2, next_v;
wire [`WIDTH-1:0] v;

gost_28147_89 enc(
    .clk(clk),
    .key(key),
    .mode(1'h0),
    .rst(rst),
    .load(enc_load),
    .done(enc_done),
    .pdata(pdata),
    .cdata(cdata)
);

mul m(
    .clk(clk), 
    .rst(rst),
    .load(mul_load),
    .done(mul_done),
    .v1(v1),
    .v2(v2),
    .v(v)
);

//localparam STATE_NONE = 0;
localparam STATE_LAZY = 1;
localparam STATE_PREPARE_1 = 2;
localparam STATE_EXTRA_1 = 3;
localparam STATE_ENCRYPT = 4;
localparam STATE_PROC_Z = 5;
localparam STATE_PROC_A = 6;
localparam STATE_FIN_PROC_Z = 7;
localparam STATE_FIN_A = 8;
localparam STATE_PREPARE_2 = 9;
localparam STATE_EXTRA_2 = 10;
localparam STATE_PROC_DOUBLE_Z = 11;
localparam STATE_PROC_Y = 12;
localparam STATE_PROC_M = 13; 
localparam STATE_FIN_PROC_DOUBLE_Z = 14;
localparam STATE_FIN_PROC_Y = 15;
localparam STATE_FIN_M = 16;
localparam STATE_LAST_PROC_Z = 17;
localparam STATE_PROC_LEN = 18;
localparam STATE_PROC_LEN_FIN = 19; 
localparam STATE_FIN = 20; 
localparam STATE_MULNXOR = 21;

reg [`STATE_WIDTH-1:0] state;
reg lazy;
reg [`WIDTH-1:0] tmp;  
reg [`LEN_WIDTH-1:0] total_len_A; 
reg [`LEN_WIDTH-1:0] total_len_M; 
reg [`WIDTH-1:0] H; 
reg [`WIDTH-1:0] Z;
reg [`WIDTH-1:0] Y; 
reg [`WIDTH-1:0] res; 

reg [`STATE_WIDTH-1:0] next_state;
reg [`STATE_WIDTH-1:0] state_after_encrypt;
reg [`STATE_WIDTH-1:0] next_state_after_encrypt;
//reg next_lazy;
//reg next_lazy;
reg [`WIDTH-1:0] next_tmp; 
reg [`WIDTH-1:0] next_res;   
reg [`LEN_WIDTH-1:0] next_total_len_A; 
reg [`LEN_WIDTH-1:0] next_total_len_M;
reg [`WIDTH-1:0] next_H; 
reg [`WIDTH-1:0] next_Z;
reg [`WIDTH-1:0] next_Y; 
reg [`WIDTH-1:0] next_C;
reg [`WIDTH-1:0] next_T;  
reg next_done; 

always @(*) begin
    // if (lazy) begin
    //     if (cmd != `CMD_NONE)
    //         next_lazy = 0;
    // end     
    //next_v = v;
    case (state)
        STATE_LAZY: begin
            case (cmd)
                `CMD_NONE: next_state = STATE_LAZY;
                `CMD_START_A: next_state = STATE_PREPARE_1;
                `CMD_A: next_state = STATE_PROC_Z; 
                `CMD_FIN_A: next_state = STATE_FIN_PROC_Z;
                `CMD_START_M: next_state = STATE_PREPARE_2;
                `CMD_DOUBLE_M: next_state = STATE_PROC_DOUBLE_Z;  
                `CMD_FIN_M: next_state = STATE_FIN_PROC_DOUBLE_Z;
                `CMD_FIN: next_state = STATE_LAST_PROC_Z; 
            endcase       
            next_done = 0;
            next_state_after_encrypt = state_after_encrypt;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;            
            next_total_len_A = total_len_A; 
            next_total_len_M = total_len_M;  
            next_res = res;
            next_Z = Z;
            next_Y = Y; 
            next_H = H;   
        end
        STATE_PREPARE_1: begin 
            pdata = {1'h1,nonce};
            next_tmp = 64'h0;
            enc_load = 1;
            next_state = STATE_ENCRYPT; 
            next_state_after_encrypt = STATE_EXTRA_1;
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = 0;
            next_total_len_A = 0;
            next_res = 64'h0;
            next_Z = 64'h0;
            next_Y = 64'h0; 
            next_H = 64'h0; 
            next_done = 0;
            mul_load = 0;
        end
        STATE_EXTRA_1: begin
        	next_Z = tmp;
            next_state = STATE_LAZY;
            next_C = 64'h0;
            next_T = 64'h0;
            enc_load = 1;
            next_state_after_encrypt = 0;
            next_total_len_M = 0;
            next_total_len_A = 0;
            next_res = res;
            next_tmp = tmp;  
            next_Y = 64'h0; 
            next_H = 64'h0;
            next_done = 1;
            mul_load = 0;
        end

        STATE_ENCRYPT: begin
            enc_load = 0;
            mul_load = 0;
            next_state_after_encrypt = state_after_encrypt;            
            next_C = 64'h0;
            next_T = 64'h0;           
            next_total_len_A = total_len_A; 
            next_total_len_M = total_len_M; 
            next_res = res;
            if (enc_done) begin
                next_tmp = cdata;
                //next_lazy = 1;
                next_done = done;
                next_state = state_after_encrypt; 
            end else begin
                next_state = STATE_ENCRYPT;
                next_done = 0;
                next_tmp = tmp;  
            end
            next_Z = Z;
            next_Y = Y;  
            next_H = H; 
        end

        STATE_PROC_Z: begin
        	pdata = Z; 
        	next_Z = {Z[`WIDTH-1:`WIDTH/2]+32'h1,Z[`WIDTH/2-1:0]};
        	enc_load = 1;
            next_state = STATE_ENCRYPT;
        	next_state_after_encrypt = STATE_PROC_A;
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A; 
            next_tmp = tmp; 
            next_Y = 64'h0;  
            next_H = 64'h0; 
            next_res = res;
            next_done = 0;
            mul_load = 0;
        end

		STATE_PROC_A: begin 
            v1 = tmp;
            v2 = A;
            mul_load = 1;
        	next_res = res; 
            next_state = STATE_MULNXOR;
            next_total_len_A = total_len_A + len_A;
            next_C = 64'h0;
            next_T = 64'h0;
            enc_load = 0;
            next_state_after_encrypt = STATE_LAZY;
            next_total_len_M = 0;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = 64'h0;  
            next_H = tmp; 
            next_done = 0; //1
        end 

        STATE_FIN_PROC_Z: begin
            pdata = Z; 
            next_Z = {Z[`WIDTH-1:`WIDTH/2]+32'h1,Z[`WIDTH/2-1:0]};
            enc_load = 1;
            next_state = STATE_ENCRYPT;
            next_state_after_encrypt = STATE_FIN_A; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;  
            next_Y = 64'h0; 
            next_done = 0;
            mul_load = 0;
        end

        STATE_FIN_A: begin   
            v1 = tmp;
            v2 = A;
            mul_load = 1;
            next_res = res; 
            next_state = STATE_MULNXOR; 
            next_total_len_A = total_len_A + len_A;
            next_C = 64'h0;
            next_T = 64'h0;
            enc_load = 0;
            next_state_after_encrypt = STATE_LAZY;
            next_total_len_M = total_len_M;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = 64'h0;  
            next_H = tmp;
            next_done = 0; //
        end

        STATE_PREPARE_2: begin 
            pdata = {1'h0,nonce};
            enc_load = 1;
            next_state = STATE_ENCRYPT;
            next_state_after_encrypt = STATE_EXTRA_2;
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = 64'h0;  
            next_H = 64'h0;
            next_done = 0;
            mul_load = 0;
        end

        STATE_EXTRA_2: begin
            next_Y = tmp;
            next_state = STATE_LAZY;
            next_C = 64'h0;
            next_T = 64'h0;
            enc_load = 0;
            next_state_after_encrypt = 0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;   
            next_H = 64'h0; 
            next_done = 1;
            mul_load = 0;
        end

        STATE_PROC_DOUBLE_Z: begin 
        	pdata = Z; 
        	next_Z = {Z[`WIDTH-1:`WIDTH/2]+32'h1,Z[`WIDTH/2-1:0]};
        	enc_load = 1;
            next_state = STATE_ENCRYPT;
        	next_state_after_encrypt = STATE_PROC_Y; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp; 
            next_Y = Y;  
            next_H = 64'h0;
            next_done = 0;
            mul_load = 0;
        end

        STATE_PROC_Y: begin 
            next_H = tmp;
            pdata = Y;  
            next_Y = {Y[`WIDTH-1:`WIDTH/2],Y[`WIDTH/2-1:0]+32'h1};
            enc_load = 1;
            next_state = STATE_ENCRYPT;
            next_state_after_encrypt = STATE_PROC_M;
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;  
            next_done = 0;
            mul_load = 0;
        end 

        STATE_PROC_M: begin 
            next_C = tmp ^ M;
            v1 = H;
            v2 = tmp ^ M;
            mul_load = 1;
            next_res = res;  
            next_state = STATE_MULNXOR;
            next_total_len_M = total_len_M + len_M;
            next_T = 64'h0;
            enc_load = 0;
            next_state_after_encrypt = STATE_LAZY;
            next_total_len_A = total_len_A; 
            next_Z = Z;
            next_Y = Y;  
            next_H = H;
            next_done = 0; //
        end 

        STATE_FIN_PROC_DOUBLE_Z: begin
        	pdata = Z; 
        	next_Z = {Z[`WIDTH-1:`WIDTH/2]+32'h1,Z[`WIDTH/2-1:0]};
        	enc_load = 1;
            next_state = STATE_ENCRYPT;
        	next_state_after_encrypt = STATE_FIN_PROC_Y; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp; 
            next_H = H;
            next_done = 0;
            mul_load = 0;
        end

        STATE_FIN_PROC_Y: begin 
			next_H = tmp;
        	pdata = Y;  
        	next_Y = {Y[`WIDTH-1:`WIDTH/2],Y[`WIDTH/2-1:0]+32'h1};
        	enc_load = 1;
            next_state = STATE_ENCRYPT;
        	next_state_after_encrypt = STATE_FIN_M;
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res; 
            next_Y = Y;
            next_done = 0;
            next_tmp = tmp;
            mul_load = 0;
        end

		STATE_FIN_M: begin   
			next_C = (tmp ^ M) & (~((64'h1 << (`WIDTH -len_M)) - 64'h1));
            v1 = H;
            v2 = (tmp ^ M) & (~((64'h1 << (`WIDTH -len_M)) - 64'h1));
            mul_load = 1;
        	next_res = res;  
            next_state = STATE_MULNXOR;  
            next_total_len_M = total_len_M + len_M; 
            next_T = 64'h0;   
            enc_load = 0;      
            next_state_after_encrypt = STATE_LAZY; 
            next_total_len_A = total_len_A;    
            next_tmp = tmp;
            next_Z = Z;
            next_Y = Y; 
            next_H = H; 
            next_done = 0; //
        end

        STATE_LAST_PROC_Z: begin
        	pdata = Z; 
        	next_Z = {Z[`WIDTH-1:`WIDTH/2]+32'h1,Z[`WIDTH/2-1:0]};
        	enc_load = 1;
            next_state = STATE_ENCRYPT;
        	next_state_after_encrypt = STATE_PROC_LEN; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_Z = Z;  
            next_H = H;
            next_done = 0;
            next_tmp = tmp;
            mul_load = 0;
        end

        STATE_PROC_LEN: begin
            v1 = tmp;
            v2 = {total_len_A, total_len_M}; 
            mul_load = 1;
        	enc_load = 0;
            next_state = STATE_MULNXOR;
        	next_state_after_encrypt = STATE_PROC_LEN_FIN; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = Y; 
            next_H = tmp;
            next_done = 0;
        end

        STATE_PROC_LEN_FIN: begin 
            pdata = res; 
            enc_load = 1;
            next_state = STATE_ENCRYPT;
            next_state_after_encrypt = STATE_FIN; 
            next_C = 64'h0;
            next_T = 64'h0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = Y; 
            next_H = tmp;
            next_done = 0;
            mul_load = 0;
        end

        STATE_FIN: begin
        	next_T = tmp;
            next_state = STATE_LAZY;
            next_C = 64'h0; 
            enc_load = 0;
            next_state_after_encrypt = 0;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_res = res;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = Y; 
            next_H = H;
            next_done = 1;
            mul_load = 0;
        end


        STATE_MULNXOR: begin 
           // next_done = done;
            if (mul_done) begin
                next_state = state_after_encrypt;
                next_res = res ^ v;
                if (state_after_encrypt == STATE_PROC_LEN_FIN) next_done = 0;
                else next_done = 1;
            end else begin
                next_state = STATE_MULNXOR;
                next_res = res;
                next_done = 0;
            end
            next_C = C;
            next_T = T; 
            enc_load = 0;
            mul_load = 0;
            next_state_after_encrypt = state_after_encrypt;
            next_total_len_M = total_len_M;
            next_total_len_A = total_len_A;
            next_tmp = tmp;
            next_Z = Z;
            next_Y = Y; 
            next_H = H;
        end
    endcase
end  

always @(posedge clk) begin
    if (rst) begin 
        state <= STATE_LAZY;
        //lazy <= 1;
        done <= 0;
        state_after_encrypt <= 0; 
    end else begin
    state <= next_state;
    tmp <= next_tmp;   
    //lazy <= next_lazy;
    res <= next_res;
    total_len_A <= next_total_len_A;
    total_len_M <= next_total_len_M; 
    state_after_encrypt <= next_state_after_encrypt;
    Z <= next_Z;
    Y <= next_Y;
    H <= next_H;
    done <= next_done;
    C <= next_C;
    T <= next_T; 
    end
end
endmodule