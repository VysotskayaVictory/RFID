`include "simon.vh" 
module silc_v3(clk, rst, small_len_A, cmd, done, generic_input, generic_output);
    input clk;
    input rst;
    input [11:0] small_len_A;  
    
    input [2:0] cmd;
    output reg done;

    input [`WIDTH-1:0] generic_input;
    output reg [`WIDTH-1:0] generic_output; 

wire enc_done;
reg enc_load;
reg [`WIDTH-1:0] pdata;
wire [`WIDTH-1:0] cdata;  
wire [`KEY_WIDTH-1:0] key = 256'h0;

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

//localparam STATE_NONE = 0;
localparam STATE_LAZY = 1;
localparam STATE_PREPARE = 2;
localparam STATE_ENCRYPT = 3;
localparam STATE_ADD = 4;
localparam STATE_PRE_FIN_A = 5;
localparam STATE_FIN_A = 6;
localparam STATE_MIDDLE_1 = 7;
localparam STATE_MIDDLE_2 = 8;
localparam STATE_ADD_C = 9;
localparam STATE_ADD_M = 10;
localparam STATE_FIN_M = 11;
localparam STATE_FIN_C = 12;
localparam STATE_FIN = 13;  

reg [`STATE_WIDTH-1:0] state;
reg lazy;
reg [`WIDTH-1:0] tmp; 
reg [`WIDTH-1:0] tmp_1; 
reg [`WIDTH-1:0] tmp_2;  
reg [`LEN_WIDTH-1:0] total_len_A;  

wire [`LEN_WIDTH-1:0] len_A = {52'h0, small_len_A};
wire [`WIDTH-1:0] zpp;
assign zpp = generic_input;
reg [`STATE_WIDTH-1:0] next_state;
reg [`STATE_WIDTH-1:0] state_after_encrypt;
reg [`STATE_WIDTH-1:0] next_state_after_encrypt;
reg next_lazy;
reg [`WIDTH-1:0] next_tmp;  
reg [`WIDTH-1:0] next_tmp_1;  
reg [`WIDTH-1:0] next_tmp_2;  
reg [`LEN_WIDTH-1:0] next_total_len_A; 
reg next_done;
reg [`WIDTH-1:0] next_C;
reg [`WIDTH-1:0] next_T;

function [`WIDTH-1:0] g (input [`WIDTH-1:0] a);
    reg [`WIDTH-1:0] b;
    begin 
        b[`BYTE_SIZE-1:0] = a[`WIDTH-1:`WIDTH-`BYTE_SIZE] ^ a[`WIDTH-`BYTE_SIZE-1:`WIDTH-2*`BYTE_SIZE];
        b[`WIDTH-1:`BYTE_SIZE] = a[`WIDTH-`BYTE_SIZE-1:0];  
        g = b; 
    end 
endfunction


always @(*) begin
    // next_lazy = 
    //     if (cmd != `CMD_NONE)
    //         next_lazy = 0;
    // end     
    case (state)
        STATE_LAZY: begin
            case (cmd)
                `CMD_NONE: next_state = STATE_LAZY;
                `CMD_START: next_state = STATE_PREPARE;
                `CMD_A: next_state = STATE_ADD;
                `CMD_FIN_A: next_state = STATE_PRE_FIN_A; 
                `CMD_M: next_state = STATE_ADD_C; 
                `CMD_FIN: next_state = STATE_FIN_M;
            endcase
            next_done = 0;
            next_state_after_encrypt = state_after_encrypt;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;            
            next_total_len_A = total_len_A;
            next_tmp_1 = tmp_1;
            next_tmp_2 = tmp_2;
        end
        STATE_PREPARE: begin 
            pdata = zpp;
            enc_load = 1;
            next_state = STATE_ENCRYPT;
            next_state_after_encrypt = STATE_LAZY;
            next_done = 0;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp; 
            next_total_len_A = 0;
            next_tmp_1 = 0;
            next_tmp_2 = 0;
        end
        STATE_ENCRYPT: begin
            enc_load = 0;
            next_state_after_encrypt = state_after_encrypt;            
            next_C = 64'h0;
            next_T = 64'h0;           
            next_total_len_A = total_len_A;
            next_tmp_1 = tmp_1;
            next_tmp_2 = tmp_2;
            if (enc_done) begin
                next_tmp = cdata;
                next_lazy = 1;
                next_done = (state_after_encrypt == STATE_LAZY);
                next_state = state_after_encrypt; 
            end else begin
                next_state = STATE_ENCRYPT;
                next_done = 0;
                next_tmp = tmp;  
            end
        end
        STATE_ADD: begin 
            pdata = tmp ^ generic_input;
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_total_len_A = total_len_A + len_A;
            next_state_after_encrypt = STATE_LAZY;            
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;            
            next_tmp_1 = 0;
            next_tmp_2 = 0;
        end 
        STATE_PRE_FIN_A: begin 
            pdata = generic_input ^ tmp; //пользователь здесь должен сам подумать и дополнить сообщение нулями справа
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_FIN_A;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;           
            next_total_len_A = total_len_A + len_A;
            next_tmp_1 = 0;
            next_tmp_2 = 0;
        end 
        STATE_FIN_A: begin 
            next_tmp = g(tmp ^ total_len_A); //применить ф-цию g
            next_state = STATE_MIDDLE_1;
            next_done = 0;
            next_state_after_encrypt = 0;
            next_C = 64'h0;
            next_T = 64'h0;           
            next_total_len_A = total_len_A;
            next_tmp_1 = 0;
            next_tmp_2 = 0;
        end 
        STATE_MIDDLE_1: begin 
            next_tmp_2 = tmp; 
            pdata = g(tmp);  
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_MIDDLE_2;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;           
            next_total_len_A = total_len_A;
            next_tmp_1 = tmp_1; 
        end 
        STATE_MIDDLE_2: begin 
            pdata = tmp_2; 
            next_tmp_1 = tmp;
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_LAZY;
            next_C = 64'h0;
            next_T = 64'h0;
            next_tmp = tmp;           
            next_total_len_A = total_len_A;             
            next_tmp_2 = tmp_2;
        end  
        STATE_ADD_C: begin 
            next_tmp_2 = tmp; 
            next_C = tmp ^ generic_input;
            pdata = tmp_1 ^ tmp ^ generic_input; 
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_ADD_M; 
            next_T = 64'h0;
            next_tmp = tmp;            
            next_total_len_A = total_len_A;          
            next_tmp_1 = tmp_1; 
        end 
        STATE_ADD_M: begin 
            next_tmp_1 = tmp;
            pdata = (tmp_2 ^ generic_input) | {1'h1, 63'h0};
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_LAZY;  
            next_C = generic_output;
            next_T = 64'h0;
            next_tmp = tmp;
            next_total_len_A = total_len_A;    
            next_tmp_2 = tmp_2;
        end    
        STATE_FIN_M: begin   
            next_C = tmp ^ generic_input;  //тут тоже во-первых, автодополнение нулями + сами обрезают выход, а не я  
            next_state = STATE_FIN_C;   
            next_T = 64'h0; 
            next_tmp = tmp;
            next_total_len_A = total_len_A; 
            next_tmp_1 = tmp_1;         
            next_tmp_2 = tmp_2;
        end
        STATE_FIN_C: begin  
            pdata = g(tmp_1 ^ generic_output); 
            next_state = STATE_ENCRYPT;
            enc_load = 1;
            next_state_after_encrypt = STATE_FIN;
            next_C = generic_output;
            next_T = 64'h0;
            next_tmp = tmp;
            next_total_len_A = total_len_A; 
            next_tmp_1 = tmp_1;         
            next_tmp_2 = tmp_2;
        end 
        STATE_FIN: begin
            next_T = tmp; //обрезайте сами
            next_done = 1;
            next_state = STATE_LAZY;  
            next_C = 64'h0;
            next_tmp = tmp;
            next_total_len_A = total_len_A; 
            next_tmp_1 = tmp_1;         
            next_tmp_2 = tmp_2;
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin 
        state <= STATE_LAZY;
        // lazy <= 1;
        done <= 0;
        state_after_encrypt <= 0; 
    end else begin
        state <= next_state;
        tmp <= next_tmp;
        tmp_1 <= next_tmp_1;
        tmp_2 <= next_tmp_2;
        lazy <= next_lazy;
        done <= next_done;
        total_len_A <= next_total_len_A;     
        state_after_encrypt <= next_state_after_encrypt;        
        if (state == STATE_FIN) begin
            generic_output <= next_T;
        end else begin 
            generic_output <= next_C;
        end
    end
end

endmodule