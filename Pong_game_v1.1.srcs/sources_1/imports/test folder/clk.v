`timescale 1ns / 1ps
// the basys 3 main clock is 100 MHz for the most of the project we need
// a 25 MHz clock so this module controls the clock by changing the
// parameter divided_value
module clock_divider #(parameter divided_value = 1) 
(
 input wire clk,
 output reg divided_clk = 0
);
 integer counter_value = 0;
 
always@ (posedge clk)
begin
  if (counter_value == divided_value)
     counter_value <= 0;
     else
     counter_value <= counter_value+1;
   end
   
always@ (posedge clk)
begin
  if (counter_value == divided_value)
    divided_clk <= ~divided_clk;
    else
    divided_clk <= divided_clk;
  end
endmodule