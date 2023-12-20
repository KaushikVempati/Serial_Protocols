class sco;
 transaction trans;

 mailbox #(transaction) mon2scb;

 bit [7:0] register;

 bit [7:0] mem1 [128];


 function new(mailbox #(transaction) mon2scb);
  this.mon2scb = mon2scb;
 endfunction

 task run();
   
   forever begin
     mon2scb.get(trans);

     trans.display ("SCO");

     if(trans.rw_bar == 1'b0) begin
         
         mem1[trans.Addr] = trans.Wdata;
          $display("DATA STORED ADDR : %0d DATA : %0d", trans.Addr, trans.Wdata);
     end
     else begin
        register = mem1[trans.Addr];

        if(trans.Rdata == register) 
           $display("DATA READ -> Data Matched");
         else
            $display("DATA READ -> DATA MISMATCHED");
     end
   end
 endtask

endclass
