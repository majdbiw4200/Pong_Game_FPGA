`timescale 1ps/1ps

//this module combines the paddle modules, ball module and the vga screen counter
//module to drow the game on the screen
module Pong_Top
  #(parameter c_TOTAL_COLS=800,
    parameter c_TOTAL_ROWS=525,
    parameter c_ACTIVE_COLS=640,
    parameter c_ACTIVE_ROWS=480)
  (input            clk,          //100Mhz clock
   input            i_HSync,      //horizontal input
   input            i_VSync,      //vertical input
   input            RxD,          //Uart reciver input
   input            enter_i,      //game start input
   // Output Video
   output reg       o_HSync,
   output reg       o_VSync,
   output [3:0] o_Red_Video,
   output [3:0] o_Grn_Video,
   output [3:0] o_Blu_Video);
 
  // Local Constants to Determine Game Play
  parameter c_GAME_WIDTH  = 40;
  parameter c_GAME_HEIGHT = 30;
  parameter c_SCORE_LIMIT = 9;
  parameter c_PADDLE_HEIGHT = 6;
  parameter c_PADDLE_COL_P1 = 0;  // Col Index of Paddle for P1
  parameter c_PADDLE_COL_Bot = c_GAME_WIDTH-1; // Index for P2/bot
 
  // State machine enumerations
  parameter IDLE    = 3'b000;
  parameter RUNNING = 3'b001;
  parameter P1_WINS = 3'b010;
  parameter Bot = 3'b011;
  parameter CLEANUP = 3'b100;
 
  reg [2:0] r_SM_Main = IDLE;
 
  wire       w_HSync, w_VSync;
  wire [9:0] w_Col_Count, w_Row_Count;
   
  wire       w_Draw_Paddle_P1, w_Draw_Paddle_Bot;
  wire [5:0] w_Paddle_Y_P1, w_Paddle_Y_Bot;
  wire       w_Draw_Ball, w_Draw_Any;
  wire [5:0] w_Ball_X, w_Ball_Y;
  wire divided_clk;
 
  reg [3:0] r_P1_Score = 0;
  reg [3:0] r_Bot_Score = 0;
 

  // Divided version of the Row/Col Counters
  // Allows us to make the board 40x30
  wire [5:0] w_Col_Count_Div, w_Row_Count_Div;

  clock_divider clock_wrapper(                //module for 25Mhz clock (divided_clk)
    .clk(clk),.divided_clk(divided_clk));
 
  Sync_To_Count #(.TOTAL_COLS(c_TOTAL_COLS),
                  .TOTAL_ROWS(c_TOTAL_ROWS)) Sync_To_Count_Inst
    (.clk(divided_clk),
     .i_HSync(i_HSync),
     .i_VSync(i_VSync),
     .o_HSync(w_HSync),
     .o_VSync(w_VSync),
     .o_Col_Count(w_Col_Count),
     .o_Row_Count(w_Row_Count));
 
  always @(posedge divided_clk)
  begin
    o_HSync <= w_HSync;
    o_VSync <= w_VSync;
  end
 
  // Drop 4 LSBs, which effectively divides by 16
  assign w_Col_Count_Div = w_Col_Count[9:4];
  assign w_Row_Count_Div = w_Row_Count[9:4];
 
 
  // Instantiation of the left Paddle (Player 1) + draw
  Pong_Paddle_Ctrl #(.c_PLAYER_PADDLE_X(c_PADDLE_COL_P1),
                     .c_GAME_HEIGHT(c_GAME_HEIGHT)) P1_Inst
    (.clk(clk),
     .RxD(RxD),
     .enter_o(enter_i),
     .i_Col_Count_Div(w_Col_Count_Div),
     .i_Row_Count_Div(w_Row_Count_Div),
     .o_Draw_Paddle(w_Draw_Paddle_P1),
     .o_Paddle_Y(w_Paddle_Y_P1));

  // Instantiation of the right Paddle (Player2/bot) + draw
  Pong_Bot #(.c_PLAYER_PADDLE_X(c_PADDLE_COL_Bot),
            .c_GAME_HEIGHT(c_GAME_HEIGHT)) Bot_Inst
  (
    .Ball_X(w_Ball_X),
    .Ball_Y(w_Ball_Y),
    .clk(divided_clk),
    .i_Col_Count_Div(w_Col_Count_Div),
    .i_Row_Count_Div(w_Row_Count_Div),
    .o_Draw_Paddle(w_Draw_Paddle_Bot),
    .o_Paddle_Y(w_Paddle_Y_Bot)
  );
 
  // Instantiation of Ball Control + Draw
  Pong_Ball_Ctrl Pong_Ball_Ctrl_Inst
    (.clk(divided_clk),
     .i_Paddle_Y_1(w_Paddle_Y_P1),
     .i_Paddle_Y_2(w_Paddle_Y_Bot),
     .i_Game_Active(w_Game_Active),
     .i_Col_Count_Div(w_Col_Count_Div),
     .i_Row_Count_Div(w_Row_Count_Div),
     .o_Draw_Ball(w_Draw_Ball),
     .o_Ball_X(w_Ball_X),
     .o_Ball_Y(w_Ball_Y));
 
 
  // Create a state machine to control the state of play
  always @(posedge divided_clk)
  begin
    case (r_SM_Main)
 
    // Stay in this state until Game Start button is hit
    IDLE :
    begin
      if (enter_i == 1'b1)
        r_SM_Main <= RUNNING;
    end
 
    // Stay in this state until either player misses the ball
    // can only occur when the Ball is at 0 to c_GAME_WIDTH-1
    RUNNING :
    begin
      // Player 1 Side
      if (w_Ball_X == 0 && 
          (w_Ball_Y < w_Paddle_Y_P1 || 
           w_Ball_Y > w_Paddle_Y_P1 + c_PADDLE_HEIGHT))
        r_SM_Main <= Bot;
 
      // Bot Side
      else if (w_Ball_X == c_GAME_WIDTH-1 && 
               (w_Ball_Y < w_Paddle_Y_Bot ||
                w_Ball_Y > w_Paddle_Y_Bot  + c_PADDLE_HEIGHT))
        r_SM_Main <= P1_WINS;
    end
 
    P1_WINS :
    begin
      if (r_P1_Score == c_SCORE_LIMIT-1)
        r_P1_Score <= 0;
      else
      begin
        r_P1_Score <= r_P1_Score + 1;
        r_SM_Main <= CLEANUP;
      end
    end
 
    Bot :
    begin
      if (r_Bot_Score == c_SCORE_LIMIT-1)
        r_Bot_Score <= 0;
      else
      begin
        r_Bot_Score <= r_Bot_Score + 1;
        r_SM_Main <= CLEANUP;
      end
    end
 
    CLEANUP :
      r_SM_Main <= IDLE;
 
    endcase
  end
 
  // Conditional Assignment based on State Machine state
  assign w_Game_Active = (r_SM_Main == RUNNING) ? 1'b1 : 1'b0;
 
  assign w_Draw_Any = w_Draw_Ball | w_Draw_Paddle_P1 | w_Draw_Paddle_Bot;
 
  // Assign colors. Currently set to only 2 colors, white or black.
  assign o_Red_Video = w_Draw_Any ? 4'b1111 : 4'b0000;
  assign o_Grn_Video = w_Draw_Any ? 4'b1111 : 4'b0000;
  assign o_Blu_Video = w_Draw_Any ? 4'b1111 : 4'b0000;
 
endmodule // Pong_Top