//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 
//Created Time: 2023-06-05 12:08:50
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_clock -name clk50 -period 20 -waveform {0 10} [get_ports {netrmii_clk50m}]
create_clock -name clk1 -period 1000 -waveform {0 500} [get_nets {netrmii_mdc_d}]
set_false_path -from [get_clocks {clk1}] -to [get_clocks {clk50}] 
set_false_path -from [get_clocks {clk50}] -to [get_clocks {clk1}] 
