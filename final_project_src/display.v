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
	wire [8:0] x;
	wire [7:0] y;
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
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 8;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	wire plot, rowCountEn, colCountEn, reset_sig_x, reset_sig_y, row_done, col_done;
	wire ld_0, ld_1, ld_2, ld_3, ld_4, ld_5, ld_6, ld_7, ld_8;
	wire [2:0] sel_im;
	wire [4:0] filter;
	wire [3:0] sel_address;
	
	datapath2 m0(.clock(CLOCK_50),
					.resetn(resetn),
					.rowCountEn(rowCountEn),
					.colCountEn(colCountEn),
					.plot_in(plot),
					.filter(filter),
					.reset_sig_x(reset_sig_x),
					.reset_sig_y(reset_sig_y),
					.ld_0(ld_0),
					.ld_1(ld_1),
					.ld_2(ld_2),
					.ld_3(ld_3),
					.ld_4(ld_4),
					.ld_5(ld_5),
					.ld_6(ld_6),
					.ld_7(ld_7),
					.ld_8(ld_8),
					.sel_address(sel_address),
					.sel_im(sel_im),
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
					.ld_0(ld_0),
					.ld_1(ld_1),
					.ld_2(ld_2),
					.ld_3(ld_3),
					.ld_4(ld_4),
					.ld_5(ld_5),
					.ld_6(ld_6),
					.ld_7(ld_7),
					.ld_8(ld_8),
					.sel_address(sel_address),
					.sel_im(sel_im));
					
	
endmodule



/*
0 1 2
3 4 5
6 7 8
*/

