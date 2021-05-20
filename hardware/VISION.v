module VISION(
    input [23:0] pixel_in,
    output [23:0] pixel_out
);


////// CONFIGURATION //////

// Red

// Green

// Blue

// Pink

// Yellow

/*

What are the possible algorithms for colour classification?
 X 1. Pixel Ranges + brightness dependent. More careful environment tuning required
 YES-> 2. Hue colour space conversion, then hue ranges, much simpler env. tuning

*/

///////////////////////////

// Separate wires for the R-G-B colour channels

wire [7:0]   red, green, blue, grey;
wire [7:0]   red_out, green_out, blue_out;

// Detect red areas
wire red_detect;
assign red_detect = red[7] & ~green[7] & ~blue[7];

// Find boundary of cursor box

// Highlight detected areas
wire [23:0] red_high;
assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4
assign red_high  =  red_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};

// Show bounding box
wire [23:0] new_image;
wire bb_active;
assign bb_active = (x == left) | (x == right) | (y == top) | (y == bottom);
assign new_image = bb_active ? bb_col : red_high;

// Switch output pixels depending on mode switch
// Don't modify the start-of-packet word - it's a packet discriptor
// Don't modify data in non-video packets
assign {red_out, green_out, blue_out} = (mode & ~sop & packet_video) ? new_image : {red,green,blue};
