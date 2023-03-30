module top(
    input        clk      ,
    input        rst_n    , //S1按键
    
    //pt8211接口
    output       HP_BCK   , //同clk_1p536m
    output       HP_WS    , //左右声道切换信号，低电平对应左声道
    output       HP_DIN   , //dac串行数据输入信号
    output       PA_EN    , //音频功放使能，高电平有效

    output reg   led
);


wire clk_6m_w;//6MHz,为产生1.5MHz
wire clk_1p5m_w;//1.536MHz近似时钟

Gowin_rPLL pll_27m_6m (
    .clkout(clk_6m_w), 
    .reset(~rst_n), 
    .clkin(clk)
    );

Gowin_CLKDIV clk_div4(
        .clkout(clk_1p5m_w), //output clkout
        .hclkin(clk_6m_w), //input hclkin
        .resetn(rst_n) //input resetn
    );

wire req_w;//读请求
wire rd_empty;//fifo read empty
wire [15:0] q_w;//rom读出的数据
reg [9:0] addr_r;//rom地址

assign PA_EN = 1'b1;//PA常开

always@(posedge clk_1p5m_w or negedge rst_n)
if(!rst_n)
    addr_r <= 10'd0;
else if(addr_r <= 'd255)
    addr_r <= req_w?addr_r+1'b1:addr_r;
else
    addr_r <= 10'd0;

rom_save_sin rom_save_sin_inst(
.clk(clk_6m_w),
.rst_n(rst_n),
.addr(addr_r),
.data(q_w)
);

//音频DAC驱动
pt8211_drive u_pt8211_drive_0(
    .clk_1p536m(clk_1p5m_w),//bit时钟，每个采样点占32个clk_1p536m(左右声道各16)
    .rst_n     (rst_n),//低电平有效异步复位信号
    //用户数据接口
    .idata     (q_w),
    .req       (req_w),//数据请求信号，可接外部FIFO的读请求(为避免空读，尽量和!fifo_empty相与后作为fifo_rd)
    //pt8211接口
    .HP_BCK   (HP_BCK),//同clk_1p536m
    .HP_WS    (HP_WS),//左右声道切换信号，低电平对应左声道
    .HP_DIN   (HP_DIN)//dac串行数据输入信号
);

reg [23:0] counter;        //定义一个变量来计数

always @(posedge clk or negedge rst_n) begin // Counter block
    if (!rst_n)
        counter <= 24'd0;
    else if (counter < 24'd1349_9999)       // 0.5s delay
        counter <= counter + 1'b1;
    else
        counter <= 24'd0;
end

always @(posedge clk or negedge rst_n) begin // Toggle LED
    if (!rst_n)
        led <= 1'b1;
    else if (counter == 24'd1349_9999)       // 0.5s delay
        led <= ~led;                         // ToggleLED
end



endmodule