class driver;
transaction trans;
mailbox #(transaction) gen2driv;

virtual intf vif;

function new(mailbox #(transaction) gen2driv,virtual intf vif);
  this.gen2driv = gen2driv;
  this.vif = vif;
endfunction


// Initialize the interface Values at reset
task reset();
 vif.reset <= 1'b1;
 vif.New_d <= 1'b0;
 vif.rw_bar <= 1'b0;
 vif.Wdata <= 0;
 vif.Addr <= 0;

 repeat(10) @(posedge vif.clk);
   vif.reset <= 1'b0;
  repeat(5) @(posedge vif.clk);
   $display ("[DRV: RESET DONE]");
endtask


// In the run task get the values of transaction through mailbox
task run();
forever begin
  gen2driv.get(trans);

  @(posedge vif.SCLK_Ref);
    vif.reset <= 1'b0;
    vif.New_d <= 1'b1;
    vif.rw_bar <= trans.rw_bar;
    vif.Wdata <= trans.Wdata;
    vif.Rdata <= trans.Rdata;
    vif.Addr <= trans.Addr;

    @(posedge vif.SCLK_Ref);
      vif.New_d <= 1'b0;

    wait(vif.done_c == 1'b1);
     @(posedge vif.SCLK_Ref);
    wait(vif.done_c == 1'b0);
    
     $display ("rwbar=%0b wdata=%0b rdata=%0b waddr=%0b",vif.rw_bar,vif.Wdata,vif.Rdata,vif.Addr);
end

endtask

endclass
