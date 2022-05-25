`timescale 1ps/1ps


module Pong_Paddle_Ctrl
  #(parameter c_PLAYER_PADDLE_X=0,
    parameter c_PADDLE_HEIGHT=6,
    parameter c_GAME_HEIGHT=30)
  (input            clk,             //25Mhz clock
   input RxD,                        //Uart reciver input
   input [5:0]      i_Col_Count_Div, //number of Columns after divition
   input [5:0]      i_Row_Count_Div, //number of Rows after divition
   output reg enter_o,               //output signal to tell the game that the enter key is pressed
   output reg       o_Draw_Paddle,   //signal to draw the paddle
   output reg [5:0] o_Paddle_Y);     //register to keep track of the upper point/edge of the paddle 
 
  // Set the Speed of the paddle movement.  
  // In this case, the paddle will move one board game unit
  // every 50 milliseconds that the button is held down.
  parameter c_PADDLE_SPEED = 1250000;
 
  reg [31:0] r_Paddle_Count = 0;

  reg   i_Paddle_Up;       //signal is true/1 if the W key is pressed
  reg   i_Paddle_Dn;       //signal is true/1 if the S key is pressed
 
  wire w_Paddle_Count_En;  //signal is true/1 if either the W or the S key is pressed                                           
  wire scan_done_tick;     //checks if the Uart done sending data to the FPGA
  wire [7:0] RxData;       //Uart data wire
  wire divided_clk;        //25Mhz clock

  localparam  // these parameters to not belong to any other data type such as net or reg
    w       = 8'h77,       // up/w
    W       = 8'h57,       // up/W
    s       = 8'h73,       // down/s
    S       = 8'h53,       // down/S
    enter   = 8'h0D;       // start/enter

  clock_divider clock_wrapper(             //25MHz clock module
    .clk(clk),.divided_clk(divided_clk));
  
  receiver Uart_rx (                       //Uart reciver module
    .clk(clk),
    .RxD(RxD),
    .RxData(RxData)
    );
  
  //checks if the data recived from the Uart is the enter key
  always @(posedge divided_clk) begin
    if (RxData == enter)
    enter_o <= 1'b1;
    else
    enter_o <= 1'b0;
  end
  //checks which key is pressed W/S
  always @(posedge divided_clk) begin
    if (RxData == w ^ RxData == W) begin
      i_Paddle_Up <= 1'b1;
      i_Paddle_Dn <= 1'b0;
    end
    else if (RxData == s ^ RxData == S) begin
      i_Paddle_Dn <= 1'b1;
      i_Paddle_Up <= 1'b0;
    end
    else begin
      i_Paddle_Dn <= 1'b0;
      i_Paddle_Up <= 1'b0;
    end
  end
  // Only allow paddles to move if only one keys is pushed.
  // ^ is an XOR bitwise operation.
  assign w_Paddle_Count_En = i_Paddle_Up ^ i_Paddle_Dn;
 
  always @(posedge divided_clk)
  begin
    if (w_Paddle_Count_En == 1'b1)
    begin
      if (r_Paddle_Count == c_PADDLE_SPEED)
        r_Paddle_Count <= 0;
      else
        r_Paddle_Count <= r_Paddle_Count + 1;
    end
 
    // Update the Paddle Location slowly.  Only allowed when the
    // Paddle Count reaches its limit.  Don't update if paddle is
    // already at the top of the screen.
    if (i_Paddle_Up == 1'b1 && r_Paddle_Count == c_PADDLE_SPEED &&
        o_Paddle_Y !== 0)
      o_Paddle_Y <= o_Paddle_Y - 1;
    else if (i_Paddle_Dn == 1'b1 && r_Paddle_Count == c_PADDLE_SPEED &&
             o_Paddle_Y !== c_GAME_HEIGHT-c_PADDLE_HEIGHT-1)
      o_Paddle_Y <= o_Paddle_Y + 1;
 
  end
 
 
  // Draws the Paddles as determined by input parameter
  // c_PLAYER_PADDLE_X as well as o_Paddle_Y
  always @(posedge divided_clk)
  begin
    // Draws in a single column and in a range of rows.
    // Range of rows is determined by c_PADDLE_HEIGHT
    if (i_Col_Count_Div == c_PLAYER_PADDLE_X &&
        i_Row_Count_Div >= o_Paddle_Y &&
        i_Row_Count_Div <= o_Paddle_Y + c_PADDLE_HEIGHT)
      o_Draw_Paddle <= 1'b1;
    else
      o_Draw_Paddle <= 1'b0;
  end
 
endmodule // Pong_Paddle_Ctrl