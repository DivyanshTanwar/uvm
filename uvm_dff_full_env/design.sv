module dff (dff_if dif);
  
  always @(posedge dif.clk) begin
    
    if(dif.rst)
      dif.d_out <= 1'b0;
    
    else 
      dif.d_out <= dif.d_in;
    
  end
  
endmodule

interface dff_if();
  
  logic clk, rst;
  logic d_in, d_out;
  modport dff(
    input clk, rst, d_in,
    output d_out
  );
  
  modport tb_top (
    output clk, rst, d_in,
    input d_out
  );
  
endinterface
      
     
 
