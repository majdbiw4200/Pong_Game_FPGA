`timescale 1ns / 1ps

module receiver(

input clk, //100MHz clock
input RxD, //input receving data line
output [7:0]RxData // output for 8 bits data
// output [7:0]LED // output 8 LEDs
    );
    
//internal variables
reg shift; // shift signal to trigger shifting data
reg state, nextstate; // initial state and next state variable
reg [3:0] bitcounter; // 4 bits counter to count up to 9 for UART receiving
reg [1:0] samplecounter; // 2 bits sample counter to count up to 4 for oversampling
reg [13:0] counter; // 14 bits counter to count the baud rate
reg [9:0] rxshiftreg; //bit shifting register
reg clear_bitcounter,inc_bitcounter,inc_samplecounter,clear_samplecounter; //clear or increment the counter

// constants
parameter clk_freq = 100_000_000;  // system clock frequency
parameter baud_rate = 9_600; //baud rate
parameter div_sample = 4; //oversampling
parameter div_counter = clk_freq/(baud_rate*div_sample);  // this is the number we have to divide the system clock frequency to get a frequency (div_sample) time higher than (baud_rate)
parameter mid_sample = (div_sample/2);  // this is the middle point of a bit where you want to sample it
parameter div_bit = 10; // 1 start, 8 data, 1 stop


assign RxData = rxshiftreg [8:1]; // assign the RxData from the shiftregister

//UART receiver logic
always @ (posedge clk)
    begin 
        counter <= counter +1; // start count in the counter
        if (counter >= div_counter-1) begin // if counter reach the baud rate with sampling 
             counter <=0; //reset the counter
            state <= nextstate; // assign the state to nextstate
            if (shift)rxshiftreg <= {RxD,rxshiftreg[9:1]}; //if shift asserted, load the receiving data
            if (clear_samplecounter) samplecounter <=0; // if clear sampl counter asserted, reset sample counter
            if (inc_samplecounter) samplecounter <= samplecounter +1; //if increment counter asserted, start sample count
            if (clear_bitcounter) bitcounter <=0; // if clear bit counter asserted, reset bit counter
            if (inc_bitcounter)bitcounter <= bitcounter +1; // if increment bit counter asserted, start count bit counter
        end
    end
   
//state machine

always @ (posedge clk) //trigger by clock
begin 
    shift <= 0; // set shift to 0 to avoid any shifting 
    clear_samplecounter <=0; // set clear sample counter to 0 to avoid reset
    inc_samplecounter <=0; // set increment sample counter to 0 to avoid any increment
    clear_bitcounter <=0; // set clear bit counter to 0 to avoid claring
    inc_bitcounter <=0; // set increment bit counter to avoid any count
    nextstate <=0; // set next state to be idle state
    case (state)
        0: begin // idle state
            if (RxD) // if input RxD data line asserted
              begin
              nextstate <=0; // back to idle state because RxD needs to be low to start transmission    
              end
            else begin // if input RxD data line is not asserted
                nextstate <=1; //jump to receiving state 
                clear_bitcounter <=1; // trigger to clear bit counter
                clear_samplecounter <=1; // trigger to clear sample counter
            end
        end
        1: begin // receiving state
            nextstate <= 1; // DEFAULT 
            if (samplecounter== mid_sample - 1) shift <= 1; // if sample counter is 1, trigger shift 
                if (samplecounter== div_sample - 1) begin // if sample counter is 3 as the sample rate used is 3
                    if (bitcounter == div_bit - 1) begin // check if bit counter if 9 or not
                nextstate <= 0; // back to idle state if bit counter is 9 as receving is complete
                end 
                inc_bitcounter <=1; // trigger the increment bit counter if bit counter is not 9
                clear_samplecounter <=1; //trigger the sample counter to reset the sample counter
            end else inc_samplecounter <=1; // if sample is not equal to 3, keep counting
        end
       default: nextstate <=0; //default idle state
     endcase
end         
endmodule
