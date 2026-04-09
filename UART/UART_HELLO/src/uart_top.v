module uart_top #(
    parameter integer SEND_DELAY = 1,        // Second
    parameter integer FIFO_DEPTH = 64,       // Bit
    parameter integer CLK_FRE    = 27,       // Megahertz
    parameter integer BAUD_RATE  = 115200    // Baud
)(
    input                        clk,
    input                        rst_n,
    input                        uart_rx,
    output                       uart_tx
);

    // -----------------------------
    // 1-second tick (CLK_FRE is MHz)
    // -----------------------------
    localparam integer ONE_SEC_CNT    = CLK_FRE * 1000_000;  // e.g. 27_000_000 MHz

    reg [31:0] sec_cnt;
    reg        str_active;
    reg [7:0]  str_idx;

    // -----------------------------
    // tx_data_send interval (PERIOD is second)
    // -----------------------------
    localparam integer TX_SEND_PERIOD = ONE_SEC_CNT * SEND_DELAY;  

    // -----------------------------
    // String bytes: "\r\n你好  GOWIN\r\n" in UTF-8
    // CRLF: 0D 0A
    // 你: E4 BD A0
    // 好: E5 A5 BD
    // ' ': 20
    // GOWIN: 47 4F 57 49 4E
    // CRLF: 0D 0A
    // Total: 17 bytes
    // -----------------------------
    localparam integer DATA_NUM = 17;

    wire [DATA_NUM*8-1:0] send_data = {
        8'h0D, 8'h0A,                       // CRLF
        8'hE4, 8'hBD, 8'hA0,                // 你
        8'hE5, 8'hA5, 8'hBD,                // 好
        8'h20, 8'h20,                       // two spaces
        8'h47, 8'h4F, 8'h57, 8'h49, 8'h4E,  // GOWIN
        8'h0D, 8'h0A                        // CRLF
    };

    wire [7:0] str_byte = send_data[(DATA_NUM-1-str_idx)*8 +: 8];

    // -----------------------------
    // UART RX interface
    // -----------------------------
    wire [7:0] rx_data;
    wire       rx_data_valid;
    wire       rx_data_ready;

    // -----------------------------
    // UART TX interface 
    // -----------------------------
    reg  [7:0] tx_data;
    reg        tx_data_valid;
    wire       tx_data_ready;
    wire       tx_busy; 

    // -----------------------------
    // TX FIFO
    // -----------------------------
    wire [7:0] fifo_dout;
    wire       fifo_full;
    wire       fifo_empty;
    wire       fifo_rd_en;
    reg        fifo_wr_en;
    reg  [7:0] fifo_din;

    assign rx_data_ready = ~fifo_full;

    // -----------------------------
    // (A) Write-side arbitration into TX FIFO:
    //     NOTICE: priority: RX echo > periodic string
    // -----------------------------
    wire req_rx  = rx_data_valid && rx_data_ready;   
    wire req_str = str_active && ~fifo_full && ~req_rx; 

    always @(*) begin
        fifo_wr_en = 1'b0;
        fifo_din   = 8'h00;

        if (req_rx) begin
            fifo_wr_en = 1'b1;
            fifo_din   = rx_data;
        end else if (req_str) begin
            fifo_wr_en = 1'b1;
            fifo_din   = str_byte;
        end
    end

    // -----------------------------
    // (B) Periodic string loader (pushes bytes into FIFO)
    //     NOTICE: tx_send_data interval from string "TX_SEND_PERIOD"
    // -----------------------------

    wire tx_send_ready = fifo_empty && tx_data_ready && !tx_busy && !tx_data_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_cnt    <= 32'd0;
            str_active <= 1'b0;
            str_idx    <= 8'd0;
        end else begin
        if (!str_active) begin
            if (tx_send_ready) begin
                if (sec_cnt >= TX_SEND_PERIOD-1) begin
                    sec_cnt    <= 32'd0;
                    str_active <= 1'b1;
                    str_idx    <= 8'd0;
                end else begin
                    sec_cnt <= sec_cnt + 32'd1;
                end
            end
        end
            if (req_str) begin
                if (str_idx == DATA_NUM-1) begin
                    str_active <= 1'b0;
                    str_idx    <= 8'd0;
                end else begin
                    str_idx <= str_idx + 8'd1;
                end
            end
        end
    end

    // -----------------------------
    // (C) TX feeder: when uart_tx is ready and FIFO not empty,
    //     present one byte and hold valid until accepted.
    //     NOTICE: pop FIFO ONLY on acceptance rise edge
    // -----------------------------
    wire   deq = tx_data_ready && !tx_data_valid && !fifo_empty;
    assign fifo_rd_en = deq;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx_data       <= 8'd0;
            tx_data_valid <= 1'b0;
        end else begin
            if(tx_data_valid && tx_data_ready)
                tx_data_valid <= 1'b0;
            if(deq) begin
                tx_data       <= fifo_dout; 
                tx_data_valid <= 1'b1;
            end
        end
    end


    sync_fifo #(
        .WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) u_txfifo (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (fifo_wr_en),
        .din   (fifo_din),
        .rd_en (fifo_rd_en),
        .dout  (fifo_dout),
        .full  (fifo_full),
        .empty (fifo_empty)
    );

    uart_rx #(
        .CLK_FRE   (CLK_FRE),
        .BAUD_RATE (BAUD_RATE)
    ) uart_rx_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .rx_data       (rx_data),
        .rx_data_valid (rx_data_valid),
        .rx_data_ready (rx_data_ready),
        .rx_pin        (uart_rx)
    );

    uart_tx #(
        .CLK_FRE   (CLK_FRE),
        .BAUD_RATE (BAUD_RATE)
    ) uart_tx_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_data       (tx_data),
        .tx_data_valid (tx_data_valid),
        .tx_data_ready (tx_data_ready),
        .tx_pin        (uart_tx),
        .tx_busy       (tx_busy)    
    );

endmodule