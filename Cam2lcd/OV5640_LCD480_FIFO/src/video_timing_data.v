module video_timing_data
#(
	parameter DATA_WIDTH = 16                       // Video data one clock data width
)
(
	input                       video_clk,          // Video pixel clock
	input                       rst,

	input [15:0] 			    fifo_data_in,
	input	 			    	fifo_data_in_en,
	input	 			    	fifo_data_in_clk,
	input	 			    	fifo_data_vs,

	output reg                   hs,                 // horizontal synchronization
	output reg                   vs,                 // vertical synchronization
	output reg                   de,                 // video valid
	output[DATA_WIDTH - 1:0]    vout_data           // video data
);
wire                   video_hs;
wire                   video_vs;
wire                   video_de;


//Frame reset at beginning, avoid error accumulation.
reg vs_in_r;
wire vs_posedge;
assign vs_posedge = !vs_in_r & fifo_data_vs;

always@(posedge video_clk) vs_in_r <= fifo_data_vs;

reg 	video_rst = 0;
video_fifo	video_fifo_m0 (
	.Reset 		(fifo_data_vs 		),

	.Data 		(fifo_data_in 		),
	.WrClk 		(fifo_data_in_clk 	),
	.WrEn 		(fifo_data_in_en 	),

	.RdClk 		(video_clk  		),
	.RdEn 		(video_de 			),
	.Q 			(vout_data  		)
	);

reg [1:0]video_state = 0;
reg [19:0] clk_delay = 0;
always@(posedge video_clk)
	case(video_state)
		2'd0:begin
			video_rst <= 0;
			if(vs_posedge)begin video_state <= video_state + 1; clk_delay <= 0; end
		end

		2'd1:begin
			if (clk_delay == 20'd0) begin // 
				clk_delay <= 0;
				video_state <= video_state + 1;
			end
			else clk_delay <= clk_delay + 1;
		end
		
		2'd2:begin
			video_rst <= 1;
			video_state <= 0;
		end
	endcase

always@(posedge video_clk)begin
	hs <= video_hs;
	vs <= video_vs;
	de <= video_de;
end

color_bar color_bar_m0(
	.clk(video_clk),
	.rst(video_rst 	),
	
	.hs(video_hs),
	.vs(video_vs),
	.de(video_de)
);
endmodule 