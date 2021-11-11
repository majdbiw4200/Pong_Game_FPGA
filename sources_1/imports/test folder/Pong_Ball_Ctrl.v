`timescale 1ps/1ps
//this module is used to drow the ball and control how it moves and
//interact with the environment like paddles and such
module Pong_Ball_Ctrl 
  #(parameter c_GAME_WIDTH=40, 
    parameter c_GAME_HEIGHT=30,
    parameter c_PADDLE_HEIGHT = 6) 
  (input            clk,             //25Mhz clk
   input            i_Game_Active,   //To check whether the enter key is pressed or not
   input [5:0]      i_Col_Count_Div, //number of Columns after divition
   input [5:0]      i_Row_Count_Div, //number of Rows after divition
   input [5:0]      i_Paddle_Y_1,    //the paddle on the left postion
   input [5:0]      i_Paddle_Y_2,    //the paddle on the right postion
   output reg       o_Draw_Ball,     //signal to drow the ball
   output reg [5:0] o_Ball_X = 0,    //register to save the ball postion value on the X axies
   output reg [5:0] o_Ball_Y = 0);   //register to save the ball postion value on the Y axies
 
  // Set the Speed of the ball movement.
  // In this case, the ball will move one board game unit 
  // every 50 milliseconds that the button is held down.   
  parameter c_BALL_SPEED = 1250000;
  parameter c_SCORE_LIMIT = 9;
 
  reg [5:0]  r_Ball_X_Prev = 0;  //register to save the ball previous postion value on the X axies 
  reg [5:0]  r_Ball_Y_Prev = 0;  //register to save the ball previous postion value on the Y axies    
  reg [31:0] r_Ball_Count = 0;   //register to set the ball speed
  reg [5:0]  r_Paddle_Y_1 = 0;   //register used to get the left paddle down edge
  reg [5:0]  r_Paddle_Y_2 = 0;   //register used to get the right paddle down edge
  reg [5:0]  r_Paddle_middle_1 = 0;  //register used to get the left paddle middle point
  reg [5:0]  r_Paddle_middle_2 = 0;  //register used to get the right paddle middle point
  reg [5:0]  r_Paddle_middle_1_plus = 0; //register used to get the left paddle second middle point if the paddle hight is binary
  reg [5:0]  r_Paddle_middle_2_plus = 0; //register used to get the right paddle second middle point if the paddle hight is binary
  reg [3:0]  Ball =0; //register for state machine
  reg [3:0] r_P1_Score = 0;  //player 1 score count
  reg [3:0] r_Bot_Score = 0; //player 2/bot score count

  reg [3:0]  game_not_active = 4'b0000; //state for when the game is not active
  reg [3:0]  game_active     = 4'b0001; //state for when the game is running
  reg [3:0]  paddle_edge_1   = 4'b0010; //state for when the ball hits the edge of the paddle on the left
  reg [3:0]  paddle_edge_2   = 4'b0011; //state for when the ball hits the edge of the paddle on the right
  reg [3:0]  paddle_middle   = 4'b0100; //state for when the ball hits the middle of the paddles
  reg [3:0]  paddle_normal   = 4'b0101; //this state is not used for now
  reg [3:0]  player_1_goal   = 4'b0110; //state when the player one scores a goal
  reg [3:0]  player_2_goal   = 4'b0111; //state when the player two/bot scores a goal
  reg [3:0]  reset_game      = 4'b1000; //state after one of the players score a goal
  //start of the state machine
  always @(posedge clk)
  begin
    case (Ball)
    // If the game is not active, ball stays in the middle of
    // screen until the game starts.
    game_not_active :
     if (i_Game_Active == 1'b0)
     begin
       o_Ball_X      <= c_GAME_WIDTH/2;
       o_Ball_Y      <= c_GAME_HEIGHT/2;
       r_Ball_X_Prev <= c_GAME_WIDTH/2 + 1;
       r_Ball_Y_Prev <= c_GAME_HEIGHT/2 - 1;
     end
     else if (i_Game_Active == 1'b1)
     Ball <= game_active;

    //if the enter key is pressed the game starts game_active is the start state
    game_active :
    // Update the ball counter continuously.  Ball movement
    // update rate is determined by input parameter
    // If ball counter is at its limit, update the ball position
    // in both X and Y.
    begin
      if (r_Ball_Count < c_BALL_SPEED)      
        r_Ball_Count <= r_Ball_Count + 1;
      else
      begin
        r_Ball_Count <= 0;
        r_Paddle_Y_1 <= i_Paddle_Y_1 + 6;  //setting the register to the down edge of the left paddle
        r_Paddle_Y_2 <= i_Paddle_Y_2 + 6;  //setting the register to the down edge of the right paddle
        r_Paddle_middle_1 <= i_Paddle_Y_1 + 2;  //setting paddle mid points
        r_Paddle_middle_2 <= i_Paddle_Y_1 + 2;  
        r_Paddle_middle_1_plus <= i_Paddle_Y_1 + 3;
        r_Paddle_middle_2_plus <= i_Paddle_Y_2 + 3;
 
        // Store Previous Location to keep track of movement
        r_Ball_X_Prev <= o_Ball_X;
        r_Ball_Y_Prev <= o_Ball_Y;
 
        // When Previous Value is less than current value, ball is moving
        // to right.  Keep it moving to the right unless we are at wall.
        // When Prevous value is greater than current value, ball is moving
        // to left.  Keep it moving to the left unless we are at a wall.
        // Same philosophy for both X and Y.
        if ((r_Ball_X_Prev < o_Ball_X && o_Ball_X == c_GAME_WIDTH-1) ||
            (r_Ball_X_Prev > o_Ball_X && o_Ball_X != 0))
          o_Ball_X <= o_Ball_X - 1;
        else
          o_Ball_X <= o_Ball_X + 1;
 
        if ((r_Ball_Y_Prev < o_Ball_Y && o_Ball_Y == c_GAME_HEIGHT-1) ||
            (r_Ball_Y_Prev > o_Ball_Y && o_Ball_Y != 0 ))
          o_Ball_Y <= o_Ball_Y - 1;
        else
          o_Ball_Y <= o_Ball_Y + 1;

        //here we check where the ball is going to hit next
        //the first if checks if the ball hit any of the left paddle edges
        if ((o_Ball_Y == i_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y == r_Paddle_Y_1 && o_Ball_X == 0) )
            Ball <= paddle_edge_1;
        //this else if checks if the ball hit any of the right paddle edges
        else if ((o_Ball_Y == i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                (o_Ball_Y == r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) )
                 Ball <= paddle_edge_2;
        //this else if checks if the ball hit any of the paddles mid points
        else if ((o_Ball_Y == r_Paddle_middle_1 && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                 (o_Ball_Y == r_Paddle_middle_1_plus && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2_plus && o_Ball_X == c_GAME_WIDTH-1))
                Ball <= paddle_middle;
        //if non of the upove is right that means the ball hit either the 0 value of
        //the X axies which means that player2/bot scored or it did hit the max value
        //of the X axies which means that player1 scored or it hit the in between
        //values of the paddles which means the ball will keep it previous state
        else
        Ball <= game_active;
        //this if checks if the ball hit the 0 value of the X axies which means
        //it checks if player2/bot scored
        if (o_Ball_X == 0 && 
                (o_Ball_Y < i_Paddle_Y_1 || 
                o_Ball_Y > r_Paddle_Y_1))
                Ball <= player_2_goal;
        //this if checks if the ball hit the max value of the X axies which means
        //it checks if player1/bot scored
        if (o_Ball_X == c_GAME_WIDTH-1 && 
                (o_Ball_Y < i_Paddle_Y_2 ||
                o_Ball_Y > r_Paddle_Y_2))
                Ball <= player_1_goal;
      end
    end

    //when ball hit the edges of the left paddle
    //most of the code is the same as the previous state
    paddle_edge_1:
    begin
      if (r_Ball_Count < c_BALL_SPEED)
        r_Ball_Count <= r_Ball_Count + 1;
      else
      begin
        r_Ball_Count <= 0;
        r_Paddle_Y_1 <= i_Paddle_Y_1 + 6;
        r_Paddle_Y_2 <= i_Paddle_Y_2 + 6;
        r_Paddle_middle_1 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_2 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_1_plus <= i_Paddle_Y_1 + 3;
        r_Paddle_middle_2_plus <= i_Paddle_Y_2 + 3;
 
        
        r_Ball_X_Prev <= o_Ball_X;
        r_Ball_Y_Prev <= o_Ball_Y;

        if ((r_Ball_X_Prev < o_Ball_X && o_Ball_X == c_GAME_WIDTH-1) ||
            (r_Ball_X_Prev > o_Ball_X && o_Ball_X != 0))
          o_Ball_X <= o_Ball_X - 1;
        else
          o_Ball_X <= o_Ball_X + 1;
 
        if ((r_Ball_Y_Prev < o_Ball_Y &&
            (o_Ball_Y == c_GAME_HEIGHT-2 || o_Ball_Y == c_GAME_HEIGHT-1)) ||
            (r_Ball_Y_Prev > o_Ball_Y && o_Ball_Y != 0) )
          o_Ball_Y <= o_Ball_Y - 2;
        else
          o_Ball_Y <= o_Ball_Y + 2;
        //this if statement checks if the ball hit the paddle in the in between values
        //basically it checks if the value is not the middle of the paddle nethier is
        //the edges of the paddle
        if ((o_Ball_Y != i_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y != r_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y != i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
            (o_Ball_Y != r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
            (o_Ball_Y != r_Paddle_middle_1 && o_Ball_X == 0) ||
            (o_Ball_Y != r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1))
            Ball <= game_active;
        else if ((o_Ball_Y == i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                (o_Ball_Y == r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) )
                 Ball <= paddle_edge_2;
        else if ((o_Ball_Y == r_Paddle_middle_1 && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                 (o_Ball_Y == r_Paddle_middle_1_plus && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2_plus && o_Ball_X == c_GAME_WIDTH-1))
                Ball <= paddle_middle;
        //stays at the same state if non of the upove is true
        else
        Ball <= paddle_edge_1;

        if (o_Ball_X == 0 && 
                (o_Ball_Y < i_Paddle_Y_1 || 
                o_Ball_Y > r_Paddle_Y_1))
                Ball <= player_2_goal;
        if (o_Ball_X == c_GAME_WIDTH-1 && 
                (o_Ball_Y < i_Paddle_Y_2 ||
                o_Ball_Y > r_Paddle_Y_2))
                Ball <= player_1_goal;
      end
    end
    

    //when ball hit the edges of the right paddle
    //most of the code is the same as the previous state
    paddle_edge_2:
    begin
      if (r_Ball_Count < c_BALL_SPEED)
        r_Ball_Count <= r_Ball_Count + 1;
      else
      begin
        r_Ball_Count <= 0;
        r_Paddle_Y_1 <= i_Paddle_Y_1 + 6;
        r_Paddle_Y_2 <= i_Paddle_Y_2 + 6;
        r_Paddle_middle_1 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_2 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_1_plus <= i_Paddle_Y_1 + 3;
        r_Paddle_middle_2_plus <= i_Paddle_Y_2 + 3;
 
        // Store Previous Location to keep track of movement
        r_Ball_X_Prev <= o_Ball_X;
        r_Ball_Y_Prev <= o_Ball_Y;

        if ((r_Ball_X_Prev < o_Ball_X && o_Ball_X == c_GAME_WIDTH-1) ||
            (r_Ball_X_Prev > o_Ball_X && o_Ball_X != 0))
          o_Ball_X <= o_Ball_X - 1;
        else
          o_Ball_X <= o_Ball_X + 1;
 
        if ((r_Ball_Y_Prev < o_Ball_Y &&
            (o_Ball_Y == c_GAME_HEIGHT-2 || o_Ball_Y == c_GAME_HEIGHT-1)) ||
            (r_Ball_Y_Prev > o_Ball_Y && o_Ball_Y != 0) )
          o_Ball_Y <= o_Ball_Y - 2;
        else
          o_Ball_Y <= o_Ball_Y + 2;

        if ((o_Ball_Y != i_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y != r_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y != i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
            (o_Ball_Y != r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
            (o_Ball_Y != r_Paddle_middle_1 && o_Ball_X == 0) ||
            (o_Ball_Y != r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1))
            Ball <= game_active;
        else if ((o_Ball_Y == i_Paddle_Y_1 && o_Ball_X == 0) ||
                (o_Ball_Y == r_Paddle_Y_1 && o_Ball_X == 0) )
                Ball <= paddle_edge_1;
        else if ((o_Ball_Y == r_Paddle_middle_1 && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                 (o_Ball_Y == r_Paddle_middle_1_plus && o_Ball_X == 0) ||
                 (o_Ball_Y == r_Paddle_middle_2_plus && o_Ball_X == c_GAME_WIDTH-1))
                Ball <= paddle_middle;
        else
        Ball <= paddle_edge_2;

        if (o_Ball_X == 0 && 
                (o_Ball_Y < i_Paddle_Y_1 || 
                o_Ball_Y > r_Paddle_Y_1))
                Ball <= player_2_goal;
        if (o_Ball_X == c_GAME_WIDTH-1 && 
                (o_Ball_Y < i_Paddle_Y_2 ||
                o_Ball_Y > r_Paddle_Y_2))
                Ball <= player_1_goal;
      end
    end

    //when ball hit the middle of paddle 1 or paddle 2
    paddle_middle:
    begin
      if (r_Ball_Count < c_BALL_SPEED)
        r_Ball_Count <= r_Ball_Count + 1;
      else
      begin
        r_Ball_Count <= 0;
        r_Paddle_Y_1 <= i_Paddle_Y_1 + 6;
        r_Paddle_Y_2 <= i_Paddle_Y_2 + 6;
        r_Paddle_middle_1 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_2 <= i_Paddle_Y_1 + 2;
        r_Paddle_middle_1_plus <= i_Paddle_Y_1 + 3;
        r_Paddle_middle_2_plus <= i_Paddle_Y_2 + 3;
 
        
        r_Ball_X_Prev <= o_Ball_X;
        r_Ball_Y_Prev <= o_Ball_Y;
 
        //moves only in the X axies when the ball hits the middle of the paddle
        if ((r_Ball_X_Prev < o_Ball_X && o_Ball_X == c_GAME_WIDTH-1) ||
            (r_Ball_X_Prev > o_Ball_X && o_Ball_X != 0))
          o_Ball_X <= o_Ball_X - 1;
        else
          o_Ball_X <= o_Ball_X + 1;
 
        
        if ((o_Ball_Y == i_Paddle_Y_1 && o_Ball_X == 0) ||
            (o_Ball_Y == r_Paddle_Y_1 && o_Ball_X == 0) )
            Ball <= paddle_edge_1;
        else if ((o_Ball_Y == i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                (o_Ball_Y == r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) )
                 Ball <= paddle_edge_2;
        else if ((o_Ball_Y != i_Paddle_Y_1 && o_Ball_X == 0) ||
                (o_Ball_Y != r_Paddle_Y_1 && o_Ball_X == 0) ||
                (o_Ball_Y != i_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                (o_Ball_Y != r_Paddle_Y_2 && o_Ball_X == c_GAME_WIDTH-1) ||
                (o_Ball_Y != r_Paddle_middle_1 && o_Ball_X == 0) ||
                (o_Ball_Y != r_Paddle_middle_2 && o_Ball_X == c_GAME_WIDTH-1))
                Ball <= game_active;
        else
        Ball <= paddle_middle;
        
        if (o_Ball_X == 0 && 
                (o_Ball_Y < i_Paddle_Y_1 || 
                o_Ball_Y > r_Paddle_Y_1))
                Ball <= player_2_goal;
        if (o_Ball_X == c_GAME_WIDTH-1 && 
                (o_Ball_Y < i_Paddle_Y_2 ||
                o_Ball_Y > r_Paddle_Y_2))
                Ball <= player_1_goal;
      end
    end
    // when player1 gets a goal
    player_1_goal:
    begin
      if (r_P1_Score == c_SCORE_LIMIT-1) //checks if player1 won
        r_P1_Score <= 0;
      else
      begin
        r_P1_Score <= r_P1_Score + 1;    //adds a one the the player1 score
        Ball <= reset_game;              //after the a goal goes to reset state
      end
    end
    // when player2/bot gets a goal
    player_2_goal:
    begin
      if (r_Bot_Score == c_SCORE_LIMIT-1) //checks if player2/bot won
        r_Bot_Score <= 0;
      else
      begin 
        r_Bot_Score <= r_Bot_Score + 1;   //adds a one the the player2/bot score
        Ball <= reset_game;               //after the a goal goes to reset state
      end
    end
    //this state is to get the ball and paddles to the starting postion
    reset_game:
      Ball <= game_not_active;
    endcase
  end // always @ (posedge clk)
 
 
  // Draws a ball at the location determined by X and Y indexes.
  always @(posedge clk)
  begin
    if (i_Col_Count_Div == o_Ball_X && i_Row_Count_Div == o_Ball_Y)
      o_Draw_Ball <= 1'b1;
    else
      o_Draw_Ball <= 1'b0;
  end
 
 
endmodule // Pong_Ball_Ctrl