module top (
	input clk,    // Clock
	
	output              lcd_dclk,	
	output              lcd_hs,    //lcd horizontal synchronization
	output              lcd_vs,    //lcd vertical synchronization        
	output              lcd_de,    //lcd data enable     
	output 	  [4:0]     lcd_r,     //lcd red
	output 	  [5:0]     lcd_g,     //lcd green
	output 	  [4:0]     lcd_b	   //lcd blue
);

wire [9:0] lcd_x,lcd_y;

assign {lcd_r,lcd_g,lcd_b} = {lcd_x[5:4],3'b000,lcd_y[5:4],9'd0};

video_pll video_pll_m0(
	.clkin  	(clk 		),
	.clkout 	(lcd_dclk 	)
	);

vga_timing vga_timing_m0(
	.clk  		(lcd_dclk 	),
	.rst  		(0 			),
	.active_x 	(lcd_x 		),
	.active_y 	(lcd_y 		),
	.hs  		(lcd_hs 	),
	.vs  		(lcd_vs 	),
	.de  		(lcd_de 	)
	);

endmodule