class transaction;

bit New_d;
rand bit [6:0] Addr;
rand bit rw_bar;
rand bit [7:0] Wdata;
bit [7:0] Rdata;
bit done_c;

// Giving constraints 
constraint Addr1 {Addr > 1 ; Addr < 63;};

function transaction copy();
 copy = new();
 copy.New_d = this.New_d;
 copy.Addr = this.Addr;
 copy.rw_bar = this.rw_bar;
 copy.Rdata = this.Rdata;
 copy.done_c = this.done_c;
 copy.Wdata = this.Wdata;
endfunction

function void display(input string tag);
  $display ("rw_bar=%0b wdata=%0b rdata=%0b done=%0b ",rw_bar,Wdata,Rdata,done_c);
endfunction

endclass
