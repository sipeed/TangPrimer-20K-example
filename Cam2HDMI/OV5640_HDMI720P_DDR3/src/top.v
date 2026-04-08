module top #(
    parameter         USE_TPG     = "false",
    parameter         USE_1280    = "true",
    parameter         USE_1024    = "false",
    parameter integer I2C_MODE    = 3,
    parameter integer USE_DSP_CNT = 0,
    parameter integer SCCB_LOGIC_CLK = 37_000_000
)(
	input                  clk,
    input                  hdmi_hpd,
	input                  rst_n,
	inout                  cmos_scl,        //cmos i2c clock
	inout                  cmos_sda,        //cmos i2c data
	input                  cmos_vsync,      //cmos vsync
	input                  cmos_href,       //cmos hsync refrence,data valid
	input                  cmos_pclk,       //cmos pxiel clock
    output                 cmos_xclk,       //cmos externl clock 
	input  [7:0]           cmos_db,         //cmos data
	output                 cmos_rst_n,      //cmos reset 
	output                 cmos_pwdn,       //cmos power down
	
	output [5:0]           state_led,

	output [13-1:0]        ddr_addr,        //ROW_WIDTH=13
	output [3-1:0]         ddr_bank,        //BANK_WIDTH=3
	output                 ddr_cs,
	output                 ddr_ras,
	output                 ddr_cas,
	output                 ddr_we,
	output                 ddr_ck,
	output                 ddr_ck_n,
	output                 ddr_cke,
	output                 ddr_odt,
	output                 ddr_reset_n,
	output [2-1:0]         ddr_dm,          //DM_WIDTH=2
	inout  [16-1:0]        ddr_dq,          //DQ_WIDTH=16
	inout  [2-1:0]         ddr_dqs,         //DQS_WIDTH=2
	inout  [2-1:0]         ddr_dqs_n,       //DQS_WIDTH=2
  
    output                 tmds_clk_n,
    output                 tmds_clk_p,
    output [2:0]           tmds_d_n,      //{r,g,b}
    output [2:0]           tmds_d_p

);
    

