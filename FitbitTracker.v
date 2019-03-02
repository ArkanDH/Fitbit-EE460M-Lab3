`timescale 1ns / 1ps

module FitbitTracker(clk,pulse,reset,display,is_miles,SI);

input clk, pulse, reset;
output [15:0] display;  
output is_miles, SI;

reg second = 0;
reg under32 = 0;

reg [15:0] display_reg = 0;
reg is_miles_reg = 0;
reg SI_reg = 0;

reg [26:0] second_divider = 0;
reg display_change = 0;
reg [1:0] display_mode = 0;

reg [3:0] nine_seconds_counter = 0;
reg [7:0] steps_per_sec = 0;
reg [31:0] total_steps = 0;

reg [15:0] high_activity_counter = 0;
reg [15:0] displayed_high_activity_counter = 0;
reg [15:0] distance_traveled = 0;
reg [15:0] over32_time = 0;

assign display = display_reg;
assign is_miles = is_miles_reg;
assign SI = SI_reg;

/* 
Defines a second based on CLK
*/
always @(posedge clk) 
begin
    if(second_divider == 50000000) begin 
        second <= ~second;
        second_divider <= 0;
    end
    else
    second_divider <= second_divider + 1;
end

/* 
Updates total_steps and distance_traveled
*/
always @(posedge pulse, posedge reset) 
begin
    if(reset) 
        total_steps <= 0;
    else 
        total_steps <= total_steps + 1;
end

always @(*) begin
    distance_traveled = total_steps >> 10;
end

/*
Updates steps_per_sec
*/
always @(posedge pulse, posedge reset, posedge second) 
begin
    if(reset) 
        steps_per_sec <= 0;
    else 
        steps_per_sec <= steps_per_sec + 1;
end
/*
Handles how to Steps over 32/sec
*/
always @(posedge second, posedge reset)
begin
    if(reset) begin  
        over32_time <= 0;
        under32 <= 0;
        nine_seconds_counter <= 0;
    end
    else begin
        if(!(nine_seconds_counter >= 9 || under32)) begin
            if(steps_per_sec <= 32) begin  
                under32 <= 1;
            end
            else begin 
                over32_time <= over32_time + 1;
                nine_seconds_counter <= nine_seconds_counter + 1;
            end
        end
    end
end

/*
Handles high activity
*/
always @(posedge second) 
begin
    if(steps_per_sec >= 64) high_activity_counter <= high_activity_counter + 1;
    else begin
        if(high_activity_counter >= 60) begin 
            displayed_high_activity_counter <= displayed_high_activity_counter + high_activity_counter;
        end

        high_activity_counter <= 0;
    end
end

/*
Cycles display_modes
*/
always @(posedge second) begin
    
    if(display_change)
        display_mode <= display_mode + 1;
    display_change = ~display_change;
    
    //display_mode = 2;
end

/*
Controls what to output to the display
*/
always @(*) 
begin
    case (display_mode)
        0: begin
            if(total_steps > 9999) begin
                display_reg = 9999;
                SI_reg = 1;
            end
            else begin
                display_reg = total_steps;
                SI_reg = 0;
            end
            is_miles_reg = 0;
        end
        1: begin
            display_reg = distance_traveled;
            is_miles_reg = 1;
            SI_reg = 0;
        end
        2: begin    
            display_reg = over32_time;
            is_miles_reg = 0;
            SI_reg = 0;
        end
        3: begin
            display_reg = displayed_high_activity_counter;
            is_miles_reg = 0;
            SI_reg = 0;
        end
    endcase
end
endmodule
