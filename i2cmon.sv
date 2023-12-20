class mon;
transaction trans;
 virtual intf vif;
 mailbox #(transaction) mon2scb;

function new(mailbox #(transaction) mon2scb, virtual intf vif);
this.mon2scb = mon2scb;
this.vif = vif;
endfunction

task run();
  $display("Monitor starting time %0t",$time);
    trans = new();

    forever begin
        @(posedge vif.SCLK_Ref);
         if(vif.New_d == 1'b1) begin
            if(vif.rw_bar == 1'b0) begin
                trans.Rdata = vif.Rdata;
                trans.Addr = vif.Addr;

                @(posedge vif.SCLK_Ref);
                 wait(vif.done_c == 1'b1);
                 trans.Wdata = vif.Wdata;
                  repeat(2) @(posedge vif.SCLK_Ref);
          $display("monitor : Wdata =%0d rdata=%0d addr=%0d",trans.Wdata,trans.Rdata,trans.Addr);
            end
         else begin
            trans.rw_bar = vif.rw_bar;
            trans.Wdata = vif.Wdata;
            trans.Addr = vif.Addr;

            @(posedge vif.SCLK_Ref);
            wait(vif.done_c == 1'b1);

            trans.Rdata = vif.Rdata;
           
           $display("wdata=%0d addr=%0d",trans.Rdata,trans.Addr);

             


         end
           mon2scb.put(trans);
         end
    end
endtask

endclass
