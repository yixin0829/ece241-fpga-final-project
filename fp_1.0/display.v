// DEBUG Log: Now when change SW[9:7] the image will change instantly. This is caused by state keep looping in display_row and s_incr_y 
//					means the counters are constantly updating new pixel colour into VGA adpator. MAY NEED TO FIX, FOR NOW IT'S GOOD

module display
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY, SW,	// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input [9:0] SW;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 23-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [23:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 8;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	wire plot, rowCountEn, colCountEn, reset_sig_x, reset_sig_y, row_done, col_done;
	wire db_sw;
	wire [2:0] filter;
	
	datapath m0(.clock(CLOCK_50),
					.resetn(resetn),
					.rowCountEn(rowCountEn),
					.colCountEn(colCountEn),
					.plot_in(plot),
					.filter(filter),
					.db_sw(db_sw),
					.reset_sig_x(reset_sig_x),
					.reset_sig_y(reset_sig_y),
					.row_done(row_done),
					.col_done(col_done),
					.x_out(x),
					.y_out(y),
					.colour_out(colour),
					.plot_out(writeEn));
					
					
	ctrlpath m1(.clock(CLOCK_50),
					.resetn(resetn),
					.SW(SW[9:0]),
					.KEY(KEY[3:0]),
					.row_done(row_done),
					.col_done(col_done),
					.rowCountEn(rowCountEn),
					.colCountEn(colCountEn),
					.plot(plot),
					.reset_sig_x(reset_sig_x),
					.reset_sig_y(reset_sig_y),
					.filter(filter),
					.db_sw(db_sw));
					
	
endmodule