// Data path2 for Guassian blur, Sobel edge detection
module datapath2(
	input clock, resetn,
	input rowCountEn,
	input colCountEn,
	input plot_in,
	input reset_sig_x,
	input reset_sig_y,
	input ld_0, ld_1, ld_2, ld_3, ld_4, ld_5, ld_6, ld_7, ld_8, // register enable signals
	input [2:0]sel_im,
	input [3:0]sel_address,
	input [4:0]filter,
	output reg row_done,
	output reg col_done,
	output [8:0]x_out,
	output [7:0]y_out,
	output [23:0]colour_out,
	output plot_out);
	
	reg [8:0]x;
	reg [7:0]y;
	wire [23:0]c0, c1, c2, c3, c4, c5, c6, c7, c8;
	wire [16:0]address;
	reg [23:0]ram_colour;
	wire [23:0]colour_im, colour_im2;
	wire [8:0]colour_mu;
	
	
	// x-8bit counter
	always@(posedge clock)begin
		if(!resetn)begin
			x <= 9'd1;
			row_done = 1'b0;
		end 
		else if(x == 9'd158)begin 
			x <= 9'd0;
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
			y <= 8'd1;
			col_done = 1'b0;
		end
		else if(y == 8'd118)begin 
			y <= 8'd0;
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
	
	
	
	//	input x, y count into the address_adaptor
	address_adaptor a0(.x(x), .y(y), .sel(sel_address), .address(address));
	
	// read the colour from the ram and store in ram_colour wire
	image_ram m0(.address(address), .clock(clock), .data(24'd0), .wren(1'b0), .q(colour_im));
	
	image2_ram m1(.address(address), .clock(clock), .data(24'd0), .wren(1'b0), .q(colour_im2));
	
	mu_ram m2(.address(address), .clock(clock), .data(24'd0), .wren(1'b0), .q(colour_mu));
	
	// case statement for select read colour from which RAMs
	always@(*)begin
		case(sel_im)
		3'd0: ram_colour = colour_im; //000
		3'd1: ram_colour = colour_im2; //001
		3'd2: ram_colour = {15'd0, colour_mu}; //010
		default: ram_colour = colour_im;
		endcase
	end
	
	
	// 9 registers while will hold the 9 pixels of colour
	pixel_register r0(.resetn(resetn), .clock(clock), .enable(ld_0), .colour_i(ram_colour), .colour_o(c0));
	pixel_register r1(.resetn(resetn), .clock(clock), .enable(ld_1), .colour_i(ram_colour), .colour_o(c1));
	pixel_register r2(.resetn(resetn), .clock(clock), .enable(ld_2), .colour_i(ram_colour), .colour_o(c2));
	pixel_register r3(.resetn(resetn), .clock(clock), .enable(ld_3), .colour_i(ram_colour), .colour_o(c3));
	pixel_register r4(.resetn(resetn), .clock(clock), .enable(ld_4), .colour_i(ram_colour), .colour_o(c4));
	pixel_register r5(.resetn(resetn), .clock(clock), .enable(ld_5), .colour_i(ram_colour), .colour_o(c5));
	pixel_register r6(.resetn(resetn), .clock(clock), .enable(ld_6), .colour_i(ram_colour), .colour_o(c6));
	pixel_register r7(.resetn(resetn), .clock(clock), .enable(ld_7), .colour_i(ram_colour), .colour_o(c7));
	pixel_register r8(.resetn(resetn), .clock(clock), .enable(ld_8), .colour_i(ram_colour), .colour_o(c8));
	
	// new image process module
	image_process m3(
		.filter(filter),
		.colour_i0(c0),
		.colour_i1(c1),
		.colour_i2(c2),
		.colour_i3(c3),
		.colour_i4(c4),
		.colour_i5(c5),
		.colour_i6(c6),
		.colour_i7(c7),
		.colour_i8(c8),
		.colour_out(colour_out));
	
	// direct assignments
	assign x_out = x + 80; 
	assign y_out = y + 60; 
	assign plot_out = plot_in;
	
endmodule


/*
0 1 2
3 4 5
6 7 8
*/

module address_adaptor(
	input [8:0]x,
	input [7:0]y,
	input [3:0]sel,
	output reg [16:0]address);

	wire[16:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;
	assign p0 = 160*y + x - 161;
	assign p1 = 160*y + x - 160;
	assign p2 = 160*y + x - 159;
	assign p3 = 160*y + x - 1;
	assign p4 = 160*y + x;
	assign p5 = 160*y + x + 1;
	assign p6 = 160*y + x + 159;
	assign p7 = 160*y + x + 160;
	assign p8 = 160*y + x + 161;
	
	always@(*)begin
		case(sel[3:0])
			4'd0: address = p0;
			4'd1: address = p1;
			4'd2: address = p2;
			4'd3: address = p3;
			4'd4: address = p4;
			4'd5: address = p5;
			4'd6: address = p6;
			4'd7: address = p7;
			4'd8: address = p8;
		default: address = p0;
		endcase
	end
	
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
	output reg ld_0, ld_1, ld_2, ld_3, ld_4, ld_5, ld_6, ld_7, ld_8,
	output reg [3:0]sel_address,
	output [2:0]sel_im,
	output [4:0]filter);
	

	reg [5:0] current_state, next_state;
	
	localparam 
		// states for reading pixels from the image
		S_IDLE = 6'd0,
		S_WAIT_KEY = 6'd1,
		S_LD0 = 6'd2,
		S_WAIT_C0 = 6'd3,
		S_LD1 = 6'd4,
		S_WAIT_C1 = 6'd5,
		S_LD2 = 6'd6,
		S_WAIT_C2 = 6'd7,
		S_LD3 = 6'd8,
		S_WAIT_C3 = 6'd9,
		S_LD4 = 6'd10,
		S_WAIT_C4 = 6'd11,
		S_LD5 = 6'd12,
		S_WAIT_C5 = 6'd13,
		S_LD6 = 6'd14,
		S_WAIT_C6 = 6'd15,
		S_LD7 = 6'd16,
		S_WAIT_C7 = 6'd17,
		S_LD8 = 6'd18,
		S_WAIT_C8 = 6'd19,
		S_DISPLAY = 6'd20,
		S_INCR_X = 6'd21,
		S_RESET_SIG = 6'd22,
		S_INCR_Y = 6'd23,
		S_WAIT_STABLE = 6'd24;
		
	
	// State table
	always@(*)begin
		
		case(current_state)
		
		
		S_IDLE: next_state = KEY[1] ? S_IDLE : S_WAIT_KEY;
			
			S_WAIT_KEY: next_state = KEY[1] ? S_LD0 : S_WAIT_C0;
			S_WAIT_C0: next_state =  S_LD0;
			
			S_LD0: next_state = S_WAIT_C1;
			S_WAIT_C1: next_state = S_LD1;
			
			S_LD1: next_state = S_WAIT_C2;
			S_WAIT_C2: next_state = S_LD2;
			
			S_LD2: next_state = S_WAIT_C3;
			S_WAIT_C3: next_state = S_LD3;
			
			S_LD3: next_state = S_WAIT_C4;
			S_WAIT_C4: next_state = S_LD4;
			
			S_LD4: next_state = S_WAIT_C5;
			S_WAIT_C5: next_state = S_LD5;
			
			S_LD5: next_state = S_WAIT_C6;
			S_WAIT_C6: next_state = S_LD6;
			
			S_LD6: next_state = S_WAIT_C7;
			S_WAIT_C7: next_state = S_LD7;
			
			S_LD7: next_state = S_WAIT_C8;
			S_WAIT_C8: next_state = S_LD8;
			
			S_LD8: next_state = S_WAIT_STABLE;
			S_WAIT_STABLE: next_state = S_DISPLAY;
			S_DISPLAY: next_state = S_INCR_X;
			S_INCR_X: next_state = row_done ? S_INCR_Y : S_LD0;
			S_INCR_Y: next_state = col_done ? S_IDLE : S_RESET_SIG;
			S_RESET_SIG: next_state = S_LD0;
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
		ld_0 = 1'b0;
		ld_1 = 1'b0;
		ld_2 = 1'b0;
		ld_3 = 1'b0;
		ld_4 = 1'b0;
		ld_5 = 1'b0;
		ld_6 = 1'b0;
		ld_7 = 1'b0;
		ld_8 = 1'b0;
		sel_address = 4'd0;
		
		case(current_state)
		S_IDLE:begin
		reset_sig_x = 1'b1;
		reset_sig_y = 1'b1;
		end
		
		
		// for drawing the pic
		S_LD0:begin
		ld_0 = 1'b1;
		sel_address = 4'd0;
		end
		

		S_LD1:begin
		ld_1 = 1'b1;
		sel_address = 4'd1;
		end
		

		S_LD2:begin
		ld_2 = 1'b1;
		sel_address = 4'd2;
		end
		

		S_LD3:begin
		ld_3 = 1'b1;
		sel_address = 4'd3;
		end
		
		S_LD4:begin
		ld_4 = 1'b1;
		sel_address = 4'd4;
		end
		
		S_LD5:begin
		ld_5 = 1'b1;
		sel_address = 4'd5;
		end
		
		S_LD6:begin
		ld_6 = 1'b1;
		sel_address = 4'd6;
		end
		

		S_LD7:begin
		ld_7 = 1'b1;
		sel_address = 4'd7;
		end
		
		S_LD8:begin
		ld_8 = 1'b1;
		sel_address = 4'd8;
		end
		
		S_DISPLAY:begin
		plot = 1'b1;
		end
		
		S_INCR_X:begin
		rowCountEn = 1'b1;
		end
		
		S_RESET_SIG:begin
		reset_sig_x = 1'b1;
		reset_sig_y = 1'b1;
		end
		
		S_INCR_Y:begin
		colCountEn = 1'b1;
		end
		
		endcase
	end
	
	
	
	// Direct assignment 
	assign filter = SW[4:0];
	assign sel_im = SW[9:7];
	
	// current_state registers
    always@(posedge clock)
    begin
        if(!resetn)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end // state_FFS

endmodule