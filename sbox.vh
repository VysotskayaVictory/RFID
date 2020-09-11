

`define Sbox(x) {S8(x[31:28]),S7(x[27:24]),S6(x[23:20]),S5(x[19:16]),S4(x[15:12]),S3(x[11:8]),S2(x[7:4]),S1(x[3:0])}


function [3:0] S1( input [3:0] x );
  begin
    case(x)
      4'd00: S1 = 4'hC;
      4'd01: S1 = 4'h4;
      4'd02: S1 = 4'h6;
      4'd03: S1 = 4'h2;
      4'd04: S1 = 4'hA;
      4'd05: S1 = 4'h5;
      4'd06: S1 = 4'hB;
      4'd07: S1 = 4'h9;
      4'd08: S1 = 4'hE;
      4'd09: S1 = 4'h8;
      4'd10: S1 = 4'hD;
      4'd11: S1 = 4'h7;
      4'd12: S1 = 4'h0;
      4'd13: S1 = 4'h3;
      4'd14: S1 = 4'hF;
      4'd15: S1 = 4'h1;
      default: S1 = 4'hX;
    endcase
  end
endfunction


function [3:0] S2( input [3:0] x );
  begin
    case(x)
      4'd00: S2 = 4'h6;
      4'd01: S2 = 4'h8;
      4'd02: S2 = 4'h2;
      4'd03: S2 = 4'h3;
      4'd04: S2 = 4'h9;
      4'd05: S2 = 4'hA;
      4'd06: S2 = 4'h5;
      4'd07: S2 = 4'hC;
      4'd08: S2 = 4'h1;
      4'd09: S2 = 4'hE;
      4'd10: S2 = 4'h4;
      4'd11: S2 = 4'h7;
      4'd12: S2 = 4'hB;
      4'd13: S2 = 4'hD;
      4'd14: S2 = 4'h0;
      4'd15: S2 = 4'hF;
      default: S2 = 4'hX;
    endcase
  end
endfunction


function [3:0] S3( input [3:0] x );
  begin
    case(x)
      4'd00: S3 = 4'hB;
      4'd01: S3 = 4'h3;
      4'd02: S3 = 4'h5;
      4'd03: S3 = 4'h8;
      4'd04: S3 = 4'h2;
      4'd05: S3 = 4'hF;
      4'd06: S3 = 4'hA;
      4'd07: S3 = 4'hD;
      4'd08: S3 = 4'hE;
      4'd09: S3 = 4'h1;
      4'd10: S3 = 4'h7;
      4'd11: S3 = 4'h4;
      4'd12: S3 = 4'hC;
      4'd13: S3 = 4'h9;
      4'd14: S3 = 4'h6;
      4'd15: S3 = 4'h0;
      default: S3 = 4'hX;
    endcase
  end
endfunction


function [3:0] S4( input [3:0] x );
  begin
    case(x)
      4'd00: S4 = 4'hC;
      4'd01: S4 = 4'h8;
      4'd02: S4 = 4'h2;
      4'd03: S4 = 4'h1;
      4'd04: S4 = 4'hD;
      4'd05: S4 = 4'h4;
      4'd06: S4 = 4'hF;
      4'd07: S4 = 4'h6;
      4'd08: S4 = 4'h7;
      4'd09: S4 = 4'h0;
      4'd10: S4 = 4'hA;
      4'd11: S4 = 4'h5;
      4'd12: S4 = 4'h3;
      4'd13: S4 = 4'hE;
      4'd14: S4 = 4'h9;
      4'd15: S4 = 4'hB;
      default: S4 = 4'hX;
    endcase
  end
endfunction


function [3:0] S5( input [3:0] x );
  begin
    case(x)
      4'd00: S5 = 4'h7;
      4'd01: S5 = 4'hF;
      4'd02: S5 = 4'h5;
      4'd03: S5 = 4'hA;
      4'd04: S5 = 4'h8;
      4'd05: S5 = 4'h1;
      4'd06: S5 = 4'h6;
      4'd07: S5 = 4'hD;
      4'd08: S5 = 4'h0;
      4'd09: S5 = 4'h9;
      4'd10: S5 = 4'h3;
      4'd11: S5 = 4'hE;
      4'd12: S5 = 4'hB;
      4'd13: S5 = 4'h4;
      4'd14: S5 = 4'h2;
      4'd15: S5 = 4'hC;
      default: S5 = 4'hX;
    endcase
  end
endfunction


function [3:0] S6( input [3:0] x );
  begin
    case(x)
      4'd00: S6 = 4'h5;
      4'd01: S6 = 4'hD;
      4'd02: S6 = 4'hF;
      4'd03: S6 = 4'h6;
      4'd04: S6 = 4'h9;
      4'd05: S6 = 4'h2;
      4'd06: S6 = 4'hC;
      4'd07: S6 = 4'hA;
      4'd08: S6 = 4'hB;
      4'd09: S6 = 4'h7;
      4'd10: S6 = 4'h8;
      4'd11: S6 = 4'h1;
      4'd12: S6 = 4'h4;
      4'd13: S6 = 4'h3;
      4'd14: S6 = 4'hE;
      4'd15: S6 = 4'h0;
      default: S6 = 4'hX;
    endcase
  end
endfunction


function [3:0] S7( input [3:0] x );
  begin
    case(x)
      4'd00: S7 = 4'h8;
      4'd01: S7 = 4'hE;
      4'd02: S7 = 4'h2;
      4'd03: S7 = 4'h5;
      4'd04: S7 = 4'h6;
      4'd05: S7 = 4'h9;
      4'd06: S7 = 4'h1;
      4'd07: S7 = 4'hC;
      4'd08: S7 = 4'hF;
      4'd09: S7 = 4'h4;
      4'd10: S7 = 4'hB;
      4'd11: S7 = 4'h0;
      4'd12: S7 = 4'hD;
      4'd13: S7 = 4'hA;
      4'd14: S7 = 4'h3;
      4'd15: S7 = 4'h7;
      default: S7 = 4'hX;
    endcase
  end
endfunction


function [3:0] S8( input [3:0] x );
  begin
    case(x)
      4'd00: S8 = 4'h1;
      4'd01: S8 = 4'h7;
      4'd02: S8 = 4'hE;
      4'd03: S8 = 4'hD;
      4'd04: S8 = 4'h0;
      4'd05: S8 = 4'h5;
      4'd06: S8 = 4'h8;
      4'd07: S8 = 4'h3;
      4'd08: S8 = 4'h4;
      4'd09: S8 = 4'hF;
      4'd10: S8 = 4'hA;
      4'd11: S8 = 4'h6;
      4'd12: S8 = 4'h9;
      4'd13: S8 = 4'hC;
      4'd14: S8 = 4'hB;
      4'd15: S8 = 4'h2;
      default: S8 = 4'hX;
    endcase
  end
endfunction


