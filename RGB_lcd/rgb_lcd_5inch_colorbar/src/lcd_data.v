`timescale 1ns/1ns

module lcd_data
#(
	parameter H_DISP = 800,
	parameter V_DISP = 480
)
( 
	input  wire	 		clk,	
	input  wire			rst_n,	
	input  wire	[11:0]	lcd_xpos,	//lcd horizontal coordinate
	input  wire	[11:0]	lcd_ypos,	//lcd vertical coordinate
	
	output reg  [23:0]	lcd_data	//lcd data
);

// Define colors RGB--8|8|8
`define RED		24'hFF0000 
`define GREEN	24'h00FF00 
`define BLUE  	24'h0000FF 
`define WHITE 	24'hFFFFFF 
`define BLACK 	24'h000000 
`define YELLOW	24'hFFFF00 
`define CYAN  	24'hFF00FF 
`define ROYAL 	24'h00FFFF 

// Define Display Mode
`define	VGA_HORIZONTAL_COLOR
// `define	VGA_VERTICAL_COLOR
// `define	VGA_GRAY_GRAPH
// `define	VGA_GRAFTAL_GRAPH

`ifdef VGA_HORIZONTAL_COLOR
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		lcd_data <= 24'h0;
	else
		begin
		if	(lcd_ypos >= 0 && lcd_ypos < (V_DISP/8)*1)
			lcd_data <= `RED;
		else if(lcd_ypos >= (V_DISP/8)*1 && lcd_ypos < (V_DISP/8)*2)
			lcd_data <= `GREEN;
		else if(lcd_ypos >= (V_DISP/8)*2 && lcd_ypos < (V_DISP/8)*3)
			lcd_data <= `BLUE;
		else if(lcd_ypos >= (V_DISP/8)*3 && lcd_ypos < (V_DISP/8)*4)
			lcd_data <= `WHITE;
		else if(lcd_ypos >= (V_DISP/8)*4 && lcd_ypos < (V_DISP/8)*5)
			lcd_data <= `BLACK;
		else if(lcd_ypos >= (V_DISP/8)*5 && lcd_ypos < (V_DISP/8)*6)
			lcd_data <= `YELLOW;
		else if(lcd_ypos >= (V_DISP/8)*6 && lcd_ypos < (V_DISP/8)*7)
			lcd_data <= `CYAN;
		else
			lcd_data <= `ROYAL;
		end
end
`endif

`ifdef VGA_VERTICAL_COLOR
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		lcd_data <= 24'h0;
	else
		begin
		if	(lcd_xpos >= 0 && lcd_xpos < (H_DISP/8)*1)
			lcd_data <= `RED;
		else if(lcd_xpos >= (H_DISP/8)*1 && lcd_xpos < (H_DISP/8)*2)
			lcd_data <= `GREEN;
		else if(lcd_xpos >= (H_DISP/8)*2 && lcd_xpos < (H_DISP/8)*3)
			lcd_data <= `BLUE;
		else if(lcd_xpos >= (H_DISP/8)*3 && lcd_xpos < (H_DISP/8)*4)
			lcd_data <= `WHITE;
		else if(lcd_xpos >= (H_DISP/8)*4 && lcd_xpos < (H_DISP/8)*5)
			lcd_data <= `BLACK;
		else if(lcd_xpos >= (H_DISP/8)*5 && lcd_xpos < (H_DISP/8)*6)
			lcd_data <= `YELLOW;
		else if(lcd_xpos >= (H_DISP/8)*6 && lcd_xpos < (H_DISP/8)*7)
			lcd_data <= `CYAN;
		else
			lcd_data <= `ROYAL;
		end
end
`endif

`ifdef VGA_GRAFTAL_GRAPH
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		lcd_data <= 24'h0;
	else
		lcd_data <= lcd_xpos * lcd_ypos;
end
`endif


`ifdef VGA_GRAY_GRAPH
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		lcd_data <= 24'h0;
	else
		begin
		if(lcd_ypos < V_DISP/2)
			lcd_data <= {lcd_ypos[7:0], lcd_ypos[7:0], lcd_ypos[7:0]};
		else
			lcd_data <= {lcd_xpos[7:0], lcd_xpos[7:0], lcd_xpos[7:0]};
		end
end
`endif

endmodule