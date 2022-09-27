module top (
	input 		clk,    // Clock

	output reg	sk9822_ck,
	output reg  sk9822_da
);

parameter SD9822_NUM = 12;//串联灯珠数量

parameter FRAME_LEN  = 32;//数据帧长度

//起始帧
parameter START_FRAME = 32'H00000000;
//结束帧
parameter END_FRAME   = 32'HFFFFFFFF;
//数据帧
parameter LED_LIGHT = 5'B01111; //全局亮度
reg [23:0] data_rgb = 24'h000001; //具体颜色
wire [31:0] data_frame = {3'b111,LED_LIGHT,data_rgb};
assign data_frame = {3'b111,LED_LIGHT,data_rgb};

//clk降频 大概 1M
parameter CLK_FRE = 27_000_000;
reg [23:0] clk_delay;
wire clk_slow = clk_delay[13];
always@(posedge clk) clk_delay <= clk_delay + 1;

//发送状态机
reg [31:0] send_frame;
reg [6:0] send_frame_cnt = 0;
reg [4:0] send_bit_cnt = 0;
reg 	  send_bit;
always@(posedge clk_slow)
	if(!sk9822_ck)begin //上升沿发送
		sk9822_ck <= 1;
	end
	else begin     //下降沿取值
		sk9822_ck <= 0;
		sk9822_da <= send_frame[(FRAME_LEN - 1) - send_bit_cnt];
		send_bit_cnt <= send_bit_cnt + 1;
		
		if(send_bit_cnt == FRAME_LEN - 1)
			send_frame_cnt <= (send_frame_cnt < (SD9822_NUM + 1))? send_frame_cnt + 1 : 0;
	end
	
//发送数据控制
always@(*)
	if(send_frame_cnt == 0)
		send_frame = START_FRAME;
	else if(send_frame_cnt == (SD9822_NUM + 1))
		send_frame = END_FRAME;
	else
		send_frame = data_frame;

//颜色转移状态机
always@(posedge clk_slow)
	if(send_frame_cnt ==(SD9822_NUM + 1) & send_bit_cnt == 0)
		data_rgb <= {data_rgb[22:0],data_rgb[23]};//24位RGB移位显示

endmodule