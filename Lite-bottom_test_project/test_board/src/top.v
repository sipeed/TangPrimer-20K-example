module top
#(
    parameter frequency     = 27_000_000,       // OSCILLATOR frequency
    parameter default_count = (frequency/10)*5, // 0.5s
    parameter counter_1     = (frequency/10)*2, // 0.2s
    parameter counter_2     = (frequency/10)*8, // 0.8s
    parameter counter_3     = (frequency/10)*12, // 1.2s
    parameter counter_4     = (frequency/10)*20, // 2s
    
    parameter onboard_pins  = 5-1,

    //parameter switch_val    = 2,

    parameter io_count = 104                  // IO numbers
)
(    
  clk ,
  rst_n,
  user_key,
  led_o,
  onboard_pin,
  //switch,

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

  input                     clk ; // Clock in
  input      [1:0]          rst_n;
  input      [4:1]          user_key;
  output     [io_count-1:0] led_o;


  output [onboard_pins:0] onboard_pin;
  assign onboard_pin[onboard_pins:0] = led_o[onboard_pins:0];

key_blink #(
    .frequency     (frequency),
    .default_count (default_count),
    .counter_1     (counter_1),
    .counter_2     (counter_2),
    .counter_3     (counter_3),
    .counter_4     (counter_4),
    .io_count      (io_count)
)key_blink_inst(
  .clk(clk) , // Clock in
  .rst_n_i(rst_n),
  .user_key(user_key),
  .led_o(led_o)
);

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


ddr3_syn_top ddr3_syn_top_inst
  (
    .clk(clk),
    .ddr_addr(ddr_addr),
    .ddr_bank(ddr_bank),
    .ddr_cs(ddr_cs),
    .ddr_ras(ddr_ras),
    .ddr_cas(ddr_cas),
    .ddr_we(ddr_we),
    .ddr_ck(ddr_ck),
    .ddr_ck_n(ddr_ck_n),
    .ddr_cke(ddr_cke),
    .ddr_odt(ddr_odt),
    .ddr_reset_n(ddr_reset_n),
    .ddr_dm(ddr_dm),
    .ddr_dq(ddr_dq),
    .ddr_dqs(ddr_dqs),
    .ddr_dqs_n(ddr_dqs_n),
    .uart_txp(uart_txp)
  );


endmodule