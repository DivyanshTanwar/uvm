`include "uvm_macros.svh"
import uvm_pkg :: *;

class transaction extends uvm_sequence_item;
  
  rand bit d_in;
  bit d_out;
  bit rst;
  
  function new(string inst = "transaction");
    super.new(inst);
  endfunction
    
  `uvm_object_utils_begin(transaction);
  `uvm_field_int(d_in, UVM_DEFAULT | UVM_DEC);
  `uvm_field_int(d_out, UVM_DEFAULT | UVM_DEC);
  `uvm_object_utils_end;  
  
endclass

class seq extends uvm_sequence #(transaction);
  
  `uvm_object_utils(seq);
  
  transaction t;
  
  function new(string inst = "seq");
    super.new(inst);
  endfunction
  
  virtual task body();
    t = transaction :: type_id :: create("t");
    
    repeat(10) begin
      
      start_item(t);
      assert(t.randomize()) else `uvm_error("Sequencer", "Randomization Failed");
      `uvm_info("Sequence", $sformatf("data_in : %0d, data_out = %0d",t.d_in, t.d_out), UVM_NONE);
      finish_item(t);
      
    end
    
  endtask
  
endclass

class driver extends uvm_driver #(transaction);
  
  `uvm_component_utils(driver);
  
  virtual dff_if dif;
  
  function new(string inst = "driver", uvm_component parent = null);
    super.new(inst,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual dff_if) :: get(this, "", "dif", dif))
      `uvm_error("DRV","Unable to access uvm_config_db");
  endfunction
  
  task reset_dut();
    `uvm_info("DRV","RESET BEGIN", UVM_NONE);
    dif.rst <= 1;
    dif.d_in <= 0;
    dif.d_out <= 0;
    repeat(5) @(posedge dif.clk);
    
    dif.rst <= 0;
    `uvm_info("DRV","RESET END", UVM_NONE);

  endtask
  
  virtual task run_phase(uvm_phase phase);
    reset_dut();
    forever begin
      
      seq_item_port.get_next_item(req);
      `uvm_info("DRV", $sformatf("data_in : %0d, data_out = %0d",req.d_in, req.d_out), UVM_NONE);
      drive_dut(req);
      seq_item_port.item_done();
      
    end
    
  endtask
  
  
  task drive_dut(transaction trans);
    dif.d_in <= trans.d_in;
    repeat(2)@(posedge dif.clk);
  endtask
  
endclass

class monitor extends uvm_monitor;
  
  `uvm_component_utils(monitor);
  
  transaction t;
  virtual dff_if dif;
  uvm_analysis_port #(transaction) send;
  
  function new(string inst = "monitor", uvm_component parent);
    super.new(inst, parent);
    send = new("send", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual dff_if) :: get(this, "", "dif", dif))
      `uvm_error("MON","Unable to access uvm_config_db");
    t = transaction :: type_id :: create("t", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    @(negedge dif.rst);
    forever begin
      repeat(2) @(posedge dif.clk);
      t.d_in = dif.d_in;
      t.d_out = dif.d_out;
      t.rst = dif.rst;
      `uvm_info("MON", $sformatf("data_in : %0d, data_out = %0d",t.d_in, t.d_out), UVM_NONE);
      send.write(t);
    end
  endtask
    
endclass

class scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(scoreboard);
  
  uvm_analysis_imp #(transaction, scoreboard) recv;
  
  function new(string inst = "scoreboard", uvm_component parent);
    super.new(inst, parent);
    recv = new("recv", this);
  endfunction
  
  
  virtual function void write (transaction trans);
    
    `uvm_info("SCO", $sformatf("data_in : %0d, data_out = %0d",trans.d_in, trans.d_out), UVM_NONE);
    case(trans.rst)
      
      1'b0 : 
        
      begin
        if (trans.d_out == trans.d_in) `uvm_info("SCO","TEST PASSED", UVM_NONE)
        else `uvm_info("SCO","TEST FAILED", UVM_NONE)
      end
      
      1'b1 : 
        
      begin
        if(trans.d_out == 0) `uvm_info("SCO","TEST PASSED", UVM_NONE)
        else `uvm_info("SCO","TEST FAILED", UVM_NONE)
      end
      
    endcase

  endfunction
  
endclass

class agent extends uvm_agent;
  
  `uvm_component_utils(agent);
  
  uvm_sequencer #(transaction) seqr;
  driver drv;
  monitor mon;

  function new(string inst = "agent", uvm_component parent);
    super.new(inst, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer #(transaction) :: type_id :: create("seqr", this);
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

  function new(string inst = "env", uvm_component parent);
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
  
  env e;
  seq s;
  
  function new(string inst = "test", uvm_component parent);
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
    #100;
    phase.drop_objection(this);
    
  endtask
  
endclass
      
module tb_top;
  
  dff_if dif();
  dff dut (dif);
  
  initial dif.clk <= 0;
  
  always #5 dif.clk <= ~dif.clk;
  
  initial begin
    
    uvm_config_db #(virtual dff_if) :: set (null, "uvm_test_top.e.a*", "dif", dif);
    run_test("test");
    
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

  
endmodule
      
      
      
    
  
   
