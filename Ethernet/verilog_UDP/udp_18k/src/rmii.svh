`ifndef RMII_INTERFACE
`define RMII_INTERFACE
interface rmii(
    input clk50m, rx_crs,
    output mdc, txen,
    inout mdio,
    output [1:0] txd,
    input [1:0] rxd
);
/*
    logic clk50m;

    logic [1:0] txd;
    logic txen;
    logic [1:0] rxd;
    logic rx_crs;

    logic mdc;
    logic mdio;
*/
endinterface //rmii
`endif //RMII_INTERFACE