`timescale  100ns/1ps
`define DELAY 2
module I2C_tb();
parameter Depth = 4, DATA_WIDTH = 7, ADDRESS_WIDTH = 6;
  reg clk;
  reg reset;
  reg New_d;
  reg rw_bar;
  //reg Ack;
  reg [ADDRESS_WIDTH:0] Addr;
  reg [DATA_WIDTH:0] Wdata;
 //wire SDA;
 // wire SCL;
  wire [DATA_WIDTH:0] Rdata;
  wire done_c;

  integer i;

I2C_Top dut(clk,reset,new_data,rw_bar,Wdata,Addr,Rdata,done_c);

  //clk generation
  initial begin
     clk = 1'b0;
     forever #5 clk = ~clk;
  end


  initial begin
      New_d = 0;
      reset = 1;
      #15 reset = 0;
      New_d = 1; 
      rw_bar = 0;

      for(i = 0; i<32 ; i=i+1) begin
         #(`DELAY) Addr = $random;
                Wdata = $random;
      end

      #45 rw_bar = 1;
     
     $display("%0t %0b %0b %0b %0b %0b %0b",Wdata,Rdata,Addr,dut.a1.sda_temp,dut.SCL_c,dut.SDA_c,dut.Ack_c);
      #500 $finish;

  end


  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,I2C_tb);
  end
endmodule