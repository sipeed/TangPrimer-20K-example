module top(
	input                       clk,
	input                       rst_n,
	inout                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
    output                      cmos_xclk,         //cmos externl clock 
	input   [7:0]               cmos_db,           //cmos data
	output                      cmos_rst_n,        //cmos reset 
	output                      cmos_pwdn,         //cmos power down
	output  sys_run,cam_run,rst_led,
	output                      lcd_dclk,	
	output                      lcd_hs,            //lcd horizontal synchronization
	output                      lcd_vs,            //lcd vertical synchronization        
	output                      lcd_de,            //lcd data enable     
	output[4:0]                 lcd_r,             //lcd red
	output[5:0]                 lcd_g,             //lcd green
	output[4:0]                 lcd_b	           //lcd blue
);

wire                            video_clk;         //video pixel clock
wire                            hs;
wire                            vs;
wire                            de;
wire[15:0]                      vout_data;
wire[15:0]                      cmos_16bit_data;
wire[15:0] 						write_data;

wire[9:0]                       lut_index;
wire[31:0]                      lut_data;

assign lcd_hs = hs;
assign lcd_vs = vs;
assign lcd_de = de;
assign lcd_r  = vout_data[15:11];
assign lcd_g  = vout_data[10: 5];
assign lcd_b  = vout_data[ 4: 0];
assign lcd_dclk = ~video_clk;

assign cmos_xclk = cmos_clk;
assign cmos_pwdn = 1'b0;
assign cmos_rst_n = 1'b1;
assign rst_led = rst_n;
assign write_data = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};

reg [5:0] vs_running;
assign sys_run = vs_running[5];
always@(posedge lcd_vs)
	vs_running <= vs_running + 6'd1;

reg [5:0] cam_running;
assign cam_run = cam_running[5];
always@(posedge cmos_vsync)
	cam_running <= cam_running + 6'd1;

//generate the CMOS sensor clock and the video clock
sys_pll sys_pll_m0(
	.clkin                     (cmos_clk                  ),
	.clkout                    (video_clk 	              )
	);
cmos_pll cmos_pll_m0(
	.clkin                     (clk                            ),
	.clkout                    (cmos_clk 	              		)
	);

//I2C master controller
i2c_config i2c_config_m0(
	.rst                        (~rst_n                   ),
	.clk                        (clk                   	  ),
	.clk_div_cnt                (16'd270                  ),
	.i2c_addr_2byte             (1'b1                     ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       (                         ),
	.i2c_scl                    (cmos_scl                 ),
	.i2c_sda                    (cmos_sda                 )
);
//configure look-up table
lut_ov5640_rgb565_800_480 lut_ov5640_rgb565_800_480_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);
//CMOS sensor 8bit data is converted to 16bit data
cmos_8_16bit cmos_8_16bit_m0(
	.rst                        (~rst_n                   ),
	.pclk                       (cmos_pclk                ),
	.pdata_i                    (cmos_db                  ),
	.de_i                       (cmos_href                ),
	.pdata_o                    (cmos_16bit_data          ),
	.hblank                     (                         ),
	.de_o                       (cmos_16bit_wr            )
);

//The video output timing generator and generate a frame read data request
video_timing_data video_timing_data_m0
(
	.video_clk                  (video_clk                ),
	.rst                        (~rst_n                   ),

	.fifo_data_in   			(write_data 		  	  ),
	.fifo_data_in_en			(cmos_16bit_wr 			  ),
	.fifo_data_in_clk			(cmos_pclk 			  	  ),
	.fifo_data_vs  				(cmos_vsync 			  ),

	.hs                         (hs                       ),
	.vs                         (vs                       ),
	.de                         (de                       ),
	.vout_data                  (vout_data                )
);

endmodule