// Data Path module
module datapath(
	input clock, resetn,
	input rowCountEn,
	input colCountEn,
	input plot_in,
	input [2:0]filter, // SW[9:7]
	input db_sw,
	input reset_sig_x,
	input reset_sig_y,
	output reg row_done,
	output reg col_done,
	output [7:0]x_out,
	output [6:0]y_out,
	output [23:0]colour_out,
	output plot_out);
	
	reg [7:0]x;
	reg [6:0]y;
	wire [14:0]address;
	wire [23:0]ram_colour;
	
	
	// x-8bit counter
	always@(posedge clock)begin
		if(!resetn)begin
			x <= 8'd0;
			row_done = 1'b0;
		end 
		else if(x == 8'd160)begin 
			x <= 8'd0;
			row_done = 1'b1;
		end 
		else if(reset_sig_x)begin
			row_done = 1'b0;
		end
		else if(rowCountEn)begin
			x <= x + 1'b1;
		end
		else
			x <= x;
	end
	
	// y-7bit counter
	always@(posedge clock)begin
		if(!resetn)begin
			y <= 7'd0;
			col_done = 1'b0;
		end
		else if(y == 7'd120)begin 
			y <= 7'd0;
		end 
		else if(reset_sig_y)begin
			col_done = 1'b0;
		end
		else if(colCountEn)begin
			y <= y + 1'b1;
			col_done = 1'b1;
		end
		else
			y <= y;
			
	end
	
	assign address = y*160 + x;
	
	image_ram m0(.address(address), .clock(clock), .data(24'd0), .wren(1'b0), .q(ram_colour));
	image_process m1(.filter(filter), .colour_in(ram_colour), .db_sw(db_sw), .x(x), .y(y), .colour_out(colour_out), .clock(clock));
	
	
	// direct assignments
	assign x_out = x; 
	assign y_out = y; 
	assign plot_out = plot_in;
	
endmodule




// Control Path module
module ctrlpath(
	input clock, resetn,
	input [9:0]SW,
	input [3:0]KEY,
	input row_done, 
	input col_done, 
	output reg rowCountEn, 
	output reg colCountEn, 
	output reg plot,
	output reg reset_sig_x,
	output reg reset_sig_y,
	output [2:0]filter,
	output db_sw);
	
	
	reg [3:0] current_state, next_state;
	
	localparam S_IDLE = 4'd0, S_WAIT = 4'd1, S_DISPLAY_ROW = 4'd2, S_RESET_SIG_X = 4'd3, S_INCR_Y = 4'd4, S_RESET_SIG_Y = 4'd5;
	
	// State table
	always@(*)begin
		
		case(current_state)
			S_IDLE: next_state = KEY[1] ? S_IDLE : S_WAIT;
			S_WAIT: next_state = KEY[1] ? S_DISPLAY_ROW : S_WAIT;
			S_DISPLAY_ROW: next_state = row_done ? S_RESET_SIG_X : S_DISPLAY_ROW;
			S_RESET_SIG_X: next_state = S_INCR_Y;
			S_INCR_Y: next_state = col_done? S_RESET_SIG_Y : S_INCR_Y;
			S_RESET_SIG_Y: next_state = S_DISPLAY_ROW;
			default: next_state = S_IDLE;
		endcase
	end
	
	
	// Output logic
	always@(*)begin
		
		rowCountEn = 1'b0;
		colCountEn = 1'b0;
		plot = 1'b0;
		reset_sig_x = 1'b0;
		reset_sig_y = 1'b0;
		
		case(current_state)
		S_DISPLAY_ROW:begin
			rowCountEn = 1'b1;
			plot = 1'b1;
		end
		S_RESET_SIG_X:begin
			reset_sig_x = 1'b1;
		end
		S_RESET_SIG_Y:begin
			reset_sig_y = 1'b1;
		end
		S_INCR_Y:begin
			colCountEn = 1'b1;
		end
		endcase
	end
	
	
	
	// Direct assignment
	assign filter = SW[9:7];
	assign db_sw = SW[0];
	
	
	// current_state registers
    always@(posedge clock)
    begin
        if(!resetn)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end // state_FFS

endmodule





// Image processing module
// SW[9:7] filter option
module image_process(
	input [2:0]filter,
	input [23:0]colour_in,
	input db_sw, // SW[0]
	input clock,
	input [7:0]x,
	input [6:0]y,
	output reg[23:0]colour_out);
	
	
	// Filter options (USER MANUAL!) SW[9:7]
	localparam 
		ORIGIN = 3'd0, // 000
		INVERT = 3'd1, // 001
		R_FILTER = 3'd2, // 010
		G_FILTER = 3'd3, // 011
		B_FILTER = 3'd4, // 100
		GREY_SCALE = 3'd5, // 101
		CONTRAST = 3'd6, //110
		BLUR = 3'd7; // 111
	
	wire [23:0]colour_grey;
	wire [23:0]contrast;
	wire [23:0]blur;
	
	always@(*)begin
		case(filter[2:0])
			ORIGIN: colour_out = colour_in;
			INVERT: colour_out = ~colour_in;
			R_FILTER: colour_out = {colour_in[23:16], 16'd0};
			G_FILTER: colour_out = {8'd0, colour_in[15:8], 8'd0};
			B_FILTER: colour_out = {16'd0, colour_in[7:0]};
			GREY_SCALE: colour_out = colour_grey;
			BLUR: colour_out = blur;
			CONTRAST: colour_out = contrast;
		endcase
	end 
	

	
	grey_scale g0(.colour_in(colour_in), .colour_out(colour_grey));
	Contrast_add g1(.colour_in(colour_in), .bd_sw(db_sw), .colour_out(contrast));
	//gaussian_blur g3(.colour_in(colour_in), .clock(clock) ,.x(x), .y(y), .colour_out(blur));
	
	
endmodule



module grey_scale(
	input [23:0]colour_in,
	output [23:0]colour_out);
	
	wire [7:0]r_in, g_in, b_in;
	wire [7:0]r_out, g_out, b_out;
	
	assign r_in = colour_in[23:16];
	assign g_in = colour_in[15:8];
	assign b_in = colour_in[7:0];
	parameter c = 8'b0000_0111;//0.43504964;
	parameter e = 8'b0010_1011;//2.71828182;
   parameter sigmasq = 8'b0000_1011;//0.707106789;

	assign r_out   = c/((2)**(r_in*r_in/(2*sigmasq)));
	assign g_out = c/((2)**(g_in*g_in/(2*sigmasq)));
	assign b_out  = c/((2)**(b_in*b_in/(2*sigmasq)));
	assign  colour_out = {r_out, g_out, b_out};

endmodule


module  Contrast_add    (
    input [23:0]colour_in,
	 input bd_sw,
	 output [23:0]colour_out
	 );
	 
    parameter black = 0;
    parameter white = 255;
	parameter threshold = 126;
	parameter value1 = 50;
	
	wire [7:0]r_in, g_in, b_in;
	assign r_in = colour_in[23:16];
	assign g_in = colour_in[15:8];
	assign b_in = colour_in[7:0];
	
	
	reg [7:0]r_out, g_out, b_out;	
	reg [15:0] tempR1, tempG1, tempB1;
	
	
	
	
	always@(*)
	begin
	
	if(bd_sw)
	
begin
		tempR1 = r_in + value1;

	
	if (tempR1 > 255)
		r_out = white;
	else
		r_out = tempR1;
		
	if(bd_sw)
		tempG1 = g_in + value1;


	if (tempG1 > 255)
		g_out = white;
	else
		g_out = tempG1;
		
	if(bd_sw)
		tempB1 = b_in + value1;

	
	if (tempB1 > 255)
		b_out = white;
	else
		b_out = tempB1;
	end
	
	
	
	else if (!bd_sw)
	begin
	 
	tempR1 = r_in - value1;
	if (tempR1[8] == 1)
	r_out = 0;
	else
	r_out = tempR1;

	tempG1 = g_in - value1;
	if (tempG1[8] == 1)
	g_out = 0;
	else
	g_out = tempG1;

	tempB1 = b_in - value1;
	if (tempB1[8] == 1)
	b_out = 0;
	else
	b_out = tempB1;
	
	end
	end
	
	assign  colour_out = {r_out, g_out, b_out};
	
endmodule


//module gaussian_blur(
//	input clock,
//	input [23:0]colour_in,
//	input [7:0]x,
//	input [6:0]y,
//	output [23:0]colour_out);
//	
//	wire [7:0]
//		w0_r, w0_g, w0_b,
//		w1_r, w1_g, w1_b,
//		w2_r, w2_g, w2_b,
//		w3_r, w3_g, w3_b,
//		w4_r, w4_g, w4_b,
//		w5_r, w5_g, w5_b,
//		w6_r, w6_g, w6_b,
//		w7_r, w7_g, w7_b,
//		w8_r, w8_g, w8_b;
//	wire [31:0] red_s, green_s, blue_s;
//		
//	assign {w0_r, w0_g, w0_b} = colour_in;
//	image_ram m1(.address(y*160 + x+ 1), .clock(clock), .data(24'd0), .wren(1'b0), .q({w1_r, w1_g, w1_b}));
//	image_ram m2(.address(y*160 + x+ 2), .clock(clock), .data(24'd0), .wren(1'b0), .q({w2_r, w2_g, w2_b}));
//	image_ram m3(.address(y*160 + x+ 160), .clock(clock), .data(24'd0), .wren(1'b0), .q({w3_r, w3_g, w3_b}));
//	image_ram m4(.address(y*160 + x+ 161), .clock(clock), .data(24'd0), .wren(1'b0), .q({w4_r, w4_g, w4_b}));
//	image_ram m5(.address(y*160 + x+ 162), .clock(clock), .data(24'd0), .wren(1'b0), .q({w5_r, w5_g, w5_b}));
//	image_ram m6(.address(y*160 + x+ 320), .clock(clock), .data(24'd0), .wren(1'b0), .q({w6_r, w6_g, w6_b}));
//	image_ram m7(.address(y*160 + x+ 321), .clock(clock), .data(24'd0), .wren(1'b0), .q({w7_r, w7_g, w7_b}));
//	image_ram m8(.address(y*160 + x+ 322), .clock(clock), .data(24'd0), .wren(1'b0), .q({w8_r, w8_g, w8_b}));
//	
//	assign red_s = (w0_r + w1_r + w2_r + w3_r + w4_r + w5_r + w6_r + w7_r + w8_r);
//	assign green_s = (w0_g + w1_g + w2_g + w3_g + w4_g + w5_g + w6_g + w7_g + w8_g);
//	assign blue_s = (w0_b + w1_b + w2_b + w3_b + w4_b + w5_b + w6_b + w7_b + w8_b);
//	
//	assign colour_out[23:16] = red_s / 9;
//	assign colour_out[15:8] = green_s / 9;
//	assign colour_out[7:0] = blue_s / 9;
//	
//endmodule 


