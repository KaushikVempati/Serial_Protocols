// I2C Protocol Design and IMplementation for FPGA 
// Company Name : 
// I2C Single Master - Single Slave Architecture
// Design Name : I2C Protocol for M24C08 Interfacing with Memory
// Clock frequency Mode : Fast Mode (Operates at 400kHz-500kHz)
// I2C Master : EEPROM (M24C08) Microcontroller
// Addressing Scheme: 7-bit (upto 128 devices)
// Bus Arbitration and Clock stretching issues covered

`timescale 100ns/1ps

`define MASTER 1 
`define SLAVES 1

module I2C_Top(
  input clk,
  input reset,
  input New_d,
  input rw_bar,
  input [7:0] Wdata,
  input [6:0] Addr,
  output [7:0] Rdata,
  output done_c
);

wire SDA_c;
wire SCL_c;
wire Ack_c;

I2C_master_controller #(.Depth(4), .DATA_WIDTH (7), .ADDRESS_WIDTH (6)) a1 (.clk(clk),.reset(reset),.new_data(New_d),.rw_bar(rw_bar),.Addr(Addr),.Wdata(Wdata),.Rdata(Rdata),.SCL(SCL_c),.SDA(SDA_c),.Ack(Ack_c),.done_c(done_c));

I2C_mem #(.Depth(7),.DATA_WIDTH(7)) mem2 (.clk(clk),.reset(reset),.SCL(SCL_c),.SDA(SDA_c),.Ack(Ack_c));

endmodule

module I2C_master_controller #(parameter Depth = 4, DATA_WIDTH = 7, ADDRESS_WIDTH = 6) (
  input clk,
  input reset,
  input new_data,
  input rw_bar,
  input Ack,
  input [ADDRESS_WIDTH:0] Addr,
  input [DATA_WIDTH:0] Wdata,
  inout SDA,
  output SCL,
  output reg [DATA_WIDTH:0] Rdata,
  output reg done_c
);

reg [DATA_WIDTH:0] memory [2**Depth-1:0];



parameter [3:0] new_d =  4'b0000,
                write_ = 4'b0001,
                write_start =  4'b0010,
                wr_Addr = 4'b0011,
                wraddr_ack = 4'b0100,
                wr_data = 4'b0101,
                wr_data_ack = 4'b0110,
                wr_stop = 4'b0111,
               // Read op cycle
               read_addr = 4'b1000,
               raddr_ack = 4'b1001,
               read_data = 4'b1010,
               read_data_ack = 4'b1011,
               rd_stop = 4'b1100;
reg [3:0] i2c_state;
reg [6:0] Addr_temp; // for storing the address and passing it to SDA line
reg SCLK_Ref = 0;
wire Ack_Master;
reg SDA_en;
integer count = 0;
integer i = 0;
reg scl_temp,sda_temp;

//Generate the SCL clock from Clock source

always @(posedge clk) begin
     if(count <= 9) begin
        count <= count+1;
     end
     else begin
        count <= 0;
        SCLK_Ref <= ~SCLK_Ref;
     end
end


always @(posedge SCLK_Ref or posedge reset) begin
   if(reset) begin
      scl_temp <= 1'b0;
      sda_temp <= 1'b0;
       done_c <= 1'b0;
   end
   else begin
      case(i2c_state)
      new_d: begin
         scl_temp <= 1'b1;
         sda_temp <= 1'b1;
         done_c <= 1'b0;
         SDA_en <= 1'b1;
         if(new_data) begin
            i2c_state <= write_;
         end
         else begin
            i2c_state <= new_d;
         end
      end
      // Starting the write operation for checking and sending the MSB 1st byte to slave
      write_start: begin
         sda_temp <= 1'b0;
         scl_temp <= 1'b1;
         done_c <= 1'b0;
         i2c_state <= write_start;
         Addr_temp <= {Addr,rw_bar};
      end

      // Checking whether address is transferred from master to slave
      write_: begin
         if(rw_bar) begin
            i2c_state <= read_addr;
            sda_temp <= Addr_temp[0];
            i <= 1;
         end
         else begin
            i2c_state <= wr_Addr;
            sda_temp <= Addr_temp[0];
            i <= 1;
         end
      end

      wr_Addr: begin
          if(i <= 7) begin
            i <= i+1;
            sda_temp <= Addr_temp[i];
          end
          else begin
            i <= 0;
            i2c_state <= wraddr_ack;
          end
      end

      wraddr_ack : begin
         if(Ack) begin
            i2c_state <= wr_data;
            sda_temp <= Wdata[0];
            i <= i+1;
         end
         else begin
            i2c_state <= wraddr_ack;
         end
      end

     // Data transfer through SDA line when rwbar ==1
     wr_data : begin
         if(i <= 7) begin
            i <= i+1;
            sda_temp <= Wdata[i];
         end
         else begin
            i <= 0;
            i2c_state <= wr_data_ack;
         end
     end

     // Once all the data has been written on SDA line then the Slave has to send acknowledgement to master after successful writing of data frame
     wr_data_ack: begin
         if(Ack) begin
            i2c_state <= wr_stop;
            sda_temp <= 1'b0;
            scl_temp <= 1'b1;
         end
         else begin
            i2c_state <= wr_data_ack;
         end
     end

     wr_stop: begin
      sda_temp <= 1'b1;
      i2c_state <= new_d;
      done_c <= 1'b1;
     end

     // Read operation
      read_addr : begin
          if(i <= 7) begin
            sda_temp <= Addr_temp[i];
            i <= i+1;
          end
          else begin
            i <= 0;
            i2c_state <= raddr_ack;  // Ensuring that the acknowledgement is taken after Read address is taken on SDA line
          end
      end

      raddr_ack : begin
         if(Ack) begin
            i2c_state <= Rdata;
            SDA_en <= 1'b0;
            i <= i+1;
         end
         else begin
            i2c_state <= raddr_ack;
         end
      end

      // Now reading of data from Slave to Master happens after the address has been transferred
      read_data : begin
         if(i <= 7) begin
            i <= i+1;
            Rdata[i] <= sda_temp;
         end
         else begin
            i <= 0;
            i2c_state <= read_data_ack;
         end
      end


      read_data_ack : begin
         if(Ack_Master) begin
            sda_temp <= 1'b0;
            scl_temp <= 1'b1;
            i2c_state <= rd_stop;
         end
         else begin
            i2c_state <= read_data_ack;
         end
      end

      rd_stop : begin
          sda_temp <= 1'b1;
          done_c <= 1'b1;
          i2c_state <= new_d;
      end

      default: begin
           i2c_state <= new_d;
      end

      endcase
   end
end

assign Ack_Master = ((i2c_state == read_data ) && (i == 0));

assign SCL = ((i2c_state == write_start) || (i2c_state == wr_stop) || (i2c_state == rd_stop)) ? scl_temp : SCLK_Ref;

assign SDA = (SDA_en == 1'b1) ? sda_temp : 1'bz;

               
endmodule


// I2C Slave or Memory Module

module I2C_mem #(parameter Depth = 7, DATA_WIDTH=7)(
   input clk,
   input reset,
   input SCL,
   inout SDA,
   output reg Ack
);

reg [DATA_WIDTH-1:0] memory [2**Depth-1:0];
reg [7:0] Addr_in;
reg [DATA_WIDTH:0] Data_in;
reg [DATA_WIDTH:0] Data_rd;
reg SDA_en = 0;
reg Sdar;

integer i = 0;
integer j;
integer count = 0;

reg SCLK_Ref = 0;

parameter [2:0] Start = 3'b000,
               Store_addr = 3'b001,
               Send_ack = 3'b010,
               Store_data = 3'b011,
               Data_ack = 3'b100,
               stop_ = 3'b101,
               Read_data = 3'b110;
reg [2:0] i2cmem_state;


// SCLK Generation from Global clock or system clock //
// System clock frequency = 10 MHz and we require 400-500Khz for I2C Fast mode
// Logic is driven below
//  f/10 == 0.1 MHz and then 0.1MHz/2 ==> 500Khz

always @(posedge clk) begin
   if(count <= 9) begin
      count <= count+1;
   end
   else begin
      count <= 0;
      SCLK_Ref <= ~SCLK_Ref;
   end
end


// FSM CONTROL PATH LOGIC

always @(posedge SCLK_Ref or posedge reset) begin
   if(reset) begin
      for( j= 0;j<127;j=j+1) begin
          memory[j] <= 0;
      end
      SDA_en <= 1'b1;
   end
   else begin
      case(i2cmem_state) 
       Start: begin
         SDA_en <= 1'b1;
         if((SCL) && (!SDA)) begin
            i2cmem_state <= Store_addr;
         end
         else begin
            i2cmem_state <= Start;
         end
       end
// Address will be stored at Addr_in Register and it will be stored in memory 
       Store_addr: begin
         if( i <= 7) begin
            i <= i+1;
            Addr_in[i] <= SDA;
         end
         else begin
            i <= 0;
            Ack <= 1'b1;
            i2cmem_state <= Send_ack;
            Data_rd <= memory[Addr_in[7:1]];
         end
       end
 
     Send_ack : begin
        Ack <= 1'b0;
        if(Addr_in[0]) begin
         i2cmem_state <= Read_data;
         i <= 1;
         SDA_en <= 1'b0;
         Sdar <= Data_rd[0];
        end
        else begin
         i2cmem_state <= Store_data;
         SDA_en <= 1'b1;
        end
     end
     
     Store_data : begin
       if( i<= 7) begin
         i <= i+1;
         Data_in[i] <= SDA;
       end
       else begin
         i2cmem_state <= Data_ack;
         i <= 0;
         Ack <= 1'b1;
       end
     end

     Data_ack : begin
      Ack <= 1'b0;
      memory[Addr_in[7:1]] <= Data_in;
      i2cmem_state <= stop_;
     end

     stop_: begin
         SDA_en <= 1'b1;
         if((SCL) && (SDA)) begin
            i2cmem_state <= Start;
         end
         else begin
            i2cmem_state <= stop_;
         end
     end


     Read_data : begin
         SDA_en <= 1'b0;
         if(i <= 7) begin
            i <= i+1;
            Sdar <= Data_rd[i];
         end
         else begin
            i <= 0;
            SDA_en <= 1'b1;
            i2cmem_state <= stop_;
         end
     end

     default : i2cmem_state <= Start;

      endcase
   end
end

assign SDA = (SDA_en == 1'b1) ? 1'bz : Sdar;

endmodule
