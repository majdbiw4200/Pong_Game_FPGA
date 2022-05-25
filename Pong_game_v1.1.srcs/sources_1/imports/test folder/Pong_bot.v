`timescale 1ps/1ps

module Pong_Bot   #(parameter c_PLAYER_PADDLE_X=0,
    parameter c_PADDLE_HEIGHT=6,
    parameter c_GAME_WIDTH=40,
    parameter c_GAME_HEIGHT=30)
    (
    input [5:0] Ball_X,                //input to get the ball X axies postion
    input [5:0] Ball_Y,                //input to get the ball Y axies postion
    input clk,                         //25Mhz clock
    input [5:0]      i_Col_Count_Div,  //number of Columns after divition
    input [5:0]      i_Row_Count_Div,  //number of Rows after divition
    output reg       o_Draw_Paddle,    //signal to draw the paddle
    output reg [5:0] o_Paddle_Y        //register to keep track of the upper point/edge of the paddle
    );


    // Set the Speed of the paddle movement.  
    // In this case, the paddle will move one board game unit
    parameter c_PADDLE_SPEED = 250000;
 
    reg [31:0] r_Paddle_Count = 0;
 
    wire w_Paddle_Count_En;
    reg [5:0] o_Paddle_Y_2 =0;
 
    // enables the bot to function only if the ball is on thier side on the X axies
    assign w_Paddle_Count_En = Ball_X >= (c_GAME_WIDTH/2) + 1;
 
    always @(posedge clk)
    begin
        if (w_Paddle_Count_En == 1'b1)
        begin
        if (r_Paddle_Count == c_PADDLE_SPEED)
         r_Paddle_Count <= 0;
        else
            r_Paddle_Count <= r_Paddle_Count + 1;
        end
 
    //checks if the ball is on the bot side if not the bot wont move
    //if follows the ball movments right now its set so the bot chases
    //the ball to make sure it hits the second point of the paddle
    if (Ball_X >= 6'b010100 &&
        r_Paddle_Count == c_PADDLE_SPEED &&
        o_Paddle_Y !== 0)
      if (o_Paddle_Y_2 > Ball_Y)
         o_Paddle_Y <= o_Paddle_Y - 1;
        else if (o_Paddle_Y_2 < Ball_Y)
            o_Paddle_Y <= o_Paddle_Y + 1;
        else
         o_Paddle_Y <= o_Paddle_Y;
    else if (Ball_X >= 6'b010100 &&
        r_Paddle_Count == c_PADDLE_SPEED && 
        o_Paddle_Y !== c_GAME_HEIGHT-c_PADDLE_HEIGHT-1 &&
        o_Paddle_Y_2 !== 0)
      if (o_Paddle_Y_2 > Ball_Y)
         o_Paddle_Y <= o_Paddle_Y - 1;
        else if (o_Paddle_Y_2 < Ball_Y)
            o_Paddle_Y <= o_Paddle_Y + 1;
        else
         o_Paddle_Y <= o_Paddle_Y;
    end
 
 
    // Draws the Paddle
    always @(posedge clk)
    begin
        // Draws in a single column and in a range of rows.
        // Range of rows is determined by c_PADDLE_HEIGHT
        if (i_Col_Count_Div == c_PLAYER_PADDLE_X &&
            i_Row_Count_Div >= o_Paddle_Y_2 &&
            i_Row_Count_Div <= o_Paddle_Y_2 + c_PADDLE_HEIGHT) begin
            o_Draw_Paddle <= 1'b1;
            o_Paddle_Y_2  <= o_Paddle_Y+1;
            end
        else
            o_Draw_Paddle <= 1'b0;
    end    
 
endmodule // Pong_Paddle_Ctrl
