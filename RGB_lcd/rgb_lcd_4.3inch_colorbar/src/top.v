module lcd480p_top (
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

assign {lcd_r,lcd_g,lcd_b} = lcd_de? 
lcd_x <  30 ? 16'B10000_000000_00000: 	lcd_x <  60 ? 16'B01000_000000_00000:
lcd_x <  90 ? 16'B00100_000000_00000:	lcd_x < 120 ? 16'B00010_000000_00000:
lcd_x < 150 ? 16'B00001_000000_00000:	lcd_x < 180 ? 16'B00000_100000_00000:

lcd_x < 210 ? 16'B00000_010000_00000:	lcd_x < 240 ? 16'B00000_001000_00000:
lcd_x < 270 ? 16'B00000_000100_00000:	lcd_x < 300 ? 16'B00000_000010_00000:
lcd_x < 330 ? 16'B00000_000001_00000:	lcd_x < 360 ? 16'B00000_000000_10000:

lcd_x < 390 ? 16'B00000_000000_01000:	lcd_x < 420 ? 16'B00000_000000_00100:
lcd_x < 450 ? 16'B00000_000000_00010:				  16'B00000_000000_00001
: 16'H0000;

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