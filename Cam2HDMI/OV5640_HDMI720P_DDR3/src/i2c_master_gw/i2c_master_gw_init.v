module i2c_master_gw_init #(
    parameter DEV_ADDR_WIDTH = 4'd8,
    parameter REG_ADDR_WIDTH = 8'd16,
    parameter REG_DATA_WIDTH = 4'd8,
    parameter I2C_FAST_MODE  = 1'b0,
    parameter INPUT_CLK_FREQ = 26'd35_000_000,
    parameter LUT_ADDR_WIDTH = 4'd8
)(
    input                        clk,
    input                        rst_n,

    input  [DEV_ADDR_WIDTH -1:0] lut_dev_addr,
    input  [REG_ADDR_WIDTH -1:0] lut_reg_addr,
    input  [REG_DATA_WIDTH -1:0] lut_reg_data,

    output [LUT_ADDR_WIDTH -1:0] lut_index,
    output                       ERROR,
    output                       DONE,
    inout                        SCL,
    inout                        SDA
);

    wire    [DEV_ADDR_WIDTH + REG_ADDR_WIDTH + REG_DATA_WIDTH - 1 : 0] lut_data;

    assign   lut_data = {lut_dev_addr, lut_reg_addr, lut_reg_data};

    I2C_MASTER_GW_Top I2C_MASTER_GW_Top_Inst(
	    .I_CLK      (clk            ),     //input I_CLK
	    .I_RESETN   (rst_n          ),     //input I_RESETN
	    .I_TX_EN    (I_TX_EN        ),     //input I_TX_EN
	    .I_WADDR    (I_WADDR        ),     //input [2:0] I_WADDR
	    .I_WDATA    (I_WDATA        ),     //input [7:0] I_WDATA
	    .I_RX_EN    (I_RX_EN        ),     //input I_RX_EN
	    .I_RADDR    (I_RADDR        ),     //input [2:0] I_RADDR
	    .O_RDATA    (O_RDATA        ),     //output [7:0] O_RDATA
	    .O_IIC_INT  (O_IIC_INT      ),     //output O_IIC_INT
	    .SCL        (SCL            ),     //inout SCL
	    .SDA        (SDA            )      //inout SDA
	);

    assign I2C_PRESCALE = I2C_FAST_MODE ? 16'h0010 : 16'h0045;

    gw_i2c_lut_write #(
        .LUT_AW     (LUT_ADDR_WIDTH ),
        .CLK_FREQ   (INPUT_CLK_FREQ ),
        .RST_DLY_MS (2'd2           )
    ) gw_i2c_lut_write_Inst(
        .I_CLK      (clk            ), 
        .I_RESETN   (rst_n          ), 
        .I_TX_EN    (I_TX_EN        ),
        .I_WADDR    (I_WADDR        ),
        .I_WDATA    (I_WDATA        ),
        .I_RX_EN    (I_RX_EN        ),
        .I_RADDR    (I_RADDR        ),
        .O_RDATA    (O_RDATA        ),
        .ERROR      (ERROR          ),
        .DONE       (DONE           ),
        .SCL        (SCL            ),
        .SDA        (SDA            ),
        .PRESCALE   (I2C_PRESCALE   ),
        .lut_data   (lut_data       ),
        .lut_index  (lut_index      ) 
    );

endmodule

    