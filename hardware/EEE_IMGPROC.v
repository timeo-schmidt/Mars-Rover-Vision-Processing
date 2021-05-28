//nios2-download C:\Users\Kunststoffe\Desktop\EEE2Rover-master\DE10_LITE_D8M_VIP_16\software\D8M_Camera_Test\D8M_Camera_Test.elf -c 1 -g

module EEE_IMGPROC(
	// global clock & reset
	clk,
	reset_n,

	// mm slave
	s_chipselect,
	s_read,
	s_write,
	s_readdata,
	s_writedata,
	s_address,

	// stream sink
	sink_data,
	sink_valid,
	sink_ready,
	sink_sop,
	sink_eop,

	// streaming source
	source_data,
	source_valid,
	source_ready,
	source_sop,
	source_eop,

	// conduit
	mode

);


// global clock & reset
input	clk;
input	reset_n;

// mm slave
input							s_chipselect;
input							s_read;
input							s_write;
output	reg	[31:0]				s_readdata;
input	[31:0]					s_writedata;
input	[2:0]					s_address;


// streaming sink
input	[23:0]            		sink_data;
input							sink_valid;
output							sink_ready;
input							sink_sop;
input							sink_eop;

// streaming source
output	[23:0]			  	   	source_data;
output							source_valid;
input							source_ready;
output							source_sop;
output							source_eop;

// conduit export
input                         	mode;

////////////////////////////////////////////////////////////////////////
parameter IMAGE_W = 11'd640;
parameter IMAGE_H = 11'd480;
parameter MESSAGE_BUF_MAX = 256;
parameter MSG_INTERVAL = 6;
parameter BB_COL_DEFAULT = 24'h00ff00;
wire [107:0] classifier_config;
assign classifier_config = {9'd70,9'd50,9'd30,9'd330,9'd50,9'd70,9'd160,9'd180,9'd200,9'd250,9'd270,9'd330};


wire [7:0]   red, green, blue; //, grey;
wire [7:0]   red_out, green_out, blue_out;

wire         sop, eop, in_valid, out_ready;


// Pixel Classification and Bounding-Box Drawing

// Pixel colour classification
reg [2:0] pixel_classification;
PIXEL_PROC m(
	.clk(clk),
	.rst(reset_n),
	.classifier_config(classifier_config),
	.pixel_in({red,green,blue}),
	.pixel_classification(pixel_classification)
);

// Colorisation
reg [23:0] colorised_image;
always@(*) begin
	case(pixel_classification)
		3'h0: begin
			colorised_image=24'h000000;
		end
		3'h1: begin
			colorised_image=24'hff0000;
		end
		3'h2: begin
			colorised_image=24'hffff00;
		end
		3'h3: begin
			colorised_image=24'h00ff00;
		end
		3'h4: begin
			colorised_image=24'h0000ff;
		end
		3'h5: begin
			colorised_image=24'hff00ff;
		end
	endcase
end


// Create the image overlay with the bounding boxes
// reg [23:0] overlayed_image;
// always@(*) begin
// 	// Yellow
// 	if((x == left_yellow) | (x == right_yellow) | (y == top_yellow) | (y == bottom_yellow)) begin
// 		overlayed_image <= 24'hffff00;
// 	end
// 	// Green
// 	else if((x == left_green) | (x == right_green) | (y == top_green) | (y == bottom_green)) begin
// 		overlayed_image <= 24'h00ff00;
// 	end
// 	// Blue
// 	else if((x == left) | (x == right) | (y == top) | (y == bottom)) begin
// 		overlayed_image <= 24'h0000ff;
// 	end
// 	// Pink
// 	else if((x == left_pink) | (x == right_pink) | (y == top_pink) | (y == bottom_pink)) begin
// 		overlayed_image <= 24'hff00ff;
// 	end
// 	// Red
// 	else if((x == left_red) | (x == right_red) | (y == top_red) | (y == bottom_red)) begin
// 		overlayed_image <= 24'hff0000;
// 	end
// 	// Display the original image, if no bounding box present on current pixel
// 	else begin
// 		overlayed_image <= {red,green,blue};
// 	end
// end

// Switch output pixels depending on mode switch
// Don't modify the start-of-packet word - it's a packet discriptor
// Don't modify data in non-video packets
assign {red_out, green_out, blue_out} = (mode & ~sop & packet_video) ? colorised_image : {red,green,blue};


