//Copyright (C)2014-2026 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12.02_SP1 (64-bit)
//IP Version: 2.4
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Wed Apr  8 14:51:48 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Video_Frame_Buffer_Top your_instance_name(
		.I_rst_n(I_rst_n), //input I_rst_n
		.I_dma_clk(I_dma_clk), //input I_dma_clk
		.I_wr_halt(I_wr_halt), //input [0:0] I_wr_halt
		.I_rd_halt(I_rd_halt), //input [0:0] I_rd_halt
		.I_vin0_clk(I_vin0_clk), //input I_vin0_clk
		.I_vin0_vs_n(I_vin0_vs_n), //input I_vin0_vs_n
		.I_vin0_de(I_vin0_de), //input I_vin0_de
		.I_vin0_data(I_vin0_data), //input [15:0] I_vin0_data
		.O_vin0_fifo_full(O_vin0_fifo_full), //output O_vin0_fifo_full
		.I_vout0_clk(I_vout0_clk), //input I_vout0_clk
		.I_vout0_vs_n(I_vout0_vs_n), //input I_vout0_vs_n
		.I_vout0_de(I_vout0_de), //input I_vout0_de
		.O_vout0_den(O_vout0_den), //output O_vout0_den
		.O_vout0_data(O_vout0_data), //output [15:0] O_vout0_data
		.O_vout0_fifo_empty(O_vout0_fifo_empty), //output O_vout0_fifo_empty
		.I_cmd_ready(I_cmd_ready), //input I_cmd_ready
		.O_cmd(O_cmd), //output [2:0] O_cmd
		.O_cmd_en(O_cmd_en), //output O_cmd_en
		.O_addr(O_addr), //output [26:0] O_addr
		.I_wr_data_rdy(I_wr_data_rdy), //input I_wr_data_rdy
		.O_wr_data_en(O_wr_data_en), //output O_wr_data_en
		.O_wr_data_end(O_wr_data_end), //output O_wr_data_end
		.O_wr_data(O_wr_data), //output [127:0] O_wr_data
		.O_wr_data_mask(O_wr_data_mask), //output [15:0] O_wr_data_mask
		.I_rd_data_valid(I_rd_data_valid), //input I_rd_data_valid
		.I_rd_data_end(I_rd_data_end), //input I_rd_data_end
		.I_rd_data(I_rd_data), //input [127:0] I_rd_data
		.I_init_calib_complete(I_init_calib_complete) //input I_init_calib_complete
	);

//--------Copy end-------------------
