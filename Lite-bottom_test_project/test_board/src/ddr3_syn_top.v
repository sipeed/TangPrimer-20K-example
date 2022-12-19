`timescale 1ps /1ps

module ddr3_syn_top
  (
    clk,


    ddr_addr,
    ddr_bank,
    ddr_cs,
    ddr_ras,
    ddr_cas,
    ddr_we,
    ddr_ck,
    ddr_ck_n,
    ddr_cke,
    ddr_odt,
    ddr_reset_n,
    ddr_dm,
    ddr_dq,
    ddr_dqs,
    ddr_dqs_n,

    uart_txp
  );

  input                       clk;

  output [14-1:0]             ddr_addr;       //ROW_WIDTH=14
  output [3-1:0]              ddr_bank;       //BANK_WIDTH=3
  output                      ddr_cs;
  output                      ddr_ras;
  output                      ddr_cas;
  output                      ddr_we;
  output                      ddr_ck;
  output                      ddr_ck_n;
  output                      ddr_cke;
  output                      ddr_odt;
  output                      ddr_reset_n;
  output [2-1:0]              ddr_dm;         //DM_WIDTH=2
  inout [16-1:0]              ddr_dq;         //DQ_WIDTH=16
  inout [2-1:0]               ddr_dqs;        //DQS_WIDTH=2
  inout [2-1:0]               ddr_dqs_n;      //DQS_WIDTH=2

  output                      uart_txp;

  wire                        memory_clk;
  wire                        pll_lock;


  assign ddr_cs = 1'b0;


  wire rst_n;
  wire clk_x1;
  //IDK why Gowin Set the addr width to 28. But it should be 27
  wire [27-1:0]             app_addr;        //ADDR_WIDTH=27

  wire                      app_cmd_en;
  wire [2:0]                app_cmd;
  wire                      app_cmd_rdy;

  wire                      app_wren;
  wire                      app_data_end;
  wire [128-1:0]            app_data;    //APP_DATA_WIDTH=128
  wire                      app_data_rdy;

  wire                      app_rdata_valid;
  wire                      app_rdata_end;
  wire [128-1:0]            app_rdata;     //APP_DATA_WIDTH=128

  wire                      init_calib_complete;
  wire [5:0]                app_burst_number;

  tester test(
    .clk(clk),
    .rst_n(rst_n),

    .clk_x1(clk_x1),
    .app_addr(app_addr),

    .app_cmd_en(app_cmd_en),
    .app_cmd(app_cmd),
    .app_cmd_rdy(app_cmd_rdy),

    .app_wren(app_wren),
    .app_data_end(app_data_end),
    .app_data(app_data),
    .app_data_rdy(app_data_rdy),

    .app_rdata_valid(app_rdata_valid),
    .app_rdata_end(app_rdata_end),
    .app_rdata(app_rdata),

    .init_calib_complete(init_calib_complete),
    .app_burst_number(app_burst_number),

    .txp(uart_txp)
  );



  Gowin_rPLL pll(
               .clkout(memory_clk), //output clkout
               .lock(pll_lock), //output lock
               .reset(~rst_n), //input reset
               .clkin(clk) //input clkin
             );



  //ddr3_memory_top u_ddr3 (
  DDR3_Memory_Interface_Top u_ddr3 (
                              .clk             (clk),
                              .memory_clk      (memory_clk),
                              .pll_lock        (pll_lock),
                              .rst_n           (rst_n),   //rst_n
                              .app_burst_number(app_burst_number),
                              .cmd_ready       (app_cmd_rdy),
                              .cmd             (app_cmd),
                              .cmd_en          (app_cmd_en),
                              .addr            ({1'b0,app_addr}),//IDK why Gowin Set the addr width to 28. But it should be 27
                              .wr_data_rdy     (app_data_rdy),
                              .wr_data         (app_data),
                              .wr_data_en      (app_wren),
                              .wr_data_end     (app_data_end),
                              .wr_data_mask    (16'h0000),
                              .rd_data         (app_rdata),
                              .rd_data_valid   (app_rdata_valid),
                              .rd_data_end     (app_rdata_end),
                              .sr_req          (1'b0),
                              .ref_req         (1'b0),
                              .sr_ack          (),
                              .ref_ack         (),
                              .init_calib_complete(init_calib_complete),
                              .clk_out         (clk_x1),
                              .burst           (1'b1),

                              // mem interface
                              .ddr_rst         (),
                              .O_ddr_addr      (ddr_addr),
                              .O_ddr_ba        (ddr_bank),
                              .O_ddr_cs_n      (ddr_cs1),
                              .O_ddr_ras_n     (ddr_ras),
                              .O_ddr_cas_n     (ddr_cas),
                              .O_ddr_we_n      (ddr_we),
                              .O_ddr_clk       (ddr_ck),
                              .O_ddr_clk_n     (ddr_ck_n),
                              .O_ddr_cke       (ddr_cke),
                              .O_ddr_odt       (ddr_odt),
                              .O_ddr_reset_n   (ddr_reset_n),
                              .O_ddr_dqm       (ddr_dm),
                              .IO_ddr_dq       (ddr_dq),
                              .IO_ddr_dqs      (ddr_dqs),
                              .IO_ddr_dqs_n    (ddr_dqs_n)
                            );


endmodule







