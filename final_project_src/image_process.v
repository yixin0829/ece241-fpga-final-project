// Image processing module
// SW[9:7] filter option
module image_process(
	input [4:0]filter,
	input [23:0]colour_i0,
	input [23:0]colour_i1,
	input [23:0]colour_i2,
	input [23:0]colour_i3,
	input [23:0]colour_i4,
	input [23:0]colour_i5,
	input [23:0]colour_i6,
	input [23:0]colour_i7,
	input [23:0]colour_i8,
	output reg[23:0]colour_out);
	
	
	// Filter options (USER MANUAL!) SW[4:0]
	localparam 
		ORIGIN = 5'd0, // 00000
		INVERT = 5'd1, // 00001
		R_FILTER = 5'd2, // 00010
		G_FILTER = 5'd3, // 00011
		B_FILTER = 5'd4, // 00100
		GREY_SCALE = 5'd5, // 00101
		BRIGHTEN = 5'd6, // 00110
		DARKEN = 5'd7, //00111
		BLUR = 5'd8, // 01000
		GBLUR = 5'd9, // 01001
		SOBEL_EDGE = 5'd10, // 01010 
		EMBOSS = 5'd11; // 01011
		
	
	wire [23:0]colour_grey;
	wire [23:0]bright, dark;
	wire [23:0]box_blur, gaussian_blur, edge_detection, emboss;
	
	always@(*)begin
		case(filter[4:0])
			ORIGIN: colour_out = colour_i0;
			INVERT: colour_out = ~colour_i0;
			R_FILTER: colour_out = {colour_i0[23:16], 16'd0};
			G_FILTER: colour_out = {8'd0, colour_i0[15:8], 8'd0};
			B_FILTER: colour_out = {16'd0, colour_i0[7:0]};
			GREY_SCALE: colour_out = colour_grey;
			BLUR: colour_out = box_blur;
			BRIGHTEN: colour_out = bright;
			DARKEN: colour_out = dark;
			GBLUR: colour_out = gaussian_blur;
			SOBEL_EDGE: colour_out = edge_detection; 
			EMBOSS: colour_out = emboss; 
		endcase
	end 
	

	
	grey_scale g0(.colour_in(colour_i0), .colour_out(colour_grey));
	bright_add g1(.colour_in(colour_i0), .colour_out(bright));
	darken g2(.colour_in(colour_i0), .colour_out(dark));
	
	box_blur g3(
		.colour_i0(colour_i0),
		.colour_i1(colour_i1),
		.colour_i2(colour_i2),
		.colour_i3(colour_i3),
		.colour_i4(colour_i4),
		.colour_i5(colour_i5),
		.colour_i6(colour_i6),
		.colour_i7(colour_i7),
		.colour_i8(colour_i8),
		.colour_out(box_blur));
	
	gaussian_blur g4(
		.colour_i0(colour_i0),
		.colour_i1(colour_i1),
		.colour_i2(colour_i2),
		.colour_i3(colour_i3),
		.colour_i4(colour_i4),
		.colour_i5(colour_i5),
		.colour_i6(colour_i6),
		.colour_i7(colour_i7),
		.colour_i8(colour_i8),
		.colour_out(gaussian_blur));
		
	edge_detection g5(
		.colour_i0(colour_i0),
		.colour_i1(colour_i1),
		.colour_i2(colour_i2),
		.colour_i3(colour_i3),
		.colour_i4(colour_i4),
		.colour_i5(colour_i5),
		.colour_i6(colour_i6),
		.colour_i7(colour_i7),
		.colour_i8(colour_i8),
		.colour_out(edge_detection));
	
	emboss g6(
		.colour_i0(colour_i0),
		.colour_i1(colour_i1),
		.colour_i2(colour_i2),
		.colour_i3(colour_i3),
		.colour_i4(colour_i4),
		.colour_i5(colour_i5),
		.colour_i6(colour_i6),
		.colour_i7(colour_i7),
		.colour_i8(colour_i8),
		.colour_out(emboss));
	
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


module  bright_add    (
    input [23:0]colour_in,
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
	
		tempR1 = r_in + value1;

	
	if (tempR1 > 255)
		r_out = white;
	else
		r_out = tempR1;
		

		tempG1 = g_in + value1;


	if (tempG1 > 255)
		g_out = white;
	else
		g_out = tempG1;
		

		tempB1 = b_in + value1;

	
	if (tempB1 > 255)
		b_out = white;
	else
		b_out = tempB1;
	
	 
	end
	
	assign  colour_out = {r_out, g_out, b_out};
	
endmodule

module  darken    (
    input [23:0]colour_in,
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
	
	assign  colour_out = {r_out, g_out, b_out};
	
endmodule


/*
0 1 2
3 4 5
6 7 8

*/

module box_blur(
	input [23:0]colour_i0,
	input [23:0]colour_i1,
	input [23:0]colour_i2,
	input [23:0]colour_i3,
	input [23:0]colour_i4,
	input [23:0]colour_i5,
	input [23:0]colour_i6,
	input [23:0]colour_i7,
	input [23:0]colour_i8,
	output [23:0]colour_out);
	
	wire[7:0]red0, red1, red2, red3, red4, red5, red6, red7, red8;
	wire[7:0]green0, green1, green2, green3, green4, green5, green6, green7, green8;
	wire[7:0]blue0, blue1, blue2, blue3, blue4, blue5, blue6, blue7, blue8;
	
	wire[31:0] red_x, green_x, blue_x;
	
	assign red0 = colour_i0[23:16];
	assign red1 = colour_i1[23:16];
	assign red2 = colour_i2[23:16];
	assign red3 = colour_i3[23:16];
	assign red4 = colour_i4[23:16];
	assign red5 = colour_i5[23:16];
	assign red6 = colour_i6[23:16];
	assign red7 = colour_i7[23:16];
	assign red8 = colour_i8[23:16];
	
	assign green0 = colour_i0[15:8];
	assign green1 = colour_i1[15:8];
	assign green2 = colour_i2[15:8];
	assign green3 = colour_i3[15:8];
	assign green4 = colour_i4[15:8];
	assign green5 = colour_i5[15:8];
	assign green6 = colour_i6[15:8];
	assign green7 = colour_i7[15:8];
	assign green8 = colour_i8[15:8];
	
	assign blue0 = colour_i0[7:0];
	assign blue1 = colour_i1[7:0];
	assign blue2 = colour_i2[7:0];
	assign blue3 = colour_i3[7:0];
	assign blue4 = colour_i4[7:0];
	assign blue5 = colour_i5[7:0];
	assign blue6 = colour_i6[7:0];
	assign blue7 = colour_i7[7:0];
	assign blue8 = colour_i8[7:0];
	
	
	assign red_x = red0 + red1 + red2 + red3 + red4 + red5 + red6 + red7 + red8;
	assign green_x = green0 + green1 + green2 + green3 + green4 + green5 + green6 + green7 + green8;
	assign blue_x = blue0 + blue1 + blue2 + blue3 + blue4 + blue5 + blue6 + blue7 + blue8;
	
	assign colour_out[23:16] = red_x / 9;
	assign colour_out[15:8] = green_x / 9;
	assign colour_out[7:0] = blue_x / 9;

endmodule


module gaussian_blur(
	input [23:0]colour_i0,
	input [23:0]colour_i1,
	input [23:0]colour_i2,
	input [23:0]colour_i3,
	input [23:0]colour_i4,
	input [23:0]colour_i5,
	input [23:0]colour_i6,
	input [23:0]colour_i7,
	input [23:0]colour_i8,
	output [23:0]colour_out);
	
	wire[7:0]red0, red1, red2, red3, red4, red5, red6, red7, red8;
	wire[7:0]green0, green1, green2, green3, green4, green5, green6, green7, green8;
	wire[7:0]blue0, blue1, blue2, blue3, blue4, blue5, blue6, blue7, blue8;
	
	wire[31:0] red_x, green_x, blue_x;
	
	assign red0 = colour_i0[23:16];
	assign red1 = colour_i1[23:16];
	assign red2 = colour_i2[23:16];
	assign red3 = colour_i3[23:16];
	assign red4 = colour_i4[23:16];
	assign red5 = colour_i5[23:16];
	assign red6 = colour_i6[23:16];
	assign red7 = colour_i7[23:16];
	assign red8 = colour_i8[23:16];
	
	assign green0 = colour_i0[15:8];
	assign green1 = colour_i1[15:8];
	assign green2 = colour_i2[15:8];
	assign green3 = colour_i3[15:8];
	assign green4 = colour_i4[15:8];
	assign green5 = colour_i5[15:8];
	assign green6 = colour_i6[15:8];
	assign green7 = colour_i7[15:8];
	assign green8 = colour_i8[15:8];
	
	assign blue0 = colour_i0[7:0];
	assign blue1 = colour_i1[7:0];
	assign blue2 = colour_i2[7:0];
	assign blue3 = colour_i3[7:0];
	assign blue4 = colour_i4[7:0];
	assign blue5 = colour_i5[7:0];
	assign blue6 = colour_i6[7:0];
	assign blue7 = colour_i7[7:0];
	assign blue8 = colour_i8[7:0];
	
	/*
	|0 1 2| 1 2 1
	|3 4 5| 2 4 2 
	|6 7 8| 1 2 1
	*/
	assign red_x = red0 + 2*red1 + red2 + 2*red3 + 4*red4+ 2*red5+ red6 + 2*red7+ red8;
	assign green_x = green0 + 2*green1 + green2 + 2*green3 + 4*green4 + 2*green5 + green6 + 2*green7 + green8;
	assign blue_x = blue0 + 2*blue1 + blue2 + 2*blue3 + 4*blue4 + 2*blue5 + blue6 +2*blue7 + blue8; 

	assign colour_out[23:16]= red_x/16;
	assign colour_out[15:8]= green_x/16;
	assign colour_out[7:0]= blue_x/16;

endmodule 


// sobel edge detection
//        sobel edge detection 
      
//        | 1 0 -1 |           | 1 2 1 | 
//        | 2 0 -2 |           | 0 0 0 | 
//        | 1 0 -1 |           |-1 -2 -1 | 


module edge_detection(
	input [23:0]colour_i0,
	input [23:0]colour_i1,
	input [23:0]colour_i2,
	input [23:0]colour_i3,
	input [23:0]colour_i4,
	input [23:0]colour_i5,
	input [23:0]colour_i6,
	input [23:0]colour_i7,
	input [23:0]colour_i8,
	output [23:0]colour_out);
	
	wire[7:0]red0, red1, red2, red3, red4, red5, red6, red7, red8;
	wire[7:0]green0, green1, green2, green3, green4, green5, green6, green7, green8;
	wire[7:0]blue0, blue1, blue2, blue3, blue4, blue5, blue6, blue7, blue8;
	
	wire[31:0] red_x, blue_x;
	reg[31:0] green_x;
	
	assign red0 = colour_i0[23:16];
	assign red1 = colour_i1[23:16];
	assign red2 = colour_i2[23:16];
	assign red3 = colour_i3[23:16];
	assign red4 = colour_i4[23:16];
	assign red5 = colour_i5[23:16];
	assign red6 = colour_i6[23:16];
	assign red7 = colour_i7[23:16];
	assign red8 = colour_i8[23:16];
	
	assign green0 = colour_i0[15:8];
	assign green1 = colour_i1[15:8];
	assign green2 = colour_i2[15:8];
	assign green3 = colour_i3[15:8];
	assign green4 = colour_i4[15:8];
	assign green5 = colour_i5[15:8];
	assign green6 = colour_i6[15:8];
	assign green7 = colour_i7[15:8];
	assign green8 = colour_i8[15:8];
	
	assign blue0 = colour_i0[7:0];
	assign blue1 = colour_i1[7:0];
	assign blue2 = colour_i2[7:0];
	assign blue3 = colour_i3[7:0];
	assign blue4 = colour_i4[7:0];
	assign blue5 = colour_i5[7:0];
	assign blue6 = colour_i6[7:0];
	assign blue7 = colour_i7[7:0];
	assign blue8 = colour_i8[7:0];

//        | 1 0 -1 |           | 1 2 1 | 
//        | 2 0 -2 |           | 0 0 0 | 
//        | 1 0 -1 |           |-1 -2 -1 | 
//    | 0 1 2 |
//    | 3 4 5 |
//    | 6 7 8 |
	assign red_x = red0 - red2 +2*red3 -2*red5 + red6 - red8;
	assign blue_x = red0 +2*red1 + red2 - red6 - 2*red7 - red8;
	
	always@(*)begin
	
	 if(red_x > 1024 & blue_x > 1024)begin 
		green_x = -(red_x + blue_x)/2; 
    end else if(red_x > 1024 & blue_x < 1024)begin 
      green_x = (-red_x  + blue_x)/2; 
    end else if(red_x < 1024 & blue_x < 1024)begin 
      green_x = (red_x + blue_x)/2; 
    end else begin 
      green_x = (red_x - blue_x)/2; 
    end 
	 
	end
	
	assign colour_out[23:16] = green_x;
	assign colour_out[15:8] = green_x;
	assign colour_out[7:0] = green_x;
	

endmodule 



module emboss(
 input [23:0]colour_i0,
 input [23:0]colour_i1,
 input [23:0]colour_i2,
 input [23:0]colour_i3,
 input [23:0]colour_i4,
 input [23:0]colour_i5,
 input [23:0]colour_i6,
 input [23:0]colour_i7,
 input [23:0]colour_i8,
 output reg [23:0]colour_out);

 wire[7:0]red0, red1, red2, red3, red4, red5, red6, red7, red8;
 wire[7:0]green0, green1, green2, green3, green4, green5, green6, green7, green8;
 wire[7:0]blue0, blue1, blue2, blue3, blue4, blue5, blue6, blue7, blue8;

 wire[31:0] red_x;

 assign red0 = colour_i0[23:16];
 assign red1 = colour_i1[23:16];
 assign red2 = colour_i2[23:16];
 assign red3 = colour_i3[23:16];
 assign red4 = colour_i4[23:16];
 assign red5 = colour_i5[23:16];
 assign red6 = colour_i6[23:16];
 assign red7 = colour_i7[23:16];
 assign red8 = colour_i8[23:16];

 assign green0 = colour_i0[15:8];
 assign green1 = colour_i1[15:8];
 assign green2 = colour_i2[15:8];
 assign green3 = colour_i3[15:8];
 assign green4 = colour_i4[15:8];
 assign green5 = colour_i5[15:8];
 assign green6 = colour_i6[15:8];
 assign green7 = colour_i7[15:8];
 assign green8 = colour_i8[15:8];

 assign blue0 = colour_i0[7:0];
 assign blue1 = colour_i1[7:0];
 assign blue2 = colour_i2[7:0];
 assign blue3 = colour_i3[7:0];
 assign blue4 = colour_i4[7:0];
 assign blue5 = colour_i5[7:0];
 assign blue6 = colour_i6[7:0];
 assign blue7 = colour_i7[7:0];
 assign blue8 = colour_i8[7:0];

 /*
 |0 1 2| -2 -1 0
 |3 4 5| -1 1 1 
 |6 7 8|  0 1 2
 */
  assign red_x = red4 + red5 -red3 -red1 + 2*red8 - 2*red0;
  
  always@(*)begin
  
		 if (red_x > 1280)  begin
		 colour_out<=0;
		 end
		 else begin
		 colour_out[23:16] <= red_x;
		 colour_out[15:8] <= red_x;
		 colour_out[7:0] <= red_x;
		 end
  end


 endmodule 



