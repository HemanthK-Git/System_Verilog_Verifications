`timescale 1ns/1ps

// 1. Interface
interface fifo_interface;
   logic clk,rst;
   logic [7:0] data_in;
   logic write_en, read_en;
   logic [7:0] data_out;
   logic full,empty;   
endinterface

// 2. Transaction
class transaction;
  // input
  rand bit [7:0] data_in;
  bit write_en, read_en;
  rand bit [1:0] operation;
  
  // output
  bit [7:0] data_out;
  bit full, empty;
  
  constraint operation_constraint{
    operation dist {0 := 40, 1 := 40, 2 := 10, 3 := 10};    
  }  
  
  function post_randomize;
    case(operation) 
      0 : begin write_en = 1; read_en = 0; end
      1 : begin write_en = 0; read_en = 1; end
      2 : begin write_en = 1; read_en = 1; end
      3 : begin write_en = 0; read_en = 0; end       
    endcase
  endfunction
  
endclass

// 3. Generator
class generator;
  transaction trgen;
  mailbox #(transaction) mbxgen;
  int count=0;
  
  function new(mailbox #(transaction) mbxgen);
    this.mbxgen=mbxgen;
    trgen = new();   
  endfunction
  
  task run();
    repeat(count) begin
      assert(trgen.randomize()) else $display("Randomization failed");   
      mbxgen.put(trgen);      
    end
    
  endtask
endclass

// 4. Driver
class driver;
  virtual fifo_interface fif;
  transaction trdrv;
  mailbox #(transaction) mbxdrv;
  
  function new(mailbox #(transaction) mbxdrv);
  	this.mbxdrv = mbxdrv;  
    trdrv = new();
  endfunction
               
  task reset();
  	fif.rst <= 1'd1; 
    fif.data_in <= 8'd0;
    fif.write_en <= 1'b0;
    fif.read_en <= 1'b0;
    repeat (5) @(posedge fif.clk);
    fif.rst <= 1'b0;
    $display("[drv]: reset working");
  endtask

  task run;
	forever begin
      mbxdrv.get(trdrv);
      fif.data_in <= trdrv.data_in;
      fif.write_en <= trdrv.write_en;
      fif.read_en <= trdrv.read_en;
      @(posedge fif.clk) ;
      $display("[drv]: data_in=%0d, write_en=%0d, read_en=%0d", fif.data_in, fif.write_en, fif.read_en);
    end

  endtask
      
endclass

// 5. Monitor
class monitor;
  virtual fifo_interface fif;
  transaction trmon;
  mailbox #(transaction) trmbx;
  
    function new(mailbox #(transaction) trmbx);
  	this.trmbx = trmbx;                  
  endfunction
               
  task run;
	forever begin
      @(posedge fif.clk);
      trmon = new();
      trmon.data_in = fif.data_in;
      trmon.write_en = fif.write_en;
      trmon.read_en = fif.read_en;
      trmon.data_out = fif.data_out;
      trmon.full = fif.full;
      trmon.empty = fif.empty;
      trmbx.put(trmon); 
      $display("[mon] : data_out= %0d, full = %0d, empty = %0d",trmon.data_out, trmon.full, trmon.empty);
    end
  endtask
endclass

// 6. Scoreboard
class scoreboard;
  transaction trscr;
  mailbox #(transaction) scrmbx;
  bit [7:0] queue[$];
  int pass_count = 0;
  int fail_count = 0;
  
  function new(mailbox #(transaction) scrmbx);
    this.scrmbx = scrmbx;  
    trscr = new();  
  endfunction
  
  
  task run;
  	forever begin
      scrmbx.get(trscr);
      if(trscr.write_en && !trscr.full) begin
        queue.push_back(trscr.data_in); 
        $display("[scr]: data_in=%0d", trscr.data_in);
      end
      if(trscr.read_en && !trscr.empty) begin
        if(queue.size()>0) begin
          bit [7:0] expected = queue.pop_front();
          if(expected == trscr.data_out) begin
            pass_count++;
            $display("[scr]: pass, expected=%0d and data_out = %0d",expected, trscr.data_out);
          end
          else begin
            fail_count++;
          $display("[scr]: fail, expected=%0d and data_out = %0d",expected, trscr.data_out);   
          end
        end        
      end
    end
  endtask  
endclass

// 7. Environment
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scr;
  
  mailbox #(transaction) gen_to_drv;
  mailbox #(transaction) mon_to_scr;
  
  virtual fifo_interface fif;
  
  function new(virtual fifo_interface fif) ;
    this.fif = fif;
    
    gen_to_drv = new();
    mon_to_scr = new();
    
    gen = new(gen_to_drv);
    drv = new(gen_to_drv);
    mon = new(mon_to_scr);
    scr = new(mon_to_scr);
    
    drv.fif = this.fif;
    mon.fif = this.fif;  
   
  endfunction
  
  task pre_test;
    drv.reset();    
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      scr.run();      
    join_any   
  endtask
  
  task run();
    pre_test();
    test();
    #1000;
    $finish;    
  endtask
endclass

module tb();
  fifo_interface fif();
  
  
  sync_fifo dut(
    .clk(fif.clk),
    .rst(fif.rst),
    .data_in(fif.data_in),
    .write_en(fif.write_en),
    .read_en(fif.read_en),
    .data_out(fif.data_out),
    .full(fif.full),
    .empty(fif.empty)    
  );
  
  initial begin
    fif.clk = 0;
  end

  always #5 fif.clk = ~fif.clk;
  
  initial begin
    environment env = new(fif);
    env.gen.count = 20;
    env.run();
  end
endmodule