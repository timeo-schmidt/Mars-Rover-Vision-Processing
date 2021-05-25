module PIXEL_PROC(
    input               clk,
    input               rst,
    input       [23:0]  pixel_in,               // The raw concatenated 8-bit RGB channels --> IN
    output reg  [2:0]   pixel_classification    // 0:unclassified | 1:red ball | 2:yellow ball | 3:green ball | 4:blue ball | 5:pink ball
);


////// CONFIGURATION //////

// Here are the accepted HSV colour space ranges for the ping-pong balls

/*
|0=========================180=========================360|
| red .... yellow .... green .... blue .... pink .... red |
|=========================================================|
*/


// later: parameterise the colour ranges

// Red
// 0-30; 330-359

// Green
// 160-180

// Blue
// 200-250

// Pink
// 270-330

// Yellow
// 50-70

// Saturation threshold
// 60-100

// Value threshold
// 50-100

////////////////////////////

// Separate wires for the R-G-B colour channels
wire [7:0]   red, green, blue;
assign {red,green,blue} = pixel_in;

wire [8:0] hsv_h;
wire [7:0] hsv_s, hsv_v;

always @(*) begin
    if(hsv_s>70 & hsv_v>50) begin
        // Red ball
        if(hsv_h < 30 | hsv_h > 330) begin
            pixel_classification <= 3'h1;
        end
        // Yellow ball
        if(hsv_h > 50 & hsv_h < 70) begin
            pixel_classification <= 3'h2;
        end
        // Green ball
        if(hsv_h > 160 & hsv_h < 180) begin
            pixel_classification <= 3'h3;
        end
        // Blue ball
        if(hsv_h > 200 & hsv_h < 250) begin
            pixel_classification <= 3'h4;
        end
        // Pink ball
        if(hsv_h > 270 & hsv_h < 330) begin
            pixel_classification <= 3'h5;
        end
    end
    else begin
        pixel_classification <= 3'h0;
    end
end


// Hardware to convert rgb to hsv color-space
// This hardware block outputs with 2 clock cycles delay
RGB_2_HSV rgb_2_hsv(
    .clk(clk),
    .rst(rst),
    .rgb_r(red),
    .rgb_g(green),
    .rgb_b(blue),
    .hsv_h(hsv_h),
    .hsv_s(hsv_s),
    .hsv_v(hsv_v)
);

endmodule
