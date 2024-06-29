`include "uvm_macros.svh"
import uvm_pkg :: *;

class ethernet extends uvm_sequence_item;
  
  function new(string path = "ethernet");
    super.new(path);
  endfunction
  
  rand bit [3:0] SA, DA;
  rand bit [7:0] data;
  
  `uvm_object_utils_begin(ethernet)
  
  `uvm_field_int(SA, UVM_DEFAULT);
  `uvm_field_int(DA, UVM_DEFAULT);
  `uvm_field_int(data, UVM_DEFAULT);
  
  `uvm_object_utils_end
  
  
endclass


class sequence1 extends uvm_sequence#(ethernet);
  
  `uvm_object_utils(sequence1)
  
  ethernet e1;
  
  function new(string path = "sequence1");
    super.new(path);
  endfunction
 
  virtual task body();
    
    e1 = ethernet :: type_id :: create("e1");
    start_item(e1);
    assert(e1.randomize()) else `uvm_error("sequence1", "Randomization Failed");
    `uvm_info("sequence1", "Data Sent : ", UVM_NONE);
    e1.print();
    finish_item(e1);
    
  endtask
  
endclass

class sequencer extends uvm_sequencer#(ethernet);
  
  `uvm_sequencer_utils(sequencer)
  
  function new(string path = "sequencer", uvm_component parent = null);
    super.new(path, parent);  
  	`uvm_update_sequence_lib_and_item(ethernet)
  endfunction

endclass

class driver extends uvm_driver#(ethernet);
  
  `uvm_component_utils(driver)
  
  ethernet e1;
  
  function new(string path = "driver", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e1 = ethernet :: type_id :: create("e1"); 
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    forever begin
      
      seq_item_port.get_next_item(e1);
      `uvm_info("driver", "Data Recieved : ", UVM_NONE);
      e1.print();
      seq_item_port.item_done();
      
    end
    
  endtask
  
endclass

class agent extends uvm_agent;
  
  `uvm_component_utils(agent)
  
  driver d1;
  sequencer seq;
  
  function new(string path = "agent", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d1 = driver :: type_id :: create("d1", this);
    seq = sequencer :: type_id :: create("seq", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d1.seq_item_port.connect(seq.seq_item_export);
  endfunction
  
endclass

class env extends uvm_env;
  
  `uvm_component_utils(env);
  
  agent a;
  
  function new(string path = "env", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent :: type_id :: create("a", this);
  endfunction
  
endclass

class test extends uvm_test;
  
  `uvm_component_utils(test)
  
  env e;
  sequence1 s1;
  
  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env :: type_id :: create("e", this);
    s1 = sequence1 :: type_id :: create("s1");
  endfunction
  
  
  virtual task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    s1.start(e.a.seq);
    phase.drop_objection(this);
    
  endtask
  
  
endclass

module tb_top;
  
  initial begin
    
    run_test("test");
    
  end
  
endmodule
