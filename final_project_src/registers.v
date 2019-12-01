// register 
module pixel_register(
	input resetn, clock,
	input enable,
	input [23:0] colour_i,
	output reg [23:0]colour_o);
	
	always@(posedge clock)begin
	
		if(!resetn)
			colour_o <= 23'd0;
		else if(enable)
			colour_o <= colour_i;
		else 
			colour_o <= colour_o;
			
	end
	
endmodule 
