// Top test

`include "Transaction.sv"
`include "interface.sv"
`include "i2c_gen.sv"
`include "i2cdriver.sv"
`include "i2cmon.sv"
`include "i2csco.sv"


module test_top;

  gen gen1;
  driver dri;
  mon m1;
  sco s2;


  mailbox #(transaction) gen2driv,mon2scb;

  intf vif();

  I2C_Top dut(vif.clk,vif.reset,vif.New_d,vif.rw_bar,vif.Wdata,vif.Addr,vif.Rdata,vif.done_c);

  initial begin
    vif.clk <= 0;
  end 

  always #5 vif.clk <= ~vif.clk;

initial begin
    
    //mailbox object handle creation
    gen2driv = new();
    mon2scb = new();

    gen1 = new(gen2driv);
     dri = new(gen2driv,vif);
    m1 = new(mon2scb,vif);
    s2 = new(mon2scb);

  //  dri.vif = vif;
  //  m1.vif = vif;

    // gen1.drvnext = nextgd;
   // dri = new(gen2driv,vif); one way of giving object handle 

   // m1 = new(mon2scb,vif);
end


task pretest();
 dri.reset();
endtask

task test2();
 fork
   gen1.run();
   dri.run();
   m1.run();
   s2.run();
 join
endtask

task posttest();
 // wait(gen1.done.triggered);
 $finish();
endtask

task run();
 pretest;
 test2;
 posttest;
endtask


initial begin
   run();
end

initial begin
   $dumpfile("dump.vcd");
   $dumpvars(0,test_top);
end
  
  assign vif.SCLK_Ref = dut.a1.SCLK_Ref;
endmodule
