module mux4x1 (mux_if mif);
  
  always@(*) begin
      
    case(mif.sel)
        
        2'b00 : mif.y <= mif.a;
        2'b01 : mif.y <= mif.b;
        2'b10 : mif.y <= mif.c;
        2'b11 : mif.y <= mif.d;
        
      endcase
    
  end
  
endmodule

interface mux_if();
  
  logic [3:0] a,b,c,d,y;
  logic [1:0] sel;
  
  
  modport mux4x1 (
  	input a,b,c,d,sel,
    output y
  );
  modport tb_top (
    output a,b,c,d,sel,
    input y
  );
  
endinterface
