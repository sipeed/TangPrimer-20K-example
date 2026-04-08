module timing_check#(
    parameter REFCLK_FREQ_MHZ = 50,
    parameter IS_2Pclk_1Pixel = "true"
) (
    input   Refclk,
	input   pxl_clk,
    input   rst_n,
    input   video_de,
    input   video_vsync,

    output  [15:0] H_Active,
    output  Ha_updated,
    output  [15:0] V_Active,
    output  va_updated,
    output  [7:0] fps,
    output  fps_valid
); 

    localparam PPS_DIV_CNT = REFCLK_FREQ_MHZ * 500_000;

    reg pps_1Hz_clk;
    reg [31:0] pps_cnt;
    always@(posedge Refclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            pps_1Hz_clk <= 1'b0;
            pps_cnt <= 32'd0;
        end else begin
            if(pps_cnt == PPS_DIV_CNT - 1)
            begin
                pps_1Hz_clk <= ~pps_1Hz_clk;
                pps_cnt <= 32'd0;
            end else begin
                pps_1Hz_clk <= pps_1Hz_clk;
                pps_cnt <= pps_cnt + 1;
            end
        end
    end 

    reg [15:0] HA_Out;
    reg HA_updated;
    reg [15:0] VA_Out;
    reg VA_updated;
    reg [7:0] fps_out;
    reg fps_updated;
    reg [15:0] HA_CNT;
    reg [15:0] VA_CNT;
    reg [7:0]  fps_CNT;
    reg [3:0]  pps_clk_d;
    reg pixel_clk;
    reg de_d;
    reg vsync_d;
    generate
        always@(posedge pxl_clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                HA_Out <= 0;
                HA_updated <= 0;
                VA_Out <= 0;
                VA_updated <= 0;
                fps_out <= 0;
                fps_updated <= 0;
                HA_CNT <= 0;
                VA_CNT <= 0;
                fps_CNT <= 0;
                pps_clk_d <= 0;
                pixel_clk <= 0;
                de_d <= 0;
                vsync_d <= 0;
            end else begin
                //Sync
                pps_clk_d <= {pps_clk_d[2:0], pps_1Hz_clk};
                de_d <= video_de;
                vsync_d <= video_vsync;

                // Horzental
                if(de_d & ~video_de)    //Negedge of DE, H end
                begin
                    HA_CNT <= 0;
                    HA_Out <= HA_CNT;
                    HA_updated <= 1;
                    pixel_clk <= 0;
                end else if(video_de)
                begin
                    HA_updated <= 0;
                    HA_Out <= HA_Out;
                    if(IS_2Pclk_1Pixel == "true")
                    begin
                        pixel_clk <= ~pixel_clk;
                        if(pixel_clk)
                        begin
                            HA_CNT <= HA_CNT + 1'b1;
                        end else begin
                            HA_CNT <= HA_CNT;
                        end
                    end else begin
                        HA_CNT <= HA_CNT + 1;
                        pixel_clk <= 0;
                    end
                end else begin
                    HA_CNT <= 0;
                    HA_Out <= HA_Out;
                    HA_updated <= 0;
                    pixel_clk <= 0;
                end

                // Vertical
                if(~vsync_d & video_vsync)    //Posedge of vsync
                begin
                    VA_Out <= VA_CNT;
                    VA_updated <= 1;
                    VA_CNT <= 0;
                end else begin
                    VA_Out <= VA_Out;
                    VA_updated <= 0;
                    if(video_de & ~de_d)    //Posedge of DE, H start
                    begin
                        VA_CNT = VA_CNT + 1'b1;
                    end else begin
                        VA_CNT = VA_CNT;
                    end
                end

                // FPS
                if(pps_clk_d[2] & ~pps_clk_d[3])    //Posedge of pps_1Hz_clk
                begin
                    fps_out <= fps_CNT;
                    fps_updated <= 1;
                    fps_CNT <= 0;
                end else begin
                    fps_out <= fps_out;
                    fps_updated <= 0;
                    if(~vsync_d & video_vsync)   //Posedge of VSYNC
                    begin
                        fps_CNT = fps_CNT + 1'b1;
                    end else begin
                        fps_CNT = fps_CNT;
                    end
                end
            end
        end 
    endgenerate

    assign H_Active = HA_Out;
    assign Ha_updated = HA_updated;
    assign V_Active = VA_Out;
    assign va_updated = VA_updated;
    assign fps = fps_out;
    assign fps_valid = fps_updated;

endmodule