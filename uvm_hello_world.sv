//use this in run options to simulate in VCS simulator
//simv +UVM_TESTNAME=hello_world 

`include "uvm_macros.svh";
import uvm_pkg::*;

program automatic simple_test;

  class hello_world extends uvm_test;
    
    `uvm_component_utils(hello_world);
    
    function new (string path, uvm_component parent);
      
      super.new(path,parent);
      
    endfunction
    
    virtual task run();
      
      `uvm_info("hello_world", "Hello World I am Learning UVM.",UVM_NONE);
      
    endtask
    
    
  endclass
  
  
  initial begin
    
    run_test();
    
  end
  
  
endprogram
