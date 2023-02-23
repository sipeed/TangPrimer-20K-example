create_clock -name ulpi_clk -period 16.667 -waveform {0 5.75} [get_ports {ulpi_clk}]
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
set_clock_latency -source 0.4 [get_clocks {ulpi_clk}] 
