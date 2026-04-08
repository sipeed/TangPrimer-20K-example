
module cmos_reset_gen #(
	parameter integer	USE_DSP_CNT = 1,
	parameter integer	CNT_WIDTH   = 22
)(
	input				clk,
	input				rst_n,
	output	reg			cmos_resetn,
	output	reg			cmos_start_config
);

	reg  [CNT_WIDTH-1:0] cnt = {CNT_WIDTH{1'b0}};
	reg  reached_resetn      = 1'b0;
	reg  reached_startcfg    = 1'b0;
//	reg  cmos_resetn         = 1'b0;
//	reg  cmos_start_config   = 1'b0;

	generate 
	if(USE_DSP_CNT == 1) begin
        wire [47:0] dsp_cnt_out;
		reg ce_dsp = 1'b1;
		MULTALU27X18 #(
		    .AREG_CLK       ("BYPASS"),
		    .BREG_CLK       ("BYPASS"),
		    .DREG_CLK       ("BYPASS"),
		    .C_IREG_CLK     ("CLK0"),
		    .C_IREG_CE      ("CE0"),
		    .C_IREG_RESET   ("RESET0"),
		    .C_PREG_CLK     ("CLK0"),
		    .C_PREG_CE      ("CE0"),
		    .C_PREG_RESET   ("RESET0"),
		    .DYN_C_SEL      ("FALSE"),
		    .C_SEL          ("1'b1"),
		    .DYN_ACC_SEL    ("FALSE"),
		    .ACC_SEL        ("1'b1"),       
		    .FB_PREG_EN     ("TRUE"), 
		    .OREG_CLK       ("CLK0"),
		    .OREG_CE        ("CE0"),
		    .OREG_RESET     ("RESET0"),
		    .PRE_LOAD       (48'h0),
		    .MULT_RESET_MODE("SYNC")
		) dsp_cnt_cmos_rst (
		    .CLK    ({1'b0, clk}),
		    .CE     ({1'b0, ce_dsp}),      
		    .RESET  ({1'b0, ~rst_n}),      
			.A      (48'd0), .B(18'd0), .D(26'd0),
		    .C      (48'd1),              
			.CSEL	(1'b1 ),				
			.PSEL   (1'b0), .PADDSUB(1'b0),
			.ASEL   (1'b0),
			.ADDSUB ({2{1'b0}}),
			.CASISEL(1'b0), 
		    .CASI   (),
		    .CASO   (),
		    .DOUT   (dsp_cnt_out)
		);
		//assign cmos_resetn       = (dsp_cnt_out >= RESET_THD);
		//assign cmos_start_config = (dsp_cnt_out >= STARTCFG_THD);
		//wire reach_target = (dsp_cnt_out == TARGET_EXT);
		reg reach_target = 1'b0;
		always @(posedge clk) begin
		    cnt <= dsp_cnt_out[{CNT_WIDTH-1}:0];
		end
		always @(posedge clk) begin
		    reach_target <= cnt[21];
		end
		
		always @(posedge clk or negedge rst_n) begin
		    if (!rst_n) begin
		        ce_dsp <= 1'b1;
		    end
		    else begin
		        ce_dsp <= reach_target;
		    end
		end
		
		//wire reach_target_w = ~reach_target & 1 /* synthesis syn_keep = value */;
		//assign ce_dsp = reach_target_w   /* synthesis syn_keep = value */; 

		//assign ce_dsp = reach_target;
	end

	else if (USE_DSP_CNT == 2) begin
		always@(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
			    cnt <= {CNT_WIDTH{1'b0}};
			end 
			else begin
			    if(cnt == 22'd2_100_000) begin
			        cnt <= cnt;
			    end 
				else if(cnt == 22'd100_000) begin
			        cnt <= cnt + 1;
			    end 
				else begin
			        cnt <= cnt + 1;
			    end

			end
		end
	end
	
	else begin
		localparam [CNT_WIDTH-1:0] RESET_THD    = 22'd70_000;    //2ms in 35MHz
		localparam [CNT_WIDTH-1:0] STARTCFG_THD = 22'd2_100_000; //60ms in 35MHz

		always @(posedge clk or negedge rst_n) begin
		    if (!rst_n) begin
		        cnt <= {CNT_WIDTH{1'b0}};
		    end
		    else if (cnt <= STARTCFG_THD) begin
		        cnt <= cnt + 1'b1;
		    end
		    else begin
		        cnt <= cnt;
		    end
		end
	end
	endgenerate

	always @(posedge clk) begin
    	cmos_start_config  <= cnt[21];
    	//reached_resetn     <= cnt[16];
    	cmos_resetn        <= (cmos_resetn) ? 1'b1 : cnt[16];  
	end
	
	/*
	always @(posedge clk) begin
	    reached_startcfg  <= cnt[21];
	    reached_resetn    <= cnt[16];         
	end
	wire reached_resetn_d   = reached_resetn;
	wire reached_startcfg_d = reached_startcfg;
	
	//reg     reached_resetn_d    = 1'b0;
	//reg     reached_startcfg_d  = 1'b0;
	//always @(posedge clk) begin
	//    reached_resetn_d   <= reached_resetn;
	//    reached_startcfg_d <= reached_startcfg;
	//end
	
	always @(posedge clk) begin
	    cmos_resetn       <= reached_resetn_d;
	    cmos_start_config <= reached_startcfg_d;
	end
	
	//wire trig_xxx = (cnt == STARTCFG_THD-1);
	*/

endmodule       
              