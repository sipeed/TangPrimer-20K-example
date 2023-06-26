`include "rmii.svh"

module top(
    input clk,
    input rst,

    rmii netrmii,
    output phyrst,

    output[5:0] led
);

logic[5:0] rled;
logic[23:0] ckdiv;
assign led = rled;

always_ff@(posedge clk or negedge rst)begin
    if(rst == 1'b0)begin
        rled <= 5'b00001;
        ckdiv <= 24'd0;
    end else begin
        ckdiv <= ckdiv + 24'd1;
        if(ckdiv == 24'd0)
            rled <= {rled[4:0],rled[5]};
    end
end

logic clk1m;
logic clk6m;
PLL_6M PLL6m(
    .clkout(clk6m),
    .clkoutd(clk1m),
    .clkin(clk)
);

logic clk50m;
logic ready;

logic rx_head_av;
logic[31:0] rx_head;
logic rx_data_av;
logic[7:0] rx_data;
logic rx_head_rdy;

logic [31:0] tx_ip;
logic [15:0] tx_dst_port;
logic tx_req;
logic [7:0] tx_data;
logic tx_data_av;
logic tx_req_rdy;
logic tx_data_rdy;

udp #(
    .ip_adr({8'd192,8'd168,8'd15,8'd14}),
    .mac_adr({8'h06,8'h00,8'hAA,8'hBB,8'h0C,8'hDD}),

    .arp_refresh_interval(50000000*15), // 15 seconds    
    .arp_max_life_time(50000000*30) // 30 seconds
)udp_inst(
    .clk1m(clk1m),
    .rst(rst),

    .clk50m(clk50m),
    .ready(ready),

    .netrmii(netrmii),

    .phyrst(phyrst),

    .rx_head_rdy_i(rx_head_rdy),
    .rx_head_av_o(rx_head_av),
    .rx_head_o(rx_head),
    .rx_data_rdy_i(1'b1),
    .rx_data_av_o(rx_data_av),
    .rx_data_o(rx_data),

    .tx_ip_i(tx_ip),
    .tx_src_port_i(16'd11451),
    .tx_dst_port_i(tx_dst_port),
    .tx_req_i(tx_req),
    .tx_data_i(tx_data),
    .tx_data_av_i(tx_data_av),
    .tx_req_rdy_o(tx_req_rdy),
    .tx_data_rdy_o(tx_data_rdy)
);

always_comb begin
    tx_data <= rx_data;
    tx_data_av <= rx_data_av;
end

byte tx_state;

//4 packs of rx head each frame
//0: src_ip
//1: dst_ip
//2: src_port+dst_port
//3: idf+udp_len


always_ff@(posedge clk50m or negedge ready)begin
    if(ready == 0)begin
        tx_state <= 0;
        rx_head_rdy <= 1'b0;
    end else begin
        tx_req <= 1'b0;
        rx_head_rdy <= 1'b0;

        case(tx_state)
            0:begin
                if(rx_head_av)begin
                    tx_state <= 1;
                    rx_head_rdy <= 1'b1;
                end
            end
            1:begin // send the data back to where it came from
                rx_head_rdy <= 1'b1;
                tx_ip <= rx_head;
                tx_state <= 2;
            end
            2:begin
                rx_head_rdy <= 1'b1;
                tx_state <= 3;
            end
            3:begin // send the data to the port it came from + 1
                rx_head_rdy <= 1'b1;
                tx_dst_port <= rx_head[31:16] + 16'd1;
                tx_state <= 4;
            end
            4:begin
                tx_state <= 5;
            end
            5:begin // wait until data is all received and req is ready
                if(tx_req_rdy && rx_data_av == 1'b0)begin
                    tx_req <= 1'b1;
                    tx_state <= 0;
                end                
            end
        endcase
    end
end




endmodule

