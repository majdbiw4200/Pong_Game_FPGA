`timescale 1ps/1ps

//this module is the Top module
module Project10_Pong_Top
  (input  clk,       //100MHz Clock
 	 input RxD,        //Uart serial data input
   // VGA
   output o_VGA_HSync,
   output o_VGA_VSync,
   output o_VGA_Red_0,
   output o_VGA_Red_1,
   output o_VGA_Red_2,
   output o_VGA_Grn_0,
   output o_VGA_Grn_1,
   output o_VGA_Grn_2,
   output o_VGA_Blu_0,
   output o_VGA_Blu_1,
   output o_VGA_Blu_2   
   );
    
  // VGA Constants to set Frame Size
  parameter c_VIDEO_WIDTH = 3;
  parameter c_TOTAL_COLS  = 800;
  parameter c_TOTAL_ROWS  = 525;
  parameter c_ACTIVE_COLS = 640;
  parameter c_ACTIVE_ROWS = 480;
     
  // Common VGA Signals
  wire [c_VIDEO_WIDTH-1:0] w_Red_Video_Pong, w_Red_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_Pong, w_Grn_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_Pong, w_Blu_Video_Porch;
  wire divided_clk;
  wire enter_i;

  clock_divider clock_wrapper(           //25MHz clock
    .clk(clk),.divided_clk(divided_clk));
   
    
  // Generates Sync Pulses to run VGA
  VGA_Sync_Pulses #(.TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS)) VGA_Sync_Pulses_Inst 
  (.clk(divided_clk),
   .o_HSync(w_HSync_VGA),
   .o_VSync(w_VSync_VGA),
   .o_Col_Count(),
   .o_Row_Count()
  );
   
   
   
  Pong_Top #(.c_TOTAL_COLS(c_TOTAL_COLS),
             .c_TOTAL_ROWS(c_TOTAL_ROWS),
             .c_ACTIVE_COLS(c_ACTIVE_COLS),
             .c_ACTIVE_ROWS(c_ACTIVE_ROWS)) Pong_Inst
  (.clk(clk),
   .RxD(RxD),
   .enter_i(enter_i),
   .i_HSync(w_HSync_VGA),
   .i_VSync(w_VSync_VGA),
   .o_HSync(w_HSync_Pong),
   .o_VSync(w_VSync_Pong),
   .o_Red_Video(w_Red_Video_Pong),
   .o_Grn_Video(w_Grn_Video_Pong),
   .o_Blu_Video(w_Blu_Video_Pong));
     
  VGA_Sync_Porch  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                    .TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS))
  VGA_Sync_Porch_Inst
   (.clk(divided_clk),
    .i_HSync(w_HSync_Pong),
    .i_VSync(w_VSync_Pong),
    .i_Red_Video(w_Red_Video_Pong),
    .i_Grn_Video(w_Grn_Video_Pong),
    .i_Blu_Video(w_Blu_Video_Pong),
    .o_HSync(o_VGA_HSync),
    .o_VSync(o_VGA_VSync),
    .o_Red_Video(w_Red_Video_Porch),
    .o_Grn_Video(w_Grn_Video_Porch),
    .o_Blu_Video(w_Blu_Video_Porch));
       
  assign o_VGA_Red_0 = w_Red_Video_Porch[0];
  assign o_VGA_Red_1 = w_Red_Video_Porch[1];
  assign o_VGA_Red_2 = w_Red_Video_Porch[2];
   
  assign o_VGA_Grn_0 = w_Grn_Video_Porch[0];
  assign o_VGA_Grn_1 = w_Grn_Video_Porch[1];
  assign o_VGA_Grn_2 = w_Grn_Video_Porch[2];
 
  assign o_VGA_Blu_0 = w_Blu_Video_Porch[0];
  assign o_VGA_Blu_1 = w_Blu_Video_Porch[1];
  assign o_VGA_Blu_2 = w_Blu_Video_Porch[2];
 
endmodule