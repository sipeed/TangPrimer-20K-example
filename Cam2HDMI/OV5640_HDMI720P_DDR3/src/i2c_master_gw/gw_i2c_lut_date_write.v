module gw_i2c_lut_write #(
    parameter integer LUT_AW     = 10,
    parameter integer CLK_FREQ   = 35_000_000,     // Hz
    parameter integer RST_DLY_MS = 2               // ms
)(
    input                     I_CLK,
    input                     I_RESETN,

    input      [15:0]         PRESCALE,     // 预分频输入

    // LUT
    output reg [LUT_AW-1:0]   lut_index,
    input      [31:0]         lut_data,

    // 结果
    output reg                DONE,
    output reg                ERROR,

    // Gowin I2C Master 接口
    output reg                I_TX_EN,
    output reg  [2:0]         I_WADDR,
    output reg  [7:0]         I_WDATA,
    output reg                I_RX_EN,
    output reg  [2:0]         I_RADDR,
    input       [7:0]         O_RDATA,

    inout                     SCL,
    inout                     SDA
);

    // 锁存当前 LUT 项
    reg [7:0]  dev;
    reg [15:0] regaddr;
    reg [7:0]  data;

    // 状态编码（Verilog-2001）
    localparam [5:0]
        S_RESET      = 6'd0,
        S_INIT0      = 6'd1,
        S_INIT1      = 6'd2,
        S_EN         = 6'd3,
        S_FETCH      = 6'd4,
        S_CHECK_END  = 6'd5,
        S_ADDR_TX    = 6'd6,
        S_ADDR_CMD   = 6'd7,
        S_REGH_TX    = 6'd8,
        S_REGH_CMD   = 6'd9,
        S_REGL_TX    = 6'd10,
        S_REGL_CMD   = 6'd11,
        S_DATA_TX    = 6'd12,
        S_DATA_CMD   = 6'd13,
        S_WAIT_REQ   = 6'd14,
        S_WAIT_DATA  = 6'd15,
        S_WAIT_EVAL  = 6'd16,
        S_DELAY      = 6'd17,
        S_NEXT       = 6'd18,
        S_ERR        = 6'd19,
        S_DONE_ST    = 6'd20; // 避免与端口 DONE 易混

    reg [5:0] state, next_state;
    reg [3:0] stage, next_stage;
    reg [31:0] delay_cnt, next_delay_cnt;

    // next 寄存器/输出
    reg [LUT_AW-1:0] next_lut_index;
    reg next_DONE, next_ERROR;

    reg next_I_TX_EN;
    reg [2:0] next_I_WADDR;
    reg [7:0] next_I_WDATA;
    reg next_I_RX_EN;
    reg [2:0] next_I_RADDR;

    reg [7:0]  next_dev;
    reg [15:0] next_regaddr;
    reg [7:0]  next_data;

    //======================================================
    // 组合：默认保持 + 状态转移
    //======================================================
    always @(*) begin
        // 默认保持
        next_state     = state;
        next_stage     = stage;
        next_delay_cnt = delay_cnt;

        next_lut_index = lut_index;
        next_DONE      = DONE;
        next_ERROR     = ERROR;

        next_I_TX_EN   = 1'b0;
        next_I_RX_EN   = 1'b0;
        next_I_WADDR   = I_WADDR;
        next_I_WDATA   = I_WDATA;
        next_I_RADDR   = I_RADDR;

        next_dev       = dev;
        next_regaddr   = regaddr;
        next_data      = data;

        case (state)
            // 初始化：写分频、使能
            S_RESET: begin
                next_state = S_INIT0;
            end
            S_INIT0: begin
                next_I_WADDR = 3'h0; next_I_WDATA = PRESCALE[7:0];  next_I_TX_EN = 1'b1;
                next_state   = S_INIT1;
            end
            S_INIT1: begin
                next_I_WADDR = 3'h1; next_I_WDATA = PRESCALE[15:8]; next_I_TX_EN = 1'b1;
                next_state   = S_EN;
            end
            S_EN: begin
                next_I_WADDR = 3'h2; next_I_WDATA = 8'h80;          next_I_TX_EN = 1'b1;
                next_state   = S_FETCH;
            end

            // 抓取 LUT
            S_FETCH: begin
                next_dev     = lut_data[31:24];
                next_regaddr = lut_data[23:8];
                next_data    = lut_data[7:0];
                next_state   = S_CHECK_END;
            end

            // 结束哨兵：FF/FFFF
            S_CHECK_END: begin
                next_stage = 4'd0;
                if (lut_data[31:24]==8'hFF && lut_data[23:8]==16'hFFFF)
                    next_state = S_DONE_ST;
                else
                    next_state = S_ADDR_TX;
            end

            // 设备地址 + START
            S_ADDR_TX: begin
                next_I_WADDR = 3'h3; next_I_WDATA = dev; next_I_TX_EN = 1'b1;
                next_state   = S_ADDR_CMD;
            end
            S_ADDR_CMD: begin
                next_I_WADDR = 3'h4; next_I_WDATA = 8'h90; next_I_TX_EN = 1'b1; // STA|WR
                next_stage   = 4'd0;
                next_state   = S_WAIT_REQ;
            end

            // reg 高
            S_REGH_TX: begin
                next_I_WADDR = 3'h3; next_I_WDATA = regaddr[15:8]; next_I_TX_EN = 1'b1;
                next_state   = S_REGH_CMD;
            end
            S_REGH_CMD: begin
                next_I_WADDR = 3'h4; next_I_WDATA = 8'h10; next_I_TX_EN = 1'b1; // WR
                next_stage   = 4'd1;
                next_state   = S_WAIT_REQ;
            end

            // reg 低
            S_REGL_TX: begin
                next_I_WADDR = 3'h3; next_I_WDATA = regaddr[7:0]; next_I_TX_EN = 1'b1;
                next_state   = S_REGL_CMD;
            end
            S_REGL_CMD: begin
                next_I_WADDR = 3'h4; next_I_WDATA = 8'h10; next_I_TX_EN = 1'b1; // WR
                next_stage   = 4'd2;
                next_state   = S_WAIT_REQ;
            end

            // 数据 + STOP
            S_DATA_TX: begin
                next_I_WADDR = 3'h3; next_I_WDATA = data; next_I_TX_EN = 1'b1;
                next_state   = S_DATA_CMD;
            end
            S_DATA_CMD: begin
                next_I_WADDR = 3'h4; next_I_WDATA = 8'h50; next_I_TX_EN = 1'b1; // WR|STO
                next_stage   = 4'd3;
                next_state   = S_WAIT_REQ;
            end

            // 轮询 TIP：加入一拍延时读取
            S_WAIT_REQ: begin
                next_I_RADDR = 3'h4; next_I_RX_EN = 1'b1;
                next_state   = S_WAIT_DATA;
            end
            S_WAIT_DATA: begin
                next_state = S_WAIT_EVAL; // 等一拍
            end
            S_WAIT_EVAL: begin
                if (O_RDATA[1]) begin
                    next_state = S_WAIT_REQ; // TIP=1 继续等
                end else if (O_RDATA[7]) begin
                    next_ERROR = 1'b1;       // RX_ACK=1 → NACK
                    next_state = S_ERR;
                end else begin
                    case (stage)
                        0: next_state = S_REGH_TX;
                        1: next_state = S_REGL_TX;
                        2: next_state = S_DATA_TX;
                        3: begin
                               if (regaddr==16'h3008 && data==8'h82) begin
                                   next_delay_cnt = (CLK_FREQ/1000) * RST_DLY_MS;
                                   next_state     = S_DELAY;
                               end else begin
                                   next_state     = S_NEXT;
                               end
                           end
                        default: begin end // 保持 next_state
                    endcase
                end
            end

            // 延时 2ms
            S_DELAY: begin
                if (delay_cnt != 0)
                    next_delay_cnt = delay_cnt - 1'b1;
                if (delay_cnt == 0)
                    next_state = S_NEXT;
            end

            // 下一条
            S_NEXT: begin
                next_lut_index = lut_index + 1'b1;
                next_state     = S_FETCH;
            end

            S_ERR: begin
                next_state = S_DONE_ST;
            end

            S_DONE_ST: begin
                next_DONE  = 1'b1;
                next_state = S_DONE_ST; // 停留
            end

            default: begin
                next_state = S_RESET;
            end
        endcase
    end

    //======================================================
    // 时序：寄存器更新
    //======================================================
    always @(posedge I_CLK or negedge I_RESETN) begin
        if (!I_RESETN) begin
            state      <= S_RESET;
            stage      <= 4'd0;
            delay_cnt  <= 32'd0;

            lut_index  <= {LUT_AW{1'b0}};
            DONE       <= 1'b0;
            ERROR      <= 1'b0;

            I_TX_EN    <= 1'b0;
            I_RX_EN    <= 1'b0;
            I_WADDR    <= 3'd0;
            I_WDATA    <= 8'd0;
            I_RADDR    <= 3'd0;

            dev        <= 8'd0;
            regaddr    <= 16'd0;
            data       <= 8'd0;
        end else begin
            state      <= next_state;
            stage      <= next_stage;
            delay_cnt  <= next_delay_cnt;

            lut_index  <= next_lut_index;
            DONE       <= next_DONE;
            ERROR      <= next_ERROR;

            I_TX_EN    <= next_I_TX_EN;
            I_RX_EN    <= next_I_RX_EN;
            I_WADDR    <= next_I_WADDR;
            I_WDATA    <= next_I_WDATA;
            I_RADDR    <= next_I_RADDR;

            dev        <= next_dev;
            regaddr    <= next_regaddr;
            data       <= next_data;
        end
    end

endmodule