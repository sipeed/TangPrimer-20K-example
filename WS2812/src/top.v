module top (
	input 		clk,  //输入 时钟源  

	output reg WS2812 //输出到WS2812的接口
	
);
parameter WS2812_NUM 	= 1  - 1     ; // WS2812的LED数量(1从0开始)
parameter WS2812_WIDTH 	= 24 	     ; // WS2812的数据位宽
parameter CLK_FRE 	 	= 27_000_000	 	 ; // CLK的频率(mHZ)

parameter DELAY_1_HIGH 	= (CLK_FRE / 1_000_000 * 0.85 )  - 1; //≈850ns±150ns     1 高电平时间
parameter DELAY_1_LOW 	= (CLK_FRE / 1_000_000 * 0.40 )  - 1; //≈400ns±150ns 	 1 低电平时间
parameter DELAY_0_HIGH 	= (CLK_FRE / 1_000_000 * 0.40 )  - 1; //≈400ns±150ns 	 0 高电平时间
parameter DELAY_0_LOW 	= (CLK_FRE / 1_000_000 * 0.85 )  - 1; //≈850ns±150ns     0 低电平时间
parameter DELAY_RESET 	= (CLK_FRE / 10 ) - 1; //0.1s 复位时间 ＞50us

parameter RESET 	 		= 0; //状态机声明
parameter DATA_SEND  		= 1;
parameter BIT_SEND_HIGH   	= 2;
parameter BIT_SEND_LOW   	= 3;

reg [ 1:0] state       = 0; // synthesis preserve //主状态机控制
reg [ 8:0] bit_send    = 0; // amount of bit sent // increase it for larger led strips/matrix
reg [ 8:0] data_send   = 0; // amount of data sent // increase it for larger led strips/matrix
reg [31:0] clk_count   = 0; // 延时控制
reg [23:0] WS2812_data = 24'd1; // WS2812的颜色数据

always@(posedge clk)
	case (state)
		RESET:begin
			WS2812 <= 0;

			if (clk_count < DELAY_RESET) 
				clk_count <= clk_count + 1;
			else begin
				clk_count <= 0;
				WS2812_data <= {WS2812_data[22:0],WS2812_data[23]};//颜色移位循环显示
				state <= DATA_SEND;
			end
		end

		DATA_SEND:
			if (data_send == WS2812_NUM && bit_send == WS2812_WIDTH)begin 
				data_send <= 0;
				bit_send  <= 0;
				state <= RESET;
			end 
			else if (bit_send < WS2812_WIDTH) begin
				state    <= BIT_SEND_HIGH;
			end
			else begin// if (bit_send == WS2812_WIDTH)
				data_send <= data_send + 1;
				bit_send  <= 0;
				state    <= BIT_SEND_HIGH;
			end
			
		BIT_SEND_HIGH:begin
			WS2812 <= 1;

			if (WS2812_data[bit_send]) 
				if (clk_count < DELAY_1_HIGH)
					clk_count <= clk_count + 1;
				else begin
					clk_count <= 0;
					state    <= BIT_SEND_LOW;
				end
			else 
				if (clk_count < DELAY_0_HIGH)
					clk_count <= clk_count + 1;
				else begin
					clk_count <= 0;
					state    <= BIT_SEND_LOW;
				end
		end

		BIT_SEND_LOW:begin
			WS2812 <= 0;

			if (WS2812_data[bit_send]) 
				if (clk_count < DELAY_1_LOW) 
					clk_count <= clk_count + 1;
				else begin
					clk_count <= 0;

					bit_send <= bit_send + 1;
					state    <= DATA_SEND;
				end
			else 
				if (clk_count < DELAY_0_LOW) 
					clk_count <= clk_count + 1;
				else begin
					clk_count <= 0;
					
					bit_send <= bit_send + 1;
					state    <= DATA_SEND;
				end
		end
	endcase
endmodule