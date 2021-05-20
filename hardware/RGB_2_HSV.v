module  RGB_2_HSV(
	input 						  clk,
	input	     [7:0]            rgb_r,
	input	     [7:0]            rgb_g,
	input	     [7:0]            rgb_b,
	output reg   [9:0]			  hsv_h,	// 0 - 360*511-1
	output reg   [7:0] 			  hsv_s,	// 0- 255
	output reg   [7:0] 			  hsv_v 	// 0- 255
);

wire[7:0] rgb_min = rgb_r < rgb_g ? (rgb_r < rgb_b ? rgb_r : rgb_b) : (rgb_g < rgb_b ? rgb_g : rgb_b);
wire[7:0] rgb_max = rgb_r > rgb_g ? (rgb_r > rgb_b ? rgb_r : rgb_b) : (rgb_g > rgb_b ? rgb_g : rgb_b);
wire [7:0] delta = rgb_max-rgb_min;

// Ignore greyscale achromatic case to simplify hardware

always@(posedge clk) begin

	if(rgb_r == rgb_max) begin
		hsv_h <= ((rgb_g-rgb_b)*43) / delta;
	end else if(rgb_r == rgb_max) begin
		hsv_h <= ((rgb_b-rgb_r)*43) / delta + 85;
	end else begin
		hsv_h <= ((rgb_r-rgb_g)*43) / delta + 171;
	end

	if(hsv_h[9]==1) begin
		$display("neg: ", hsv_h);
		hsv_h <= hsv_h+360;
		$display("neg+360: ", hsv_h+360);
	end

	hsv_s <= (256*delta-8) / rgb_max;
	hsv_v <= rgb_max;

end

endmodule