//Count valid pixels to tget the image coordinates. Reset and detect packet type on Start of Packet.
reg [10:0] x, y;
reg packet_video;
always@(posedge clk) begin
	if (sop) begin
		x <= 11'h0;
		y <= 11'h0;
		packet_video <= (blue[3:0] == 3'h0);
	end
	else if (in_valid) begin
		if (x == IMAGE_W-1) begin
			x <= 11'h0;
			y <= y + 11'h1;
		end
		else begin
			x <= x + 11'h1;
		end
	end
end

//Find first and last red pixels
reg [10:0] x_min, y_min, x_max, y_max;

reg [10:0] x_min_red, 		y_min_red, 		x_max_red, 		y_max_red;
reg [10:0] x_min_yellow, 	y_min_yellow, 	x_max_yellow, 	y_max_yellow;
reg [10:0] x_min_green, 	y_min_green, 	x_max_green, 	y_max_green;
reg [10:0] x_min_blue, 		y_min_blue, 	x_max_blue, 	y_max_blue;
reg [10:0] x_min_pink, 		y_min_pink, 	x_max_pink, 	y_max_pink;

always@(posedge clk) begin
	if (in_valid) begin

		// Expand regions of found classified pixels for bounding boxes
		case(pixel_classification)
			3'h1: begin	// Red
				if (x < x_min_red) x_min_red <= x;
				if (x > x_max_red) x_max_red <= x;
				if (y < y_min_red) y_min_red <= y;
				y_max_red <= y;
			end
			3'h2: begin	// Yellow
				if (x < x_min_yellow) x_min_yellow <= x;
				if (x > x_max_yellow) x_max_yellow <= x;
				if (y < y_min_yellow) y_min_yellow <= y;
				y_max_yellow <= y;
			end
			3'h3: begin // Green
				if (x < x_min_green) x_min_green <= x;
				if (x > x_max_green) x_max_green <= x;
				if (y < y_min_green) y_min_green <= y;
				y_max_green <= y;
			end
			3'h4: begin // Blue
				if (x < x_min_blue) x_min_blue <= x;
				if (x > x_max_blue) x_max_blue <= x;
				if (y < y_min_blue) y_min_blue <= y;
				y_max_blue <= y;
			end
			3'h5: begin // Pink
				if (x < x_min_pink) x_min_pink <= x;
				if (x > x_max_pink) x_max_pink <= x;
				if (y < y_min_pink) y_min_pink <= y;
				y_max_pink <= y;
			end
		endcase
	end

	//Reset bounds on start of packet
	if (sop & in_valid) begin
		{x_min,x_min_red,x_min_yellow,x_min_green,x_min_blue,x_min_pink} <= IMAGE_W-11'h1;
		{x_max,x_max_red,x_max_yellow,x_max_green,x_max_blue,x_max_pink} <= 0;
		{y_min,y_min_red,y_min_yellow,y_min_green,y_min_blue,y_min_pink} <= IMAGE_H-11'h1;
		{y_max,y_max_red,y_max_yellow,y_max_green,y_max_blue,y_max_pink} <= 0;
	end
end

//Process bounding box at the end of the frame.
reg [1:0] msg_state;
reg [10:0] left, right, top, bottom;

reg [10:0] left_red, right_red, top_red, bottom_red;
reg [10:0] left_yellow, right_yellow, top_yellow, bottom_yellow;
reg [10:0] left_green, right_green, top_green, bottom_green;
reg [10:0] left_blue, right_blue, top_blue, bottom_blue;
reg [10:0] left_pink, right_pink, top_pink, bottom_pink;

reg [7:0] frame_count;
always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets

		// Red
		left_red <= x_min_red;
		right_red <= x_max_red;
		top_red <= y_min_red;
		bottom_red <= y_max_red;

		// Yellow
		left_yellow <= x_min_yellow;
		right_yellow <= x_max_yellow;
		top_yellow <= y_min_yellow;
		bottom_yellow <= y_max_yellow;

		// Green
		left_green <= x_min_green;
		right_green <= x_max_green;
		top_green <= y_min_green;
		bottom_green <= y_max_green;

		// Blue
		left_blue <= x_min_blue;
		right_blue <= x_max_blue;
		top_blue <= y_min_blue;
		bottom_blue <= y_max_blue;

		// Pink
		left_pink <= x_min_pink;
		right_pink <= x_max_pink;
		top_pink <= y_min_pink;
		bottom_pink <= y_max_pink;

		//Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
		frame_count <= frame_count - 1;

		if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX - 3) begin
			msg_state <= 2'b01;
			frame_count <= MSG_INTERVAL-1;
		end
	end

	//Cycle through message writer states once started
	if (msg_state != 2'b00) msg_state <= msg_state + 2'b01;

end

//Generate output messages for CPU
reg [31:0] msg_buf_in;
wire [31:0] msg_buf_out;
reg msg_buf_wr;
wire msg_buf_rd, msg_buf_flush;
wire [7:0] msg_buf_size;
wire msg_buf_empty;

`define RED_BOX_MSG_ID "RBB"

always@(*) begin	//Write words to FIFO as state machine advances
	case(msg_state)
		2'b00: begin
			msg_buf_in = 32'b0;
			msg_buf_wr = 1'b0;
		end
		2'b01: begin
			msg_buf_in = `RED_BOX_MSG_ID;	//Message ID
			msg_buf_wr = 1'b1;
		end
		2'b10: begin
			msg_buf_in = {5'b0, x_min, 5'b0, y_min};	//Top left coordinate
			msg_buf_wr = 1'b1;
		end
		2'b11: begin
			msg_buf_in = {5'b0, x_max, 5'b0, y_max}; //Bottom right coordinate
			msg_buf_wr = 1'b1;
		end
	endcase
end


//Output message FIFO
MSG_FIFO MSG_FIFO_inst (
	.clock (clk),
	.data (msg_buf_in),
	.rdreq (msg_buf_rd),
	.sclr (~reset_n | msg_buf_flush),
	.wrreq (msg_buf_wr),
	.q (msg_buf_out),
	.usedw (msg_buf_size),
	.empty (msg_buf_empty)
);


//Streaming registers to buffer video signal
STREAM_REG #(.DATA_WIDTH(26)) in_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(sink_ready),
	.valid_out(in_valid),
	.data_out({red,green,blue,sop,eop}),
	.ready_in(out_ready),
	.valid_in(sink_valid),
	.data_in({sink_data,sink_sop,sink_eop})
);

