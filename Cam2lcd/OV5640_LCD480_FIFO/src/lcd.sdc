create_clock -name clk       -period 37 [get_ports {clk}] -add
create_clock -name cmos_pclk -period 10 [get_ports {cmos_pclk}] -add
create_clock -name cmos_vsync -period 1000 [get_ports {cmos_vsync}] -add