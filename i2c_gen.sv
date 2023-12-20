class gen;

transaction trans;
mailbox #(transaction) gen2driv;

// event done;
  //event drvnxt;
  //event sconxt;

  int count  = 0;

  function new(mailbox #(transaction) gen2driv);
     this.gen2driv = gen2driv;
  endfunction

  task run();
   trans = new();
   repeat(count) begin
     trans.randomize();
     gen2driv.put(trans.copy);
      $display ("%0t Wdata=%0b Rdata=%0b done_c=%0b",$time,trans.Wdata,trans.Rdata,trans.done_c);
   end
   // -> done;
  endtask

  /*int count = 0;
  function new(mailbox #(trans) gen2driv);
    this.gen2driv = gen2driv;
    t = new();
  endfunction
  
  
  task run();
    repeat(count) begin
      t.randomize();
      gen2driv.put(t.copy);
      $display("%0t wdata=%0d rdata=%0d done=%0b ",$time,t.a,t.b,t.c)
    end
    -> done;
  endtask */

endclass
