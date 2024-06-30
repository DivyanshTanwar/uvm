`include "uvm_macros.svh"
import uvm_pkg :: *;

class transaction extends uvm_sequence_item;
  
  rand bit [3:0] a, b, c, d;
  rand bit [1:0] sel;
  bit [3:0] y;
  
  function new(string inst = "transaction");
    super.new(inst);
  endfunction
  
  `uvm_object_utils_begin(transaction);
  
  `uvm_field_int(a,UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(b,UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(c,UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(d,UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(sel,UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(y,UVM_DEFAULT | UVM_DEC);

  `uvm_object_utils_end;
  
endclass


class seq extends uvm_sequence#(transaction);
  
  `uvm_object_utils(seq);
  
  transaction t;
  
  function new(string inst = "seq");
    super.new(inst);
  endfunction
  
  virtual task body();
    
    t = transaction :: type_id :: create("t");
    
    repeat(10) begin
      
      start_item(t);
      assert(t.randomize()) else `uvm_error("SEQUENCE", "Randomization Failed");
      finish_item(t);
    end
    
    
  endtask
  
endclass

class driver extends uvm_driver#(transaction);
  
  `uvm_component_utils(driver);
  
  virtual mux_if mif;
  
  function new(string inst = "driver", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual mux_if) :: get(this,"","mif",mif))
      `uvm_error("DRV","Unable to access uvm_config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    forever begin
      
      seq_item_port.get_next_item(req);
      `uvm_info("DRV", $sformatf("a = %0d, b = %0d, c = %0d, d = %0d, sel = %0d, output = %0d",req.a, req.b, req.c, req.d, req.sel, req.y),UVM_NONE);
      drive_signal(req);
      seq_item_port.item_done();
      
    end
    
  endtask
  
  task drive_signal(transaction trans);
    
    mif.a <= trans.a;
    mif.b <= trans.b;
    mif.c <= trans.c;
    mif.d <= trans.d;
    mif.sel <= trans.sel;
    #10;
  endtask
  
endclass

class monitor extends uvm_monitor;
  
  `uvm_component_utils(monitor);
  
  transaction tc;
  virtual mux_if mif;
  uvm_analysis_port #(transaction) send;
  
  function new(string inst = "monitor", uvm_component parent = null);
    super.new(inst, parent);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tc = transaction :: type_id :: create("tc");
    if(!uvm_config_db #(virtual mux_if) :: get(this,"","mif",mif))
      `uvm_error("MON", "Unable to access uvm_config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    forever begin
      
      #10;
      tc.a = mif.a;
      tc.b = mif.b;
      tc.c = mif.c;
      tc.d = mif.d;
      tc.sel = mif.sel;
      tc.y = mif.y;
      `uvm_info("MON", $sformatf("a = %0d, b = %0d, c = %0d, d = %0d, sel = %0d, output = %0d",tc.a, tc.b, tc.c, tc.d, tc.sel, tc.y),UVM_NONE);
      send.write(tc);
      
    end
    
  endtask

  
endclass

class scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(scoreboard);
  
  uvm_analysis_imp #(transaction, scoreboard) recv;
  
  function new(string inst = "scoreboard", uvm_component parent = null);
    super.new(inst,parent);
    recv = new("recv", this);
  endfunction
  
  virtual function void write (transaction tc);
    
    `uvm_info("SCO", $sformatf("a = %0d, b = %0d, c = %0d, d = %0d, sel = %0d, output = %0d",tc.a, tc.b, tc.c, tc.d, tc.sel, tc.y),UVM_NONE);
    
  case (tc.sel)
      2'b00: 
          if (tc.y == tc.a) 
            `uvm_info("SCO", "TEST PASSED", UVM_NONE)
          else 
              `uvm_info("SCO", "TEST FAILED", UVM_NONE)
      
      2'b01: 
          if (tc.y == tc.b) 
              `uvm_info("SCO", "TEST PASSED", UVM_NONE)
          else 
              `uvm_info("SCO", "TEST FAILED", UVM_NONE)
      
      2'b10: 
          if (tc.y == tc.c) 
              `uvm_info("SCO", "TEST PASSED", UVM_NONE)
          else 
              `uvm_info("SCO", "TEST FAILED", UVM_NONE)
      2'b11: 
          if (tc.y == tc.d) 
              `uvm_info("SCO", "TEST PASSED", UVM_NONE)
          else 
              `uvm_info("SCO", "TEST FAILED", UVM_NONE)
  endcase
           
  endfunction
  
endclass

class agent extends uvm_agent;
  
  `uvm_component_utils(agent);
  
  uvm_sequencer#(transaction) seqr;
  driver drv;
  monitor mon;
  
  function new(string inst = "agent", uvm_component parent = null);
    super.new(inst,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer#(transaction) :: type_id :: create("seqr", this);
    drv = driver :: type_id :: create("drv", this);
    mon = monitor :: type_id :: create("mon", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
endclass

class env extends uvm_env;
  
  `uvm_component_utils(env);
  
  agent a;
  scoreboard sco;
  
  function new(string inst = "env", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent :: type_id :: create("a", this);
    sco = scoreboard :: type_id :: create("sco", this);
  endfunction
  
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(sco.recv);
  endfunction
  
endclass

class test extends uvm_test;
  
  `uvm_component_utils(test);
  
  seq s;
  env e;
  
  function new(string inst = "test", uvm_component parent = null);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env :: type_id :: create("e", this);
    s = seq :: type_id :: create("s", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    s.start(e.a.seqr);
    #10;
    phase.drop_objection(this);
    
  endtask
  
endclass

module tb_top;
  
  mux_if mif();
  
  mux4x1 dut (mif);
  
  initial begin
    uvm_config_db #(virtual mux_if) :: set(null, "uvm_test_top.e.a*", "mif", mif);
    run_test("test");
  end
  
  initial begin
    
    $dumpfile("dump.vcd");
    $dumpvars();
    
  end

endmodule
