//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.07 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18C
//Created Time: Sat Sep 24 16:37:16 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Video_Frame_Buffer_Top your_instance_name(
		.I_rst_n(I_rst_n_i), //input I_rst_n
		.I_dma_clk(I_dma_clk_i), //input I_dma_clk
		.I_wr_halt(I_wr_halt_i), //input [0:0] I_wr_halt
		.I_rd_halt(I_rd_halt_i), //input [0:0] I_rd_halt
		.I_vin0_clk(I_vin0_clk_i), //input I_vin0_clk
		.I_vin0_vs_n(I_vin0_vs_n_i), //input I_vin0_vs_n
		.I_vin0_de(I_vin0_de_i), //input I_vin0_de
		.I_vin0_data(I_vin0_data_i), //input [15:0] I_vin0_data
		.O_vin0_fifo_full(O_vin0_fifo_full_o), //output O_vin0_fifo_full
		.I_vout0_clk(I_vout0_clk_i), //input I_vout0_clk
		.I_vout0_vs_n(I_vout0_vs_n_i), //input I_vout0_vs_n
		.I_vout0_de(I_vout0_de_i), //input I_vout0_de
		.O_vout0_den(O_vout0_den_o), //output O_vout0_den
		.O_vout0_data(O_vout0_data_o), //output [15:0] O_vout0_data
		.O_vout0_fifo_empty(O_vout0_fifo_empty_o), //output O_vout0_fifo_empty
		.I_cmd_ready(I_cmd_ready_i), //input I_cmd_ready
		.O_cmd(O_cmd_o), //output [2:0] O_cmd
		.O_cmd_en(O_cmd_en_o), //output O_cmd_en
		.O_app_burst_number(O_app_burst_number_o), //output [5:0] O_app_burst_number
		.O_addr(O_addr_o), //output [27:0] O_addr
		.I_wr_data_rdy(I_wr_data_rdy_i), //input I_wr_data_rdy
		.O_wr_data_en(O_wr_data_en_o), //output O_wr_data_en
		.O_wr_data_end(O_wr_data_end_o), //output O_wr_data_end
		.O_wr_data(O_wr_data_o), //output [127:0] O_wr_data
		.O_wr_data_mask(O_wr_data_mask_o), //output [15:0] O_wr_data_mask
		.I_rd_data_valid(I_rd_data_valid_i), //input I_rd_data_valid
		.I_rd_data_end(I_rd_data_end_i), //input I_rd_data_end
		.I_rd_data(I_rd_data_i), //input [127:0] I_rd_data
		.I_init_calib_complete(I_init_calib_complete_i) //input I_init_calib_complete
	);

//--------Copy end-------------------
