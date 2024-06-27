`include "uvm_macros.svh";
import uvm_pkg :: *;

class ethernet extends uvm_sequence_item;
  
  rand bit [6:0] preamble;
  rand bit sfd;
  rand bit [5:0] DA, SA;
  rand bit [1:0] length;
  rand bit [45:0] data;
  rand bit [3:0] crc;
  
  `uvm_object_utils_begin(ethernet);
  
  `uvm_field_int(preamble,UVM_DEFAULT);
  `uvm_field_int(sfd,UVM_DEFAULT);
  `uvm_field_int(DA,UVM_DEFAULT);
  `uvm_field_int(SA,UVM_DEFAULT);
  `uvm_field_int(length,UVM_DEFAULT);
  `uvm_field_int(data,UVM_DEFAULT);
  `uvm_field_int(crc,UVM_DEFAULT);
  
  `uvm_object_utils_end;
  
  
  function new(string path = "ethernet");
    
    super.new(path);
    
  endfunction

  
endclass


module tb_top();
  
  
  ethernet e1,e2;
  
  initial begin
    
    e1 = ethernet :: type_id :: create("e1");
    e2 = ethernet :: type_id :: create("e2");
    
    assert(e1.randomize()) else `uvm_info("TB_TOP","Randomization Failed",UVM_MEDIUM);
    
    e1.print();
    e2.copy(e1);
    e2.print();
    
  end
  
endmodule
