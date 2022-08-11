//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.05 
//Created Time: 2022-05-06 23:08:41
create_clock -name clk_x1 -period 10 -waveform {0 5} [get_nets {clk_x1}]
create_clock -name clk_x4 -period 2.5 -waveform {0 1.25} [get_nets {memory_clk}]
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
set_clock_groups -asynchronous -group [get_clocks {clk_x1}] -group [get_clocks {clk_x4}] -group [get_clocks {clk}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
