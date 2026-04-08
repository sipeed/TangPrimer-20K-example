module clk_init(
    input  wire     clkin,
    input  wire     rst_n,
    output wire     clk_37M,
    output wire     clk_50M,
    output wire     cmos_clk,
    output wire     memory_clk,
    output wire     clk_5x,
    output wire     clk_1x,
    output wire     cmos_pll_lock,
    output wire     DDR_pll_lock,
    output wire     TMDS_pll_lock
);

//    cmos_pll cmos_pll_m0(
//        .clkin                     (clkin                      	),
//        .reset                     (~rst_n                   		),
//        .lock                      (cmos_pll_lock             	),
//        .clkout                    (         	              		),
//        .clkoutd                   (clk_35M 	              		),
//        .clkoutd3                  (cmos_clk 	              		)
//   	);

    assign cmos_pll_lock = 1'b1;
    
    wire clk_100M;
    mem_pll u_mem_pll(
        .clkin                     (clkin                           ),
        .reset                     (~rst_n                   		),
        .clkout                    (memory_clk 	              		),
        .clkoutd3                  (clk_100M 	              		),
        .lock 					   (DDR_pll_lock 					)
   	);

    CLKDIV u_clkdiv4(
        .RESETN(DDR_pll_lock),
        .HCLKIN(clk_100M    ),   
        .CLKOUT(cmos_clk    ),
        .CALIB (1'b1        )
    );
    defparam u_clkdiv4.DIV_MODE="4";
    defparam u_clkdiv4.GSREN="false";

    CLKDIV u_clkdiv2(
        .RESETN(DDR_pll_lock),
        .HCLKIN(clk_100M    ),   
        .CLKOUT(clk_50M     ),
        .CALIB (1'b1        )
    );
    defparam u_clkdiv2.DIV_MODE="2";
    defparam u_clkdiv2.GSREN="false";

    TMDS_rPLL u_tmds_rpll(
        .clkin     (clkin            ),     //input clk 
        .reset     (~rst_n           ),
        .clkout    (clk_5x           ),     //output clk 
        .clkoutd   (clk_37M 	     ),
        .lock      (TMDS_pll_lock    )      //output lock
    );
    
    wire hdmi_rst_n = rst_n & TMDS_pll_lock;

    CLKDIV u_clkdiv5(
        .RESETN(hdmi_rst_n ),
        .HCLKIN(clk_5x     ),    //clk  x5
        .CLKOUT(clk_1x     ),    //clk  x1
        .CALIB (1'b1       )
    );
    defparam u_clkdiv5.DIV_MODE="5";
    defparam u_clkdiv5.GSREN="false";

endmodule