STREAM_REG #(.DATA_WIDTH(26)) out_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(out_ready),
	.valid_out(source_valid),
	.data_out({source_data,source_sop,source_eop}),
	.ready_in(source_ready),
	.valid_in(in_valid),
	.data_in({red_out, green_out, blue_out, sop, eop})
);


/////////////////////////////////
/// Memory-mapped port		 /////
/////////////////////////////////

// Addresses
`define REG_STATUS    			0
`define READ_MSG    			1
`define READ_ID    				2
`define REG_BBCOL				3

//Status register bits
// 31:16 - unimplemented
// 15:8 - number of words in message buffer (read only)
// 7:5 - unused
// 4 - flush message buffer (write only - read as 0)
// 3:0 - unused


// Process write

reg [7:0]   reg_status;
reg	[23:0]	bb_col;

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		reg_status <= 8'b0;
		bb_col <= BB_COL_DEFAULT;
	end
	else begin
		if(s_chipselect & s_write) begin
		   if      (s_address == `REG_STATUS)	reg_status <= s_writedata[7:0];
		   if      (s_address == `REG_BBCOL)	bb_col <= s_writedata[23:0];
		end
	end
end


//Flush the message buffer if 1 is written to status register bit 4
assign msg_buf_flush = (s_chipselect & s_write & (s_address == `REG_STATUS) & s_writedata[4]);


// Process reads
reg read_d; //Store the read signal for correct updating of the message buffer

// Copy the requested word to the output port when there is a read.
always @ (posedge clk)
begin
   if (~reset_n) begin
	   s_readdata <= {32'b0};
		read_d <= 1'b0;
	end

	else if (s_chipselect & s_read) begin
		if   (s_address == `REG_STATUS) s_readdata <= {16'b0,msg_buf_size,reg_status};
		if   (s_address == `READ_MSG) s_readdata <= {msg_buf_out};
		if   (s_address == `READ_ID) s_readdata <= 32'h1234EEE2;
		if   (s_address == `REG_BBCOL) s_readdata <= {8'h0, bb_col};
	end

	read_d <= s_read;
end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);



endmodule
