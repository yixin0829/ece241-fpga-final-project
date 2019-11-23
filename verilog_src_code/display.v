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
	wire [2:0] filter;
	
	datapath m0(.clock(CLOCK_50),
					.resetn(resetn),
					.rowCountEn(rowCountEn),
					.colCountEn(colCountEn),
					.plot_in(plot),
					.filter(filter),
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
					.filter(filter));
					
	
endmodule



// Data Path module
module datapath(
	input clock, resetn,
	input rowCountEn,
	input colCountEn,
	input plot_in,
	input [2:0]filter, // SW[9:7]
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
		else if(x == 8'd159)begin 
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
		else if(y == 7'd119)begin 
			y <= 7'd0;
			col_done = 1'b1;
		end 
		else if(reset_sig_y)begin
			col_done = 1'b0;

		end
		else if(colCountEn)begin
			y <= y + 1'b1;
		end
		else
			y <= y;
			
	end
	
	assign address = y*160 + x;
	
	image_ram m0(.address(address), .clock(clock), .data(24'd0), .wren(1'b0), .q(ram_colour));
	image_process m1(.filter(filter), .colour_in(ram_colour), .colour_out(colour_out));
	
	
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
	output [2:0]filter);
	
	
	reg [2:0] current_state, next_state;
	
	localparam S_IDLE = 3'd0, S_WAIT = 3'd1, S_DISPLAY_ROW = 3'd2, S_RESET_SIG_X = 3'd3, S_INCR_Y = 3'd4, S_RESET_SIG_Y = 3'd5;
	
	// State table
	always@(*)begin
		
		case(current_state)
			S_IDLE: next_state = KEY[1] ? S_IDLE : S_WAIT;
			S_WAIT: next_state = KEY[1] ? S_DISPLAY_ROW : S_WAIT;
			S_DISPLAY_ROW: next_state = row_done ? S_RESET_SIG_X : S_DISPLAY_ROW;
			S_RESET_SIG_X: next_state = S_INCR_Y;
			S_INCR_Y: next_state = col_done? S_IDLE : S_DISPLAY_ROW;
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
		S_IDLE:begin
			reset_sig_x = 1'b1;
			reset_sig_y = 1'b1;
		end
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
	output reg[23:0]colour_out);
	
	
	// Filter options (USER MANUAL!) SW[9:7]
	localparam 
		ORIGIN = 3'd0, // 000
		INVERT = 3'd1, // 001
		R_FILTER = 3'd2, // 010
		G_FILTER = 3'd3, // 011
		B_FILTER = 3'd4, // 100
		GREY_SCALE = 3'd5, // 101
		BLACK = 3'd7; // 111
	
	wire [23:0]colour_grey;
	
	always@(*)begin
		case(filter[2:0])
			ORIGIN: colour_out = colour_in;
			INVERT: colour_out = ~colour_in;
			R_FILTER: colour_out = {colour_in[23:16], 16'd0};
			G_FILTER: colour_out = {8'd0, colour_in[15:8], 8'd0};
			B_FILTER: colour_out = {16'd0, colour_in[7:0]};
			GREY_SCALE: colour_out = colour_grey;
			BLACK: colour_out = 24'd0;
		endcase
	end 
	
	grey_scale g0(.colour_in(colour_in), .colour_out(colour_grey));

endmodule



module grey_scale(
	input [23:0]colour_in,
	output [23:0]colour_out);
	
	wire [7:0]r_in, g_in, b_in;
	wire [7:0]r_out, g_out, b_out;
	
	assign r_in = colour_in[23:16];
	assign g_in = colour_in[15:8];
	assign b_in = colour_in[7:0];
	
	assign r_out   = (r_in   != 0) ? (299*r_in/1000)+(587*g_in/1000)+(114*b_in/1000) : 0;
	assign g_out = (g_in != 0) ? (299*r_in/1000)+(587*g_in/1000)+(114*b_in/1000) : 0;
	assign b_out  = (b_in  != 0) ? (299*r_in/1000)+(587*g_in/1000)+(114*b_in/1000) : 0;
	
	assign  colour_out = {r_out, g_out, b_out};

endmodule


module test(
	input clock,
	input [9:0]SW,
	input [3:0]KEY,
	output [23:0]colour,
	output [7:0]x,
	output [6:0]y,
	output writeEn);
	
	wire plot, rowCountEn, colCountEn, reset_sig_x, reset_sig_y, row_done, col_done;
	wire [2:0]filter;
	wire resetn;
	assign resetn = KEY[0];
	
	
	datapath m0(.clock(clock),
					.resetn(resetn),
					.rowCountEn(rowCountEn),
					.colCountEn(colCountEn),
					.plot_in(plot),
					.filter(filter),
					.reset_sig_x(reset_sig_x),
					.reset_sig_y(reset_sig_y),
					.row_done(row_done),
					.col_done(col_done),
					.x_out(x),
					.y_out(y),
					.colour_out(colour),
					.plot_out(writeEn));
					
					
	ctrlpath m1(.clock(clock),
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
					.filter(filter));
					
	
	
	
endmodule