//memory interface
    wire                   memory_clk         ;
    wire                   dma_clk         	  ;
    wire                   cmd_ready          ;
    wire[2:0]              cmd                ;
    wire                   cmd_en             ;
    //wire[5:0]              app_burst_number   ;
    wire[ADDR_WIDTH-1:0]   addr               ;
    wire                   wr_data_rdy        ;
    wire                   wr_data_en         ;
    wire                   wr_data_end        ;
    wire[DATA_WIDTH-1:0]   wr_data            ;   
    wire[DATA_WIDTH/8-1:0] wr_data_mask       ;   
    wire                   rd_data_valid      ;  
    wire                   rd_data_end        ;//unused 
    wire[DATA_WIDTH-1:0]   rd_data            ;   
    wire                   err                ;
    wire                   ddr_rst            ;

    //According to IP parameters to choose
    `define	    WR_VIDEO_WIDTH_16
    `define	DEF_WR_VIDEO_WIDTH 16

    `define	    RD_VIDEO_WIDTH_16
    `define	DEF_RD_VIDEO_WIDTH 16

    `define	USE_THREE_FRAME_BUFFER

    `define	DEF_ADDR_WIDTH 27
    `define	DEF_SRAM_DATA_WIDTH 128
    
    //=========================================================
    //SRAM parameters
    localparam ADDR_WIDTH          = `DEF_ADDR_WIDTH;        //The memory is byte, total capacity = 2^29*16bit = 8Gbit, add 1 bit of rank address, {rank[0],bank[2:0],row[15:0],cloumn[9:0]}
    localparam DATA_WIDTH          = `DEF_SRAM_DATA_WIDTH;   //Related to generating DDR3 IP
    localparam WR_VIDEO_WIDTH      = `DEF_WR_VIDEO_WIDTH;  
    localparam RD_VIDEO_WIDTH      = `DEF_RD_VIDEO_WIDTH;  

    wire                            video_clk, serial_clk;  //video pixel clock
    //-------------------
    //syn_code
    wire                            syn_off0_re;      // ofifo read enable signal
    wire                            syn_off0_vs;
    wire                            syn_off0_hs;

    wire                            off0_syn_de  ;
    wire [RD_VIDEO_WIDTH-1:0]       off0_syn_data;

    wire[15:0]                      cmos_16bit_data;
    wire                            cmos_16bit_clk;
    wire[15:0] 						write_data;

    wire[7:0]                       lut_index;
    wire[31:0]                      lut_data;
    wire                            i2c_err;
    
    wire                            rstni; 
    key_debounce u_key_debounce (
    .clk(clk), 
    .rst_n(1'b1), 
    .key1_n(rst_n), 
    .key_1(rstni)
    );

    reg [4:0] cmos_vs_cnt;
    always@(posedge cmos_vsync) 
        cmos_vs_cnt <= cmos_vs_cnt + 1'b1;

    assign cmos_vs_div_out = cmos_vs_cnt[4];

    wire cmos_pll_lock, TMDS_pll_lock, DDR_pll_lock;
    //indicator
    wire   i2c_done;
    assign state_led[5] = ~hdmi_hpd;
    assign state_led[4] = ~i2c_done;
    assign state_led[3] = ~cmos_vs_cnt[4];
    assign state_led[2] = ~TMDS_pll_lock;
    assign state_led[1] = ~DDR_pll_lock; 
    assign state_led[0] = ~init_calib_complete;


    wire [15:0] HActive;
    wire HA_valid;
    wire [15:0] VActive;
    wire VA_valid;
    wire [7:0] fps;
    wire fps_valid;

    timing_check#(
        .REFCLK_FREQ_MHZ(50),
        .IS_2Pclk_1Pixel("true")
    ) timing_check_5640(
        .Refclk(clk),
        .pxl_clk(cmos_pclk),
        .rst_n(rstni),
        .video_de(cmos_href),
        .video_vsync(cmos_vsync),
        .H_Active(HActive),
        .Ha_updated(HA_valid),
        .V_Active(VActive),
        .va_updated(VA_valid),
        .fps(fps),
        .fps_valid(fps_valid)
    ); 

    //generate the CMOS sensor clock and the SDRAM controller, I2C controller clock
    wire clk_35M, clk_50M, cmos_clk;
    wire pll_stop;
    clk_init u_clk_init(
    	.clkin                      (clk                ),
        .rst_n                      (rstni & hdmi_hpd   ),
    	.clk_37M                    (clk_37M 	        ),
    	.clk_50M                    (clk_50M 	        ),
        .cmos_clk                   (cmos_clk 	        ),
        .memory_clk                 (memory_clk         ),
    	.clk_5x 					(serial_clk         ),
        .clk_1x                     (video_clk          ),
        .cmos_pll_lock              (cmos_pll_lock      ), 
        .DDR_pll_lock               (DDR_pll_lock       ), 
        .TMDS_pll_lock              (TMDS_pll_lock       )  
	);

    wire cmos_resetn, cmos_start_cfg;
    wire cmos_start_config = cmos_start_cfg & cmos_resetn;

    assign cmos_xclk = cmos_clk;
    assign cmos_pwdn = 1'b0;
    //assign cmos_rst_n = 1'b1;
    assign cmos_rst_n = cmos_resetn ^ ddr_rst;
    //assign cmos_rst_n = rst_n;
    assign write_data = cmos_16bit_data;
    //assign write_data = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};
    //assign hdmi_hpd = 1;  

    cmos_reset_gen #(
        .USE_DSP_CNT                (0                    ),
        .CNT_WIDTH                  (22                   )
    ) cmos_reset_gen_m0(
        .clk                        (sccb_clk             ),
        .rst_n                      (rstni & cmos_pll_lock),
        .cmos_resetn                (cmos_resetn          ),
        .cmos_start_config          (cmos_start_cfg       )
    );

    //configure look-up table
    localparam [3:0]   LUT_ADDR_WIDTH = 4'd8;
    localparam integer CMOS_COLOR_BAR = 1'b0;
    generate 
        if(USE_1280 == "true") begin
            lut_ov5640_rgb565 #(
            	.HActive(12'd1280),
            	.VActive(12'd720),
            	.HTotal(13'd1892),
            	.VTotal(13'd740),
                .LUT_AW(LUT_ADDR_WIDTH),
                .USE_colour_bar(CMOS_COLOR_BAR),
                .USE_4vs3_frame(1'b0)
            )lut_ov5640_rgb565_m0(
            	.lut_index(lut_index),
            	.lut_data(lut_data)
            );
        end
        else if(USE_1024 == "true" && USE_1280 == "false") begin
            lut_ov5640_rgb565 #(
            	.HActive(12'd1024),
            	.VActive(12'd768),
            	.HTotal(13'd1892),
            	.VTotal(13'd740),
                .LUT_AW(LUT_ADDR_WIDTH),
                .USE_colour_bar(CMOS_COLOR_BAR),
                .USE_4vs3_frame(1'b1)
            )lut_ov5640_rgb565_m0(
            	.lut_index(lut_index),
            	.lut_data(lut_data)
            );
        end
        else begin
            lut_ov5640_rgb565 #(
            	.HActive(12'd800),
            	.VActive(12'd600),
            	.HTotal(13'd1892),
            	.VTotal(13'd740),
                .LUT_AW(LUT_ADDR_WIDTH),
                .USE_colour_bar(CMOS_COLOR_BAR),
                .USE_4vs3_frame(1'b1)
            )lut_ov5640_rgb565_m0(
            	.lut_index(lut_index),
            	.lut_data(lut_data)
            );
        end
    endgenerate
    
    //I2C master controller
    wire [15:0] i2c_clk_cnt;
    generate
        if(SCCB_LOGIC_CLK == 37_000_000) begin
            assign sccb_clk    = clk_37M;
            assign i2c_clk_cnt = 16'd73;
        end
        else begin
            assign sccb_clk    = clk;
            assign i2c_clk_cnt = 16'd54;
        end
    endgenerate

    generate
        if(I2C_MODE == 1) begin
            i2c_config i2c_config_m0(
            	.rst                        (~cmos_start_config       ),
            	.clk                        (sccb_clk                 ),
            	.clk_div_cnt                (i2c_clk_cnt              ),
            	.i2c_addr_2byte             (1'b1                     ),
            	.lut_index                  (lut_index                ),
            	.lut_dev_addr               (lut_data[31:24]          ),
            	.lut_reg_addr               (lut_data[23:8]           ),
            	.lut_reg_data               (lut_data[7:0]            ),
            	.error                      (i2c_err                  ),
            	.done                       (i2c_done                 ),
            	.i2c_scl                    (cmos_scl                 ),
            	.i2c_sda                    (cmos_sda                 )
            );
        end

        else if(I2C_MODE == 2) begin
            i2c_master_gw_init #(
                .DEV_ADDR_WIDTH             (4'd8                     ),
                .REG_ADDR_WIDTH             (8'd16                    ),
                .REG_DATA_WIDTH             (4'd8                     ),
                .I2C_FAST_MODE              (1'b0                     ),
                .INPUT_CLK_FREQ             (SCCB_LOGIC_CLK           ),
                .LUT_ADDR_WIDTH             (LUT_ADDR_WIDTH           )
            )i2c_master_gw_init_m0(
                .rst_n                      (cmos_start_config        ),
                .clk                        (sccb_clk                 ),
                .lut_index                  (lut_index                ),
                .lut_dev_addr               (lut_data[31:24]          ),
                .lut_reg_addr               (lut_data[23:8]           ),
                .lut_reg_data               (lut_data[7:0]            ),
                .ERROR                      (i2c_err                  ),
                .DONE                       (i2c_done                 ),
                .SCL                        (cmos_scl                 ),
                .SDA                        (cmos_sda                 )
            );
        end
        
        else begin
            sccb_init_top #(
                .DEV_ADDR_WIDTH             (4'd8                     ),
                .REG_ADDR_WIDTH             (8'd16                    ),
                .REG_DATA_WIDTH             (4'd8                     ),
                .I2C_FAST_MODE              (1'b0                     ),
                .I2C_ACK_MODE               (1'b0                     ),
                .INPUT_CLK_FREQ             (SCCB_LOGIC_CLK           ),
                .LUT_ADDR_WIDTH             (LUT_ADDR_WIDTH           ) 
            )sccb_init_top_Inst(
                .rst_n                      (cmos_start_config        ),
                .clk                        (sccb_clk                 ),
                .lut_index                  (lut_index                ),
                .lut_dev_addr               (lut_data[31:24]          ),
                .lut_reg_addr               (lut_data[23:8]           ),
                .lut_reg_data               (lut_data[7:0]            ),
                //.ERROR                      (i2c_err                  ),
                .INIT_DONE                  (i2c_done                 ),
                .SCL                        (cmos_scl                 ),
                .SDA                        (cmos_sda                 ) 
            );
        end
    endgenerate

    //CMOS sensor 8bit data is converted to 16bit data
    cmos_8_16bit cmos_8_16bit_m0(
    	.rst                        (~cmos_resetn             ),
    	.pclk                       (cmos_pclk                ),
    	.pdata_i                    (cmos_db                  ),
    	.de_i                       (cmos_href                ),
    	.pdata_o                    (cmos_16bit_data          ),
    	.hblank                     (cmos_16bit_wr            ),
    	.de_o                       (cmos_16bit_clk           )
    );

    //The video output timing generator and generate a frame read data request
    //Output
    wire out_de;
    wire [11:0] active_x,active_y;
    wire [9:0] lcd_x = active_x[9:0];
    wire [9:0] lcd_y = active_y[9:0];

    generate 
        if(USE_1280 == "true") begin
            vga_timing #(
                .H_ACTIVE(16'd1280), 
                .H_FP(16'd110),
                .H_SYNC(16'd40),
                .H_BP(16'd220),
                .V_ACTIVE(16'd720),
                .V_FP(16'd5),
                .V_SYNC(16'd5),
                .V_BP(16'd20), 	
                .HS_POL(1'b1),   	
                .VS_POL(1'b1)
            ) vga_timing_m0(
                .clk (video_clk),
                .rst (~rstni),

                .active_x(active_x),
                .active_y(active_y),

                .hs(syn_off0_hs),
                .vs(syn_off0_vs),
                .de(out_de)
            );
        end
    else begin   //800x600
        vga_timing #(
            .H_ACTIVE(16'd800), 
            .H_FP(16'd40),
            .H_SYNC(16'd128),
            .H_BP(16'd88),
            .V_ACTIVE(16'd600),
            .V_FP(16'd1),
            .V_SYNC(16'd4),
            .V_BP(16'd23), 	
            .HS_POL(1'b1),   	
            .VS_POL(1'b1)
        ) vga_timing_m0(
            .clk (video_clk),
            .rst (~rstni),

            .active_x(lcd_x),
            .active_y(lcd_y),

            .hs(syn_off0_hs),
            .vs(syn_off0_vs),
            .de(out_de)
        );
    end
    endgenerate
    

    //Input testpattern
    ///--------------------------
    wire        tp0_vs_in ;
    wire        tp0_hs_in ;
    wire        tp0_de_in ;
    wire [ 7:0] tp0_data_r;
    wire [ 7:0] tp0_data_g;
    wire [ 7:0] tp0_data_b;

    generate if(USE_TPG == "true")         
    begin
        if(USE_1280 == "true") begin
            testpattern testpattern_inst_1280(
                .I_pxl_clk   (video_clk    ),//pixel clock
                .I_rst_n     (rstni        ),//low active 
                .I_mode      (3'b010       ),//data select
                .I_single_r  (8'd255       ),
                .I_single_g  (8'd255       ),
                .I_single_b  (8'd255       ),                  //800x600    //1024x768   //1280x720   //1920x1080 
                .I_h_total   (12'd1650     ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650  // 12'd2200
                .I_h_sync    (12'd40       ),//hor sync time   // 12'd128   // 12'd136   // 12'd40    // 12'd44  
                .I_h_bporch  (12'd220      ),//hor back porch  // 12'd88    // 12'd160   // 12'd220   // 12'd148 
                .I_h_res     (12'd1280     ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280  // 12'd1920
                .I_v_total   (12'd750      ),//ver total time  // 12'd628   // 12'd806   // 12'd750   // 12'd1125 
                .I_v_sync    (12'd5        ),//ver sync time   // 12'd4     // 12'd6     // 12'd5     // 12'd5   
                .I_v_bporch  (12'd20       ),//ver back porch  // 12'd23    // 12'd29    // 12'd20    // 12'd36  
                .I_v_res     (12'd720      ),//ver resolution  // 12'd600   // 12'd768   // 12'd720   // 12'd1080 
                .I_hs_pol    (1'b1         ),//0,negative;1,positive
                .I_vs_pol    (1'b1         ),//0,negative;1,positive
                .O_de        (tp0_de_in    ),   
                .O_hs        (tp0_hs_in    ),
                .O_vs        (tp0_vs_in    ),
                .O_data_r    (tp0_data_r   ),   
                .O_data_g    (tp0_data_g   ),
                .O_data_b    (tp0_data_b   )
            );
        end 
        else begin
            testpattern testpattern_inst_800(
                .I_pxl_clk   (video_clk    ),//pixel clock
                .I_rst_n     (rstni        ),//low active 
                .I_mode      (3'b000       ),//data select
                .I_single_r  (8'd100       ),
                .I_single_g  (8'd255       ),
                .I_single_b  (8'd100       ),                  //800x600    //1024x768   //1280x720   //1920x1080 
                .I_h_total   (12'd1056     ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650  // 12'd2200
                .I_h_sync    (12'd128      ),//hor sync time   // 12'd128   // 12'd136   // 12'd40    // 12'd44  
                .I_h_bporch  (12'd88       ),//hor back porch  // 12'd88    // 12'd160   // 12'd220   // 12'd148 
                .I_h_res     (12'd800      ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280  // 12'd1920
                .I_v_total   (12'd628      ),//ver total time  // 12'd628   // 12'd806   // 12'd750   // 12'd1125 
                .I_v_sync    (12'd4        ),//ver sync time   // 12'd4     // 12'd6     // 12'd5     // 12'd5   
                .I_v_bporch  (12'd23       ),//ver back porch  // 12'd23    // 12'd29    // 12'd20    // 12'd36  
                .I_v_res     (12'd600      ),//ver resolution  // 12'd600   // 12'd768   // 12'd720   // 12'd1080 
                .I_hs_pol    (1'b1         ),//0,negative;1,positive
                .I_vs_pol    (1'b1         ),//0,negative;1,positive
                .O_de        (tp0_de_in    ),   
                .O_hs        (tp0_hs_in    ),
                .O_vs        (tp0_vs_in    ),
                .O_data_r    (tp0_data_r   ),   
                .O_data_g    (tp0_data_g   ),
                .O_data_b    (tp0_data_b   )
            );
        end
    end
    endgenerate
    
    
    wire fb_vin_clk;
    wire fb_vin_vsync;
    wire [15:0] fb_vin_data;
    wire fb_vin_de;

    generate if(USE_TPG == "true")
    begin
        assign fb_vin_clk      = video_clk;
        assign fb_vin_vsync    = tp0_vs_in;
        assign fb_vin_data     = {tp0_data_r[7:3],tp0_data_g[7:2],tp0_data_b[7:3]};
        assign fb_vin_de       = tp0_de_in;
    end else begin //CMOS DATA
        assign fb_vin_clk      = cmos_16bit_clk;
        assign fb_vin_vsync    = cmos_vsync;
        assign fb_vin_data     = write_data;
        assign fb_vin_de       = cmos_16bit_wr;
    end
    endgenerate
    
    wire vfb_rstn = init_calib_complete & hdmi_hpd;
    Video_Frame_Buffer_Top Video_Frame_Buffer_Top_inst
    ( 
        .I_rst_n              (vfb_rstn         ),
        .I_dma_clk            (dma_clk          ),
    `ifdef USE_THREE_FRAME_BUFFER 
        .I_wr_halt            (1'd0             ), //1:halt,  0:no halt
        .I_rd_halt            (1'd0             ), //1:halt,  0:no halt
    `endif

        // video data input       
        .I_vin0_clk           (fb_vin_clk   ),
        .I_vin0_vs_n          (~fb_vin_vsync),  //negative only 
        .I_vin0_de            (fb_vin_de    ),
        .I_vin0_data          (fb_vin_data  ),
        .O_vin0_fifo_full     (             ),

        // video data output            
        .I_vout0_clk          (video_clk        ),
        .I_vout0_vs_n         (~syn_off0_vs     ),//negative only 
        .I_vout0_de           (out_de           ),
        .O_vout0_den          (off0_syn_de      ),
        .O_vout0_data         (off0_syn_data    ),
        .O_vout0_fifo_empty   (                 ),
        // ddr write request
        .I_cmd_ready          (cmd_ready          ),
        .O_cmd                (cmd                ),//0:write;  1:read
        .O_cmd_en             (cmd_en             ),
        //.O_app_burst_number   (app_burst_number   ),
        .O_addr               (addr               ),//[ADDR_WIDTH-1:0]
        .I_wr_data_rdy        (wr_data_rdy        ),
        .O_wr_data_en         (wr_data_en         ),//
        .O_wr_data_end        (wr_data_end        ),//
        .O_wr_data            (wr_data            ),//[DATA_WIDTH-1:0]
        .O_wr_data_mask       (wr_data_mask       ),
        .I_rd_data_valid      (rd_data_valid      ),
        .I_rd_data_end        (rd_data_end        ),//unused 
        .I_rd_data            (rd_data            ),//[DATA_WIDTH-1:0]
        .I_init_calib_complete(init_calib_complete)
    ); 

    DDR3MI u_ddr3 
    (
        .clk                (clk                ),
        .memory_clk         (memory_clk         ),
        .pll_lock           (DDR_pll_lock       ),
        .rst_n              (rstni              ),
        //.app_burst_number   (app_burst_number   ),
        .cmd_ready          (cmd_ready          ),
        .cmd                (cmd                ),
        .cmd_en             (cmd_en             ),
        .addr               (addr               ),
        .wr_data_rdy        (wr_data_rdy        ),
        .wr_data            (wr_data            ),
        .wr_data_en         (wr_data_en         ),
        .wr_data_end        (wr_data_end        ),
        .wr_data_mask       (wr_data_mask       ),
        .rd_data            (rd_data            ),
        .rd_data_valid      (rd_data_valid      ),
        .rd_data_end        (rd_data_end        ),
        .sr_req             (1'b0               ),
        .ref_req            (1'b0               ),
        .sr_ack             (                   ),
        .ref_ack            (                   ),
        .init_calib_complete(init_calib_complete),
        .clk_out            (dma_clk            ),
        .burst              (1'b1               ),
        // mem interface
        .ddr_rst            (ddr_rst          ),
        .O_ddr_addr         (ddr_addr         ),
        .O_ddr_ba           (ddr_bank         ),
        .O_ddr_cs_n         (ddr_cs           ),
        .O_ddr_ras_n        (ddr_ras          ),
        .O_ddr_cas_n        (ddr_cas          ),
        .O_ddr_we_n         (ddr_we           ),
        .O_ddr_clk          (ddr_ck           ),
        .O_ddr_clk_n        (ddr_ck_n         ),
        .O_ddr_cke          (ddr_cke          ),
        .O_ddr_odt          (ddr_odt          ),
        .O_ddr_reset_n      (ddr_reset_n      ),
        .O_ddr_dqm          (ddr_dm           ),
        .IO_ddr_dq          (ddr_dq           ),
        .IO_ddr_dqs         (ddr_dqs          ),
        .IO_ddr_dqs_n       (ddr_dqs_n        )
    );
    //==============================================================================
    //TMDS TX(HDMI4)

    //---------------------------------------------
    wire [4:0] lcd_r,lcd_b;
    wire [5:0] lcd_g;
    wire lcd_vs,lcd_de,lcd_hs,lcd_dclk;
    
    assign {lcd_r,lcd_g,lcd_b}    = off0_syn_de ? off0_syn_data[15:0] : 16'h0000;//{r,g,b}
    assign lcd_vs      			  = Pout_vs_dn[1];//syn_off0_vs;
    assign lcd_hs      			  = Pout_hs_dn[1];//syn_off0_hs;
    assign lcd_de      			  = Pout_de_dn[1];//off0_syn_de;
    assign lcd_dclk    			  = video_clk;//video_clk_phs;

    reg  [1:0]  Pout_hs_dn;
    reg  [1:0]  Pout_vs_dn;
    reg  [1:0]  Pout_de_dn;

    always@(posedge video_clk or negedge rstni)
    begin
        if(!rstni) begin                          
            Pout_hs_dn  <= {2'b11};
            Pout_vs_dn  <= {2'b11}; 
            Pout_de_dn  <= {2'b00}; 
        end
        else begin                          
            Pout_hs_dn  <= {Pout_hs_dn[0],syn_off0_hs};
            Pout_vs_dn  <= {Pout_vs_dn[0],syn_off0_vs}; 
            Pout_de_dn  <= {Pout_de_dn[0],out_de}; 
        end
    end

    wire dvi0_rgb_clk;
    wire dvi0_rgb_vs ;
    wire dvi0_rgb_hs ;
    wire dvi0_rgb_de ;
    wire [7:0] dvi0_rgb_r  ;
    wire [7:0] dvi0_rgb_g  ;
    wire [7:0] dvi0_rgb_b  ;

    wire dvi1_rgb_clk;
    wire dvi1_rgb_vs ;
    wire dvi1_rgb_hs ;
    wire dvi1_rgb_de ;
    wire [7:0] dvi1_rgb_r  ;
    wire [7:0] dvi1_rgb_g  ;
    wire [7:0] dvi1_rgb_b  ;

    generate if(USE_TPG == "true")
    begin
        //DVI 1 use DDR & Framebuffer
        assign dvi0_rgb_clk = lcd_dclk;
        assign dvi0_rgb_vs  = lcd_vs;
        assign dvi0_rgb_hs  = lcd_hs;
        assign dvi0_rgb_de  = lcd_de;
        assign dvi0_rgb_r   = {lcd_r,3'd0};
        assign dvi0_rgb_g   = {lcd_g,2'd0};
        assign dvi0_rgb_b   = {lcd_b,3'd0};
        //DVI2 directly use TPG video
        assign dvi1_rgb_clk = video_clk ;
        assign dvi1_rgb_vs  = tp0_vs_in ;
        assign dvi1_rgb_hs  = tp0_hs_in ;
        assign dvi1_rgb_de  = tp0_de_in ;
        assign dvi1_rgb_r   = tp0_data_r;
        assign dvi1_rgb_g   = tp0_data_g;
        assign dvi1_rgb_b   = tp0_data_b;
    end 
    else begin
        assign dvi0_rgb_clk = lcd_dclk;
        assign dvi0_rgb_vs  = lcd_vs;
        assign dvi0_rgb_hs  = lcd_hs;
        assign dvi0_rgb_de  = lcd_de;
        assign dvi0_rgb_r   = {lcd_r,3'd0};
        assign dvi0_rgb_g   = {lcd_g,2'd0};
        assign dvi0_rgb_b   = {lcd_b,3'd0};

        assign dvi1_rgb_clk = lcd_dclk;
        assign dvi1_rgb_vs  = lcd_vs;
        assign dvi1_rgb_hs  = lcd_hs;
        assign dvi1_rgb_de  = lcd_de;
        assign dvi1_rgb_r   = {lcd_r,3'd0};
        assign dvi1_rgb_g   = {lcd_g,2'd0};
        assign dvi1_rgb_b   = {lcd_b,3'd0};
    end
    endgenerate

    wire hdmi4_rst_n = rstni & TMDS_pll_lock & hdmi_hpd;

    DVI_TX_Top DVI_TX_Top_inst0
    (
        .I_rst_n       (hdmi4_rst_n   ),  //asynchronous reset, low active
        .I_serial_clk  (serial_clk    ),

        //CMOS
        .I_rgb_clk     (dvi0_rgb_clk),  //pixel clock
        .I_rgb_vs      (dvi0_rgb_vs ), 
        .I_rgb_hs      (dvi0_rgb_hs ),    
        .I_rgb_de      (dvi0_rgb_de ), 
        .I_rgb_r       (dvi0_rgb_r  ), 
        .I_rgb_g       (dvi0_rgb_g  ),  
        .I_rgb_b       (dvi0_rgb_b  ),  

        .O_tmds_clk_p  (tmds_clk_p  ),
        .O_tmds_clk_n  (tmds_clk_n  ),
        .O_tmds_data_p (tmds_d_p    ),  //{r,g,b}
        .O_tmds_data_n (tmds_d_n    )
    );

endmodule