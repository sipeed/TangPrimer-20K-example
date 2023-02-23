module top(
    input  wire       rst_n,
    input   clk,
    output wire       ulpi_rst,
    input  wire       ulpi_clk,
    input  wire       ulpi_dir,
    input  wire       ulpi_nxt,
    output wire       ulpi_stp,
    inout  wire [7:0] ulpi_data
);

wire [7:0] data;
wire rx_av;
wire tx_av;
wire clk120;


Gowin_rPLL pll(
        .clkout(clk120), //output clkout
        .clkin(clk) //input clkin
    );

usb_wrapper usb(
    .rst_n(rst_n),
    .clk(clk120),

    .data_o(data),
    .rdav(rx_av),
    .rden(tx_av),

    .data_i(data),
    .wrav(tx_av),
    .wren(rx_av),

    .ulpi_rst(ulpi_rst),
    .ulpi_clk(ulpi_clk),
    .ulpi_dir(ulpi_dir),
    .ulpi_nxt(ulpi_nxt),
    .ulpi_stp(ulpi_stp),
    .ulpi_data(ulpi_data)
);

endmodule
