module top (
    input           clk,
    input           rst_n,

	output [4:0]  	lcd_r,
	output [5:0]  	lcd_g,
	output [4:0]  	lcd_b,
    output          lcd_de,
    output          lcd_hsync,
    output          lcd_vsync,
    output          lcd_clk,
	output			lcd_bl
);

assign lcd_bl = 1'b1 ;

pll_40m pll_40m_inst(
    .clkout (clk_out),  //output clkout
    .clkin  (clk)     //input clkin
);

parameter para = 8 ;

wire [23:0] lcd_rgb  ;
wire [23:0] lcd_data ;

assign lcd_r[4:0] = lcd_rgb[4+ para*2:para*2];
assign lcd_g[5:0] = lcd_rgb[5+ para*1:para*1];
assign lcd_b[4:0] = lcd_rgb[4+ para*0:para*0];

wire	[11:0]	lcd_xpos;		
wire	[11:0]	lcd_ypos;		

lcd_ctrl lcd_ctrl_inst (
	.clk        (clk_out)    ,      //lcd clock
	.rst_n      (rst_n)      ,      //sync reset
	.lcd_data   (lcd_data)   ,      //lcd data
	.lcd_clk    (lcd_clk)    ,      //lcd pixel clock
	.lcd_hs     (lcd_hsync)  ,	    //lcd horizontal sync
	.lcd_vs     (lcd_vsync)  ,	    //lcd vertical sync
	.lcd_de     (lcd_de)     ,	    //lcd display enable; 1:Display Enable Signal;0: Disable Ddsplay
	.lcd_rgb    (lcd_rgb)    ,      //lcd display data
	.lcd_xpos   (lcd_xpos)   ,      //lcd horizontal coordinate
	.lcd_ypos   (lcd_ypos)		    //lcd vertical coordinate
);

lcd_data lcd_data_inst( 
	.clk(clk),	
	.rst_n(rst_n),	
	.lcd_xpos(lcd_xpos),	//lcd horizontal coordinate
	.lcd_ypos(lcd_ypos),	//lcd vertical coordinate
	
	.lcd_data(lcd_data)	    //lcd data
);

endmodule