//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12.02_SP1 (64-bit) 
//Created Time: 2026-04-08 17:05:21

//SYS CLK 27MHz
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]

// PLL1 mem_pll
create_generated_clock -name mem_clk  -source [get_ports {clk}] -master_clock clk -divide_by 27 -multiply_by 300 [get_pins {u_clk_init/u_mem_pll/rpll_inst/CLKOUT}]
create_generated_clock -name cam_xclk -source [get_ports {clk}] -master_clock clk -divide_by 27  -multiply_by 25 [get_pins {u_clk_init/u_clkdiv4/CLKOUT}]
//create_generated_clock -name clk_50m  -source [get_ports {clk}] -master_clock clk -divide_by 27  -multiply_by 50 [get_pins {u_clk_init/u_clkdiv2/CLKOUT}]

// PLL2 tmds_pll
create_generated_clock -name clk_tmds_5x -source [get_ports {clk}] -master_clock clk -divide_by 4  -multiply_by 55 [get_pins {u_clk_init/u_tmds_rpll/rpll_inst/CLKOUT}]
create_generated_clock -name clk_74_25   -source [get_ports {clk}] -master_clock clk -divide_by 4 -multiply_by 11 [get_pins {u_clk_init/u_clkdiv5/CLKOUT}]

//ddr3 phy clk
create_generated_clock -name clk_x1 -source [get_pins {u_clk_init/u_mem_pll/rpll_inst/CLKOUT}] -master_clock mem_clk -divide_by 4 -multiply_by 1 [get_pins {u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]

//camera pclk
create_clock -name cmos_pclk -period 5.88 -waveform {0 2.94} [get_ports {cmos_pclk}]
create_generated_clock -name cmos_pclk_div2 -source [get_ports {cmos_pclk}] -master_clock cmos_pclk -divide_by 2 -multiply_by 1 [get_nets {cmos_16bit_clk}]
create_clock -name cmos_vsync -period 10000 -waveform {0 5000} [get_ports {cmos_vsync}]

set_clock_groups -asynchronous -group [get_clocks {clk_tmds_5x}] 
                               -group [get_clocks {clk_74_25}] 
//                               -group [get_clocks {clk_50m}] 
                               -group [get_clocks {clk_x1}] 
                               -group [get_clocks {cam_xclk}] 
                               -group [get_clocks {mem_clk}] 
                               -group [get_clocks {cmos_pclk}] 
                               -group [get_clocks {cmos_vsync}] 
                               -group [get_clocks {clk}]
                               -group [get_clocks {cmos_pclk_div2}] 