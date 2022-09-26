//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.07 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18C
//Created Time: Tue Aug 23 21:47:10 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	DDR3MI your_instance_name(
		.memory_clk(memory_clk_i), //input memory_clk
		.clk(clk_i), //input clk
		.pll_lock(pll_lock_i), //input pll_lock
		.rst_n(rst_n_i), //input rst_n
		.app_burst_number(app_burst_number_i), //input [5:0] app_burst_number
		.cmd_ready(cmd_ready_o), //output cmd_ready
		.cmd(cmd_i), //input [2:0] cmd
		.cmd_en(cmd_en_i), //input cmd_en
		.addr(addr_i), //input [27:0] addr
		.wr_data_rdy(wr_data_rdy_o), //output wr_data_rdy
		.wr_data(wr_data_i), //input [127:0] wr_data
		.wr_data_en(wr_data_en_i), //input wr_data_en
		.wr_data_end(wr_data_end_i), //input wr_data_end
		.wr_data_mask(wr_data_mask_i), //input [15:0] wr_data_mask
		.rd_data(rd_data_o), //output [127:0] rd_data
		.rd_data_valid(rd_data_valid_o), //output rd_data_valid
		.rd_data_end(rd_data_end_o), //output rd_data_end
		.sr_req(sr_req_i), //input sr_req
		.ref_req(ref_req_i), //input ref_req
		.sr_ack(sr_ack_o), //output sr_ack
		.ref_ack(ref_ack_o), //output ref_ack
		.init_calib_complete(init_calib_complete_o), //output init_calib_complete
		.clk_out(clk_out_o), //output clk_out
		.ddr_rst(ddr_rst_o), //output ddr_rst
		.burst(burst_i), //input burst
		.O_ddr_addr(O_ddr_addr_o), //output [13:0] O_ddr_addr
		.O_ddr_ba(O_ddr_ba_o), //output [2:0] O_ddr_ba
		.O_ddr_cs_n(O_ddr_cs_n_o), //output O_ddr_cs_n
		.O_ddr_ras_n(O_ddr_ras_n_o), //output O_ddr_ras_n
		.O_ddr_cas_n(O_ddr_cas_n_o), //output O_ddr_cas_n
		.O_ddr_we_n(O_ddr_we_n_o), //output O_ddr_we_n
		.O_ddr_clk(O_ddr_clk_o), //output O_ddr_clk
		.O_ddr_clk_n(O_ddr_clk_n_o), //output O_ddr_clk_n
		.O_ddr_cke(O_ddr_cke_o), //output O_ddr_cke
		.O_ddr_odt(O_ddr_odt_o), //output O_ddr_odt
		.O_ddr_reset_n(O_ddr_reset_n_o), //output O_ddr_reset_n
		.O_ddr_dqm(O_ddr_dqm_o), //output [1:0] O_ddr_dqm
		.IO_ddr_dq(IO_ddr_dq_io), //inout [15:0] IO_ddr_dq
		.IO_ddr_dqs(IO_ddr_dqs_io), //inout [1:0] IO_ddr_dqs
		.IO_ddr_dqs_n(IO_ddr_dqs_n_io) //inout [1:0] IO_ddr_dqs_n
	);

//--------Copy end-------------------
