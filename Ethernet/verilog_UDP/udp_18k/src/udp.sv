//----------------------------------------------------------------------
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------
//----------------------------------------------------------------------
// Author          : LAKKA
// Mail            : Ja_P_S@outlook.com
// File            : udp.sv
//----------------------------------------------------------------------
// Creation Date   : 06.05.2023
//----------------------------------------------------------------------
//

`include "rmii.svh"

module udp
#(
    parameter bit [31:0] ip_adr = 32'd0,
    parameter bit [47:0] mac_adr = 48'd0,
    
    parameter int arp_refresh_interval = 50000000*2,
    parameter int arp_max_life_time = 50000000*10
)(
    input clk1m,
    input rst,

    output logic clk50m,
    output logic ready,

    rmii netrmii,

    output logic phyrst,

    output logic [31:0] rx_head_o,
    output logic rx_head_av_o,
    output logic [7:0] rx_data_o,
    output logic rx_data_av_o,
    input logic rx_head_rdy_i,
    input logic rx_data_rdy_i,

    input logic [31:0] tx_ip_i,
    input logic [15:0] tx_src_port_i,
    input logic [15:0] tx_dst_port_i,
    input logic tx_req_i,
    input logic [7:0] tx_data_i,
    input logic tx_data_av_i,

    output logic tx_req_rdy_o,
    output logic tx_data_rdy_o
);

//logic [31:0] ip_adr = {8'd192,8'd168,8'd15,8'd16};

logic rphyrst;


assign netrmii.mdc = clk1m;
logic phy_rdy;
logic SMI_trg;
logic SMI_ack;
logic SMI_ready;
logic SMI_rw;
logic [4:0] SMI_adr;
logic [15:0] SMI_data;
logic [15:0] SMI_wdata;

byte SMI_status;

assign ready = phy_rdy;


always_ff@(posedge clk1m or negedge rst)begin
    if(rst == 1'b0)begin
        phy_rdy <= 1'b0;
        rphyrst <= 1'b0;
        SMI_trg <= 1'b0;
        SMI_adr <= 5'd1;
        SMI_rw <= 1'b1;
        SMI_status <= 0;
    end else begin
        rphyrst <= 1'b1;
        if(phy_rdy == 1'b0)begin
            SMI_trg <= 1'b1;
            if(SMI_ack && SMI_ready)begin
                case(SMI_status)
                    0:begin
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h7;
                        SMI_rw <= 1'b0;

                        SMI_status <= 1;
                    end
                    1:begin
                        SMI_adr <= 5'd16;
                        SMI_wdata <= 16'hFFE;

                        SMI_status <= 2;
                    end
                    2:begin
                        SMI_rw <= 1'b1;

                        SMI_status <= 3;
                    end
                    3:begin
                        SMI_adr <= 5'd31;
                        SMI_wdata <= 16'h0;
                        SMI_rw <= 1'b0;

                        SMI_status <= 4;
                    end
                    4:begin
                        SMI_adr <= 5'd1;
                        SMI_rw <= 1'b1;

                        SMI_status <= 5;
                    end
                    5:begin
                        if(SMI_data[2])begin
                            phy_rdy <= 1'b1;
                            SMI_trg <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
end

SMI_ct ct(
    .clk(clk1m), .rst(rphyrst), .rw(SMI_rw), .trg(SMI_trg), .ready(SMI_ready), .ack(SMI_ack),
    .phy_adr(5'd1), .reg_adr(SMI_adr),
    .data(SMI_wdata),
    .smi_data(SMI_data),
    .mdio(netrmii.mdio)
);

assign phyrst = rphyrst;

assign clk50m = netrmii.clk50m;

//rx fifo
logic arp_rpy_fin;

byte rx_state;

byte cnt;
logic[7:0] rx_data_s;


logic crs;
assign crs = netrmii.rx_crs;
logic[1:0] rxd;
assign rxd = netrmii.rxd;

byte rx_cnt;
byte tick;

logic fifo_in;
logic[7:0] fifo_d;
always_comb begin
    fifo_in <= tick == 0 && rx_state == 3;
    fifo_d <= rx_data_s;
end
logic fifo_drop;

always @(posedge clk50m or negedge phy_rdy) begin
    if(phy_rdy==1'b0)begin
        cnt <=0;
    end else begin
        if(crs)begin
            tick <= tick + 8'd1;
            if(tick == 3)tick <= 0;
        end
        rx_cnt <= 0;
        fifo_drop <= 1'b0;

        case(rx_state)
            0:begin
                rx_state <= 1;
            end
            1:begin //检测前导码和相位
                if(rx_data_s[7:0] == 8'h55)begin
                    rx_state <= 2;
                end
            end
            2:begin
                tick <= 1;
                if(rx_data_s == 8'h55)begin
                    rx_cnt <= rx_cnt + 8'd1;
                end else begin
                    if(rx_data_s == 8'hD5 && rx_cnt > 26)begin
                        rx_state <= 3;
                        tick <= 1;
                    end else begin
                        rx_state <= 0;
                    end
                end
            end
            3:begin
                if(crs == 1'b0)
                    fifo_drop <= 1'b1;
            end
        endcase

        if(crs == 1'b0)begin
            rx_state<=0;
            rx_data_s <= 8'b00XXXXXX;
        end
        if(crs)begin
            rx_data_s <= {rxd,rx_data_s[7:2]};
        end
    end
end

logic [7:0] rx_data_gd;
logic rx_data_rdy;
logic rx_data_fin;

shortint rx_data_byte_cnt;
byte ethernet_resolve_status;



logic [47:0] rx_info_buf;

logic [47:0] rx_src_mac;
logic [15:0] rx_type;

//0 no request, 1 undef
//checkip: 2 request from slot 0, 3 request from slot 1
//should act: 4 need reply to slot 0, 5 need reply to slot 1
logic [2:0] arp_request;


//0 not ready, 1 ready
logic [1:0] arp_list;



int arp_life_time[1:0];

logic [47:0] arp_mac_0;
logic [47:0] arp_mac_1;
logic [31:0] arp_ip_0;
logic [31:0] arp_ip_1;

logic [1:0] arp_clean;

shortint head_len;

logic [17:0] checksum;

logic [31:0] src_ip;
logic [31:0] dst_ip;
logic [15:0] src_port;
logic [15:0] dst_port;

logic [15:0] idf;
logic [15:0] udp_len;

shortint rx_head_fifo_head_int;
shortint rx_head_fifo_head;
shortint rx_head_fifo_tail = 0;
logic [31:0] rx_head_fifo[127:0];

logic [31:0] rx_head_data_i_port;
logic rx_head_data_i_en;
logic [7:0] rx_head_data_i_adr;
//4 packs each frame
//0: src_ip
//1: dst_ip
//2: src_port+dst_port
//3: idf+udp_len

task rx_head_fifo_push(input [31:0] data);
    rx_head_data_i_port <= data;
    rx_head_data_i_en <= 1'b1;
    rx_head_data_i_adr <= rx_head_fifo_head_int[7:0];

    rx_head_fifo_head_int <= rx_head_fifo_head_int + 16'd1;
    if(rx_head_fifo_head_int == 127)
        rx_head_fifo_head_int <= 0;
endtask

shortint rx_data_fifo_head_int;
shortint rx_data_fifo_head;
shortint rx_data_fifo_tail = 0;
logic [7:0] rx_data_fifo[8191:0];

logic [7:0] rx_data_fifo_i_port;
logic rx_data_fifo_i_en;
logic [12:0] rx_data_fifo_i_adr;

task rx_data_fifo_push(input [7:0] data);
    rx_data_fifo_i_port <= data;
    rx_data_fifo_i_en <= 1'b1;
    rx_data_fifo_i_adr <= rx_data_fifo_head_int[12:0];

    rx_data_fifo_head_int <= rx_data_fifo_head_int + 16'd1;
    if(rx_data_fifo_head_int == 8191)
        rx_data_fifo_head_int <= 0;
endtask

logic rx_fin;



always_ff@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy==1'b0)begin
        ethernet_resolve_status <= 0;
        rx_head_fifo_head <= 0;
        rx_head_fifo_head_int <= 0;
        
        rx_data_fifo_head <= 0;
        rx_data_fifo_head_int <= 0;

        arp_list <= 2'b00;
    end else begin
        if(arp_list[0]==1'b1)begin
            if(arp_life_time[0] != 0)
                arp_life_time[0] <= arp_life_time[0] - 1;
            else
                arp_list[0] <= 1'b0;
        end else
            arp_life_time[0] <= arp_max_life_time;
        
        if(arp_list[1]==1'b1)begin
            if(arp_life_time[1] != 0)
                arp_life_time[1] <= arp_life_time[1] - 1;
            else
                arp_list[1] <= 1'b0;
        end else
            arp_life_time[1] <= arp_max_life_time;

        if(arp_clean[1])arp_list[1] <= 1'b0;
        if(arp_clean[0])arp_list[0] <= 1'b0;

        if(rx_head_data_i_en)
            rx_head_fifo[rx_head_data_i_adr] <= rx_head_data_i_port;
        rx_head_data_i_en <= 1'b0;
        if(rx_data_fifo_i_en)
            rx_data_fifo[rx_data_fifo_i_adr] <= rx_data_fifo_i_port;
        rx_data_fifo_i_en <= 1'b0;
        

        rx_fin <= rx_data_fin;

        if(rx_data_byte_cnt[0]==1'b0)begin
            checksum <= {2'b0,checksum[15:0]}+{2'b0,rx_info_buf[15:0]}+{15'd0,checksum[17:16]};
        end
        if(rx_data_byte_cnt==14)
            checksum <= 0;

        if(arp_request > 3 && arp_rpy_fin)
            arp_request <= 0;

        rx_data_byte_cnt <= rx_data_byte_cnt + 8'd1;
        rx_info_buf <= {rx_info_buf[39:0],rx_data_gd};
        case(ethernet_resolve_status)
            0:begin      
                if(rx_data_byte_cnt == 6)begin
                    if((rx_info_buf == mac_adr) || (rx_info_buf == 48'hFFFFFFFFFFFF))
                        ethernet_resolve_status <= 1;
                    else
                        ethernet_resolve_status <= 100;
                end  
            end
            1:begin
                //回复rx_fifo
                rx_head_fifo_head_int <= rx_head_fifo_head;
                rx_data_fifo_head_int <= rx_data_fifo_head;


                if(rx_data_byte_cnt == 12)begin
                    rx_src_mac <= rx_info_buf;
                end
                if(rx_data_byte_cnt == 14)begin
                    ethernet_resolve_status <= 100;
                    if(rx_info_buf[15:0] == 16'h0800)//IP包处理(只收UDP,不处理分片)
                        ethernet_resolve_status <= 20;
                    if(rx_info_buf[15:0] == 16'h0806)//ARP包处理
                        ethernet_resolve_status <= 30;
                end
            end
            20:begin
                //如果fifo满了，就直接拒绝接收
                //head 剩余空间小于4 或者 data 剩余空间小于1600
                if((rx_data_fifo_tail + 127 - rx_data_fifo_head_int) % 128 < 4)
                    ethernet_resolve_status <= 100;
                if((rx_data_fifo_tail + 8191 - rx_data_fifo_head_int) % 8192 < 1600)
                    ethernet_resolve_status <= 100;

                if(rx_data_byte_cnt == 20)begin
                    if(rx_info_buf[47:44]!=4'd4)begin
                        ethernet_resolve_status <= 100;
                    end
                    head_len <= rx_info_buf[43:40]*4;
                    idf <= rx_info_buf[15:0];
                end
                if(rx_data_byte_cnt == 26)begin
                    if(rx_info_buf[23:16] != 8'h11)
                        ethernet_resolve_status <= 100;
                    
                    //checksum <= rx_info_buf[15:0];
                end

                if(rx_data_byte_cnt == 30)begin
                    src_ip <= rx_info_buf[31:0];
                end

                if(rx_data_byte_cnt == head_len + 14)begin
                    ethernet_resolve_status <= 21;

                    if(rx_data_byte_cnt != 34)
                        checksum <= src_ip[15:0]+src_ip[31:16]+dst_ip[15:0]+dst_ip[31:16]+16'h0011;
                    else
                        checksum <= src_ip[15:0]+src_ip[31:16]+rx_info_buf[15:0]+rx_info_buf[31:16]+16'h0011;
                end

                
                if(rx_data_byte_cnt == 34)begin
                    if(rx_info_buf[31:0] != ip_adr && rx_info_buf[31:0] != 32'hFFFFFFFF)
                        ethernet_resolve_status <= 100;
                    
                    dst_ip <= rx_info_buf[31:0];
                    
                    if((checksum[17:0]+{2'd0,rx_info_buf[15:0]} != 18'h0FFFF) && (checksum[17:0]+{2'd0,rx_info_buf[15:0]} != 18'h1FFFE) && (checksum[17:0]+{2'd0,rx_info_buf[15:0]} != 18'h2FFFD))
                    //if((checksum[16:0]+{1'b0,rx_info_buf[15:0]} != 17'h00000) && (checksum[16:0]+{1'b0,rx_info_buf[15:0]} != 17'h1FFFF))
                        ethernet_resolve_status <= 100;
                end
            end
            21:begin
                if(rx_data_byte_cnt == head_len + 18)begin
                    rx_head_fifo_push(src_ip);
                end
                if(rx_data_byte_cnt == head_len + 19)begin
                    rx_head_fifo_push(dst_ip);
                end
                if(rx_data_byte_cnt == head_len + 21)begin
                    rx_head_fifo_push({src_port,dst_port});
                end
                if(rx_data_byte_cnt == head_len + 22)begin
                    rx_head_fifo_push({idf,udp_len - 8});
                end

                if(rx_data_byte_cnt == head_len + 20)begin
                    src_port <= rx_info_buf[47:32];
                    dst_port <= rx_info_buf[31:16];
                    udp_len <= rx_info_buf[15:0];
                end

                if(rx_data_byte_cnt > head_len + 22 && udp_len != 8)begin
                    rx_data_fifo_push(rx_info_buf[7:0]);
                end

                if(rx_data_byte_cnt == head_len + 14 + udp_len)begin
                    if(rx_data_byte_cnt[0]==1'b1)begin
                        if((checksum[17:0]+{2'd0,rx_info_buf[7:0],8'd0}+udp_len != 18'h0FFFF)&&(checksum[17:0]+{2'd0,rx_info_buf[7:0],8'd0}+udp_len != 18'h1FFFE)&&(checksum[17:0]+{2'd0,rx_info_buf[7:0],8'd0}+udp_len != 18'h2FFFD))
                            ethernet_resolve_status <= 100;
                        else begin
                            ethernet_resolve_status <= 29;
                            //移动头部指针
                            rx_head_fifo_head <= rx_head_fifo_head_int;
                            if(udp_len != 8)
                                rx_data_fifo_head <= rx_data_fifo_head_int == 8191?16'd0:rx_data_fifo_head_int+16'd1;
                        end
                    end else begin
                        if((checksum[17:0]+{2'd0,rx_info_buf[15:0]}+udp_len != 18'h0FFFF)&&(checksum[17:0]+{2'd0,rx_info_buf[15:0]}+udp_len != 18'h1FFFE)&&(checksum[17:0]+{2'd0,rx_info_buf[15:0]}+udp_len != 18'h2FFFD))
                            ethernet_resolve_status <= 100;
                        else begin
                            ethernet_resolve_status <= 29;
                            //移动头部指针
                            rx_head_fifo_head <= rx_head_fifo_head_int;
                            if(udp_len != 8)
                                rx_data_fifo_head <= rx_data_fifo_head_int == 8191?16'd0:rx_data_fifo_head_int+16'd1;
                        end
                    end
                end

            end
            29:begin

            end
            30:begin
                //只回复000108000604类型的ARP包
                if(rx_data_byte_cnt == 20)begin
                    if(rx_info_buf == 48'h000108000604)
                        ethernet_resolve_status <= 31;
                    else
                        ethernet_resolve_status <= 100;
                end
            end
            31:begin
                //将MAC和IP地址写入ARP表,源MAC直接用链路层MAC
                //如果是request包，检测是否是自己的IP地址，如果是，回复reply包
                //ARP表深度为2，FIFO
                if(rx_data_byte_cnt == 22)begin
                    //如果是request包
                    if(rx_info_buf[15:0] == 16'h0001 && arp_request == 0)begin
                        arp_request <= 2; 
                        if(arp_list[1] && arp_mac_1 == rx_src_mac)
                            arp_request <= 3;
                    end
                end
                if(rx_data_byte_cnt == 32)begin
                    if(rx_src_mac != arp_mac_0 && rx_src_mac != arp_mac_1)begin
                        arp_mac_1 <= arp_mac_0;
                        arp_ip_1 <= arp_ip_0;
                        arp_list[1] <= arp_list[0];
                        arp_life_time[1] <= arp_life_time[0];

                        arp_mac_0 <= rx_src_mac;
                        arp_ip_0 <= rx_info_buf[31:0];
                        arp_list[0] <= 1'b1;
                        arp_life_time[0] <= arp_max_life_time;
                    end

                    if(rx_src_mac == arp_mac_0)begin
                        arp_ip_0 <= rx_info_buf[31:0];
                        arp_list[0] <= 1'b1;
                        arp_life_time[0] <= arp_max_life_time;
                    end

                    if(rx_src_mac == arp_mac_1)begin
                        arp_ip_1 <= rx_info_buf[31:0];
                        arp_list[1] <= 1'b1;
                        arp_life_time[1] <= arp_max_life_time;
                    end
                end
                if(rx_data_byte_cnt == 42)begin
                    if(rx_info_buf[31:0] == ip_adr && arp_request >= 2)begin
                        arp_request <= arp_request + 3'd2;
                    end else begin
                        arp_request <= 0;
                    end
                end
            end
        endcase

        if(rx_data_rdy == 1'b0)
            rx_data_byte_cnt <= 0;

        if(rx_fin)
            ethernet_resolve_status <= 0;
    end
end


logic read_head;
logic read_data;

always_comb begin
    read_head <= rx_head_rdy_i && rx_head_av_o;
    read_data <= rx_data_rdy_i && rx_data_av_o;
end

always_ff@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy==1'b0)begin
        rx_head_fifo_tail <= 0;
        rx_data_fifo_tail <= 0;

        rx_head_av_o<=1'b0;
        rx_data_av_o<=1'b0;
    end else begin
        rx_head_av_o <= rx_head_fifo_head != rx_head_fifo_tail;
        if(read_head)rx_head_av_o <= rx_head_fifo_head != (rx_head_fifo_tail+1)%128;

        if(read_head)rx_head_fifo_tail <= (rx_head_fifo_tail+1)%16'd128;

        rx_head_o <= rx_head_fifo[rx_head_fifo_tail];
        if(read_head) rx_head_o <= rx_head_fifo[(rx_head_fifo_tail+1)%128];

        rx_data_av_o <= rx_data_fifo_head != rx_data_fifo_tail;
        if(read_data)rx_data_av_o <= rx_data_fifo_head != (rx_data_fifo_tail+1)%8192;

        if(read_data)rx_data_fifo_tail <= (rx_data_fifo_tail+1)%16'd8192;

        rx_data_o <= rx_data_fifo[rx_data_fifo_tail];
        if(read_data) rx_data_o <= rx_data_fifo[(rx_data_fifo_tail+1)%8192];
    end
end

CRC_check crc(
    .clk(clk50m),
    .rst(phy_rdy),
    .data(fifo_d),
    .av(fifo_in),
    .stp(fifo_drop),

    .data_gd(rx_data_gd),
    .rdy(rx_data_rdy),
    .fin(rx_data_fin)
);




//如果收到一个arp request包，需要回复一个arp reply包
logic test_tx_en;
logic [7:0] test_data;

byte arp_rpy_stauts;
shortint arp_rpy_cnt;

logic [7:0] arp_head [8:0] = {8'h08,8'h06,8'h00,8'h01,8'h08,8'h00,8'h06,8'h04,8'h00};


logic tx_bz;
logic tx_av;

tx_ct ctct(
    .clk(clk50m), .rst(phy_rdy),
    .data(test_data),
    .tx_en(test_tx_en),
    .tx_bz(tx_bz),
    .tx_av(tx_av),
    .p_txd(netrmii.txd),
    .p_txen(netrmii.txen)
);

logic [15:0] sendport = 16'h1234;

logic [47:0] tar_mac_buf;
logic [31:0] tar_ip_buf;
logic [15:0] len_buf;

//发送数据格式,目标地址32B,16Bx,16B len
//len是包的总长度，包含mac地址

logic [31:0] tx_head_fifo[63:0];
shortint tx_head_fifo_head=0;
shortint tx_head_fifo_tail=0;
logic [31:0] tx_head_data_i_port;
logic [31:0] tx_head_data_o_port;
logic tx_head_data_i_en;
logic [6:0] tx_head_data_i_adr;



logic [7:0] tx_data_fifo[8191:0];
shortint tx_data_fifo_head=0;
shortint tx_data_fifo_tail=0;
logic [7:0] tx_data_data_i_port;
logic [7:0] tx_data_data_o_port;
logic tx_data_data_i_en;
logic [12:0] tx_data_data_i_adr;

always_ff@(posedge clk50m) begin
    //tx_head_data_o_port <= {8'd192,8'd168,8'd15,8'd15};
    tx_head_data_o_port <= tx_head_fifo[tx_head_fifo_tail];
    tx_data_data_o_port <= tx_data_fifo[tx_data_fifo_tail];
end

int tick_wt_cnt;

int base_tick = 250000000;

//data to write: 08004500002937f3400040116361c0a80f0fc0a80f10a3943039001524e054446762653436623433793563
/* it's wrong , order should be reversed.
logic [7:0] data_rom [42:0] = {8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h29, 8'h37, 8'hf3, 8'h40, 8'h00, 8'h40, 8'h11, 8'h63, 8'h61, 8'hc0, 8'ha8, 8'h0f, 8'h0f, 8'hc0, 8'ha8, 8'h0f, 8'h10, 8'ha3, 8'h94, 8'h30, 8'h39, 8'h00, 8'h15, 8'h24, 8'h65, 8'h05, 8'h44, 8'h46, 8'h76, 8'h65, 8'h34, 8'h36, 8'h62, 8'h34, 8'h33, 8'h79, 8'h35, 8'h63};
*/
logic [7:0] data_rom [42:0] = {8'h63, 8'h35, 8'h79, 8'h33, 8'h34, 8'h62, 8'h36, 8'h34, 8'h65, 8'h76, 8'h46, 8'h44, 8'h05, 8'hcc, 8'h94, 8'h15, 8'h00, 8'h39, 8'h30, 8'h94, 8'ha3, 8'h0f, 8'h0f, 8'ha8, 8'hc0, 8'h10, 8'h0f, 8'ha8, 8'hc0, 8'h61, 8'h63, 8'h11, 8'h40, 8'h00, 8'h40, 8'hf3, 8'h37, 8'h29, 8'h00, 8'h00, 8'h45, 8'h00, 8'h08};
/*
always_ff@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy==1'b0)begin
        tx_head_fifo_head <= 0;
        tx_data_fifo_head <= 0;
        tick_wt_cnt <= 0;

    end else begin
        if(tx_head_data_i_en)
            tx_head_fifo[tx_head_data_i_adr] <= tx_head_data_i_port;
        tx_head_data_i_en <= 1'b0;
        if(tx_data_data_i_en)
            tx_data_fifo[tx_data_data_i_adr] <= tx_data_data_i_port;
        tx_data_data_i_en <= 1'b0;

        tick_wt_cnt <= tick_wt_cnt + 1;
        if(tick_wt_cnt == base_tick*2)begin
            tick_wt_cnt <= 0;
        end

        

        if(tick_wt_cnt == base_tick)begin
            tx_head_data_i_adr <= tx_head_fifo_head;
            tx_head_data_i_en <= 1'b1;
            tx_head_data_i_port <= {8'd192,8'd168,8'd15,8'd15};
        end

        if(tick_wt_cnt == base_tick+1)begin
            tx_head_data_i_adr <= (tx_head_fifo_head+1)%64;
            tx_head_data_i_en <= 1'b1;
            tx_head_data_i_port <= {16'h0000,16'd55};
        end

        if(tick_wt_cnt >= base_tick && tick_wt_cnt < base_tick+43)begin
            tx_data_data_i_adr <= (tx_data_fifo_head+tick_wt_cnt-base_tick)%8192;
            tx_data_data_i_en <= 1'b1;
            tx_data_data_i_port <= data_rom[tick_wt_cnt-base_tick];
        end

        if(tick_wt_cnt == base_tick+44)begin
            tx_head_fifo_head <= (tx_head_fifo_head+2)%64;
            tx_data_fifo_head <= (tx_data_fifo_head+43)%8192;
        end
    end
end

*/

logic arp_lst_refresh;
int arp_refresh_cnt;
logic [31:0] arp_target_ip;
logic [47:0] arp_target_mac;

int longdelay;

always_ff@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy==1'b0)begin
        arp_refresh_cnt <= 0;
        arp_rpy_stauts <=0;
        arp_clean <= 2'b00;

        tx_head_fifo_tail <= 0;
        tx_data_fifo_tail <= 0;
    end else begin
        arp_rpy_fin <= 1'b0;
        test_tx_en <= 1'b0;
        arp_rpy_cnt <= arp_rpy_cnt + 16'd1;

        arp_clean <= 2'b00;


        case(arp_rpy_stauts)
            0:begin
                if(arp_request > 3)begin
                    arp_rpy_stauts <= 1;
                    arp_rpy_cnt <= 0;
                end else begin
                    if(tx_head_fifo_head != tx_head_fifo_tail)begin //有数据要发
                        //无对应，请求arp
                        arp_rpy_cnt <= 0;
                        arp_target_ip <= tx_head_data_o_port;
                        //tx_head_fifo_tail <= (tx_head_fifo_tail + 1)%128;
                        arp_rpy_stauts <= 2;
                        longdelay <= 50000;//1ms
                        if(tx_head_data_o_port == arp_ip_0 && arp_list[0])begin//对应arp0
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1)%16'd64;
                            arp_target_mac <= arp_mac_0;
                            arp_rpy_stauts <= 3;
                        end
                        if(tx_head_data_o_port == arp_ip_1 && arp_list[1])begin//对应arp1
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1)%16'd64;
                            arp_target_mac <= arp_mac_1;
                            arp_rpy_stauts <= 3;
                        end
                        if(tx_head_data_o_port == 32'hFFFFFFFF)begin//广播
                            tx_head_fifo_tail <= (tx_head_fifo_tail + 1)%16'd64;
                            arp_target_mac <= 48'hFFFFFFFFFFFF;
                            arp_rpy_stauts <= 3;
                        end
                    end else begin //定时请求arp刷新
                        arp_refresh_cnt <= arp_refresh_cnt + 1;
                        if(arp_refresh_cnt >= arp_refresh_interval)begin
                            arp_refresh_cnt <= 0;

                            if(arp_list != 2'b00)begin
                                arp_rpy_stauts <= 2;
                                arp_rpy_cnt <= 0;
                            end
                            
                            if(arp_list == 2'b11)begin
                                arp_lst_refresh <= ~arp_lst_refresh;
                                arp_clean[~arp_lst_refresh] <= 1'b1;

                                if(arp_lst_refresh == 0)begin
                                    arp_target_ip <= arp_ip_1;
                                end else begin
                                    arp_target_ip <= arp_ip_0;
                                end
                            end
                            if(arp_list == 2'b10)begin
                                arp_clean[1] <= 1'b1;

                                arp_target_ip <= arp_ip_1;
                            end
                            if(arp_list == 2'b01)begin
                                arp_clean[0] <= 1'b1;

                                arp_target_ip <= arp_ip_0;
                            end
                        end
                    end
                end
                
            end
            1:begin
                test_tx_en <= 1'b1;
                if(arp_rpy_cnt < 6)
                    test_data <= arp_request == 4?arp_mac_0[(5-arp_rpy_cnt)*8 +: 8]:arp_mac_1[(5-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 12 && arp_rpy_cnt < 21)
                    test_data <= arp_head[20-arp_rpy_cnt];
                if(arp_rpy_cnt == 21)
                    test_data <= 8'h02;
                if(arp_rpy_cnt >= 22 && arp_rpy_cnt < 28)
                    test_data <= mac_adr[(27-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 28 && arp_rpy_cnt < 32)
                    test_data <= ip_adr[(31-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 32 && arp_rpy_cnt < 38)
                    test_data <= arp_request == 4?arp_mac_0[(37-arp_rpy_cnt)*8 +: 8]:arp_mac_1[(37-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 38 && arp_rpy_cnt < 42)
                    test_data <= arp_request == 4?arp_ip_0[(41-arp_rpy_cnt)*8 +: 8]:arp_ip_1[(41-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt == 42)
                    arp_rpy_fin <= 1'b1;
                if(arp_rpy_cnt >= 42)begin
                    test_tx_en<= 1'b0;
                end
                if(arp_rpy_cnt == 46)
                    arp_rpy_stauts <= 10;
            end
            2:begin //发送arp请求
                test_tx_en <= 1'b1;
                if(arp_rpy_cnt < 6)
                    test_data <= 8'hFF;
                if(arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 12 && arp_rpy_cnt < 21)
                    test_data <= arp_head[20-arp_rpy_cnt];
                if(arp_rpy_cnt == 21)
                    test_data <= 8'h01;
                if(arp_rpy_cnt >= 22 && arp_rpy_cnt < 28)
                    test_data <= mac_adr[(27-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 28 && arp_rpy_cnt < 32)
                    test_data <= ip_adr[(31-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 32 && arp_rpy_cnt < 38)
                    test_data <= 8'h00;
                if(arp_rpy_cnt >= 38 && arp_rpy_cnt < 42)
                    test_data <= arp_target_ip[(41-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt == 42)
                    arp_rpy_fin <= 1'b1;
                if(arp_rpy_cnt >= 42)begin
                    test_tx_en<= 1'b0;
                end
                if(arp_rpy_cnt == 46)
                    arp_rpy_stauts <= 10;
            end
            3:begin //发送数据
                if(arp_rpy_cnt == 1)begin
                    tx_head_fifo_tail <= (tx_head_fifo_tail + 1)%16'd64;
                    len_buf <= tx_head_data_o_port[15:0];
                end

                test_tx_en <= 1'b1;
                if(arp_rpy_cnt < 6)
                    test_data <= arp_target_mac[(5-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 6 && arp_rpy_cnt < 12)
                    test_data <= mac_adr[(11-arp_rpy_cnt)*8 +: 8];
                if(arp_rpy_cnt >= 12 && arp_rpy_cnt < len_buf)begin
                    test_data <= tx_data_data_o_port;
                end
                if(arp_rpy_cnt >= 11 && arp_rpy_cnt < len_buf - 1)
                    tx_data_fifo_tail <= (tx_data_fifo_tail + 1)%16'd8192;
                if(arp_rpy_cnt == len_buf - 1)begin
                    arp_rpy_stauts <= 10;
                end
            end
            10:begin
                if(longdelay)longdelay<=longdelay-1;
                if(tx_bz == 1'b0 && longdelay == 0)
                    arp_rpy_stauts <= 0;
            end
        endcase
    end
end


/*
int test_cntl;
logic[31:0] ob_head_o;
logic[7:0] ob_data_o;
logic ob_head_en;
logic ob_data_en;
logic ob_fin;
logic ob_busy;
udp_generator #(.ip_adr(ip_adr)) udp_gen (
    .clk(clk50m),.rst(phy_rdy),
    .data(test_cntl[7:0]),
    .tx_en(test_cntl<50),
    .req(test_cntl == 100),
    .ip_adr_i({8'd192,8'd168,8'd15,8'd15}),
    .src_port(16'd1234),
    .dst_port(16'd5678),
    .head_o(ob_head_o),
    .data_o(ob_data_o),
    .head_en(ob_head_en),
    .data_en(ob_data_en),
    .fin(ob_fin),
    .busy(ob_busy)
);

shortint head_cnt;
shortint data_cnt;

always@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy == 0)begin
        head_cnt <= 0;
        data_cnt <= 0;
    end else begin
        if(ob_head_en)
            head_cnt <= head_cnt + 16'd1;
        
        if(ob_data_en)
            data_cnt <= data_cnt + 16'd1;
        
        if(ob_fin)begin
            head_cnt <= 0;
            data_cnt <= 0;
            tx_data_fifo_head <= (tx_data_fifo_head + data_cnt)%16'd8192;
            tx_head_fifo_head <= (tx_head_fifo_head + head_cnt)%16'd64;
        end

        if(ob_data_en)begin
            tx_data_fifo[(tx_data_fifo_head+data_cnt)%8192] <= ob_data_o;
        end

        if(ob_head_en)begin
            tx_head_fifo[(tx_head_fifo_head+head_cnt)%64] <= ob_head_o;
        end
    end
end

always@(posedge clk50m)begin
    test_cntl <= test_cntl + 1;
    if(test_cntl > 50000000)test_cntl <= 0;

end*/


/*

    input logic [31:0] tx_ip_i,
    input logic [15:0] tx_src_port_i,
    input logic [15:0] tx_dst_port_i,
    input logic tx_req_i,
    input logic [7:0] tx_data_i,
    input logic tx_data_av,

    output logic tx_req_rdy_o,
    output logic tx_data_rdy_o
    */

logic[31:0] ob_head_o;
logic[7:0] ob_data_o;
logic ob_head_en;
logic ob_data_en;
logic ob_fin;
logic ob_busy;
logic ob_full;
shortint head_cnt;
shortint data_cnt;

udp_generator #(.ip_adr(ip_adr)) udp_gen (
    .clk(clk50m),.rst(phy_rdy),
    .data(tx_data_i),
    .tx_en(tx_data_av_i),
    .req(tx_req_i),
    .ip_adr_i(tx_ip_i),
    .src_port(tx_src_port_i),
    .dst_port(tx_dst_port_i),

    .head_o(ob_head_o),
    .data_o(ob_data_o),
    .head_en(ob_head_en),
    .data_en(ob_data_en),
    .fin(ob_fin),
    .busy(ob_busy),
    .full(ob_full)
);

always_comb begin
    tx_req_rdy_o <= ~ob_busy;
    tx_data_rdy_o <= ~ob_full;
end


always@(posedge clk50m or negedge phy_rdy)begin
    if(phy_rdy == 0)begin
        head_cnt <= 0;
        data_cnt <= 0;

        tx_data_fifo_head <= 0;
        tx_head_fifo_head <= 0;
    end else begin
        if(ob_head_en)
            head_cnt <= head_cnt + 16'd1;
        
        if(ob_data_en)
            data_cnt <= data_cnt + 16'd1;
        
        if(ob_fin)begin
            head_cnt <= 0;
            data_cnt <= 0;
            tx_data_fifo_head <= (tx_data_fifo_head + data_cnt)%16'd8192;
            tx_head_fifo_head <= (tx_head_fifo_head + head_cnt)%16'd64;
        end

        if(ob_data_en)begin
            tx_data_fifo[(tx_data_fifo_head+data_cnt)%8192] <= ob_data_o;
        end

        if(ob_head_en)begin
            tx_head_fifo[(tx_head_fifo_head+head_cnt)%64] <= ob_head_o;
        end
    end
end


endmodule

//1 = read, 0 = write
module SMI_ct(
    input clk, rst, rw, trg,
    [4:0] phy_adr, reg_adr,
    [15:0] data,
    output logic ready, ack,
    logic [15:0] smi_data,
    inout logic mdio
);

    byte ct;
    reg rmdio;

    reg [31:0] tx_data;
    reg [15:0] rx_data;

    assign mdio = rmdio?1'bZ:1'b0;

    always_comb begin
        smi_data <= rx_data;
    end

    always_ff@(posedge clk or negedge rst)begin
        if(rst == 1'b0)begin
            ct <= 0;
            ready <= 1'b0;
            ack <= 1'b0;

            rmdio <= 1'b1;
        end else begin
            ct <= ct + 8'd1;
            if(ct == 0 && trg == 1'b0)ct<=0;
            if(ct == 0 && trg == 1'b1)begin
                ready <= 1'b0;
                ack <= 1'b0;
            end

            if(ct == 64)begin
                ready <= 1'b1;
            end

            if(trg == 1'b1 && ready == 1'b1)begin
                ready <= 1'b0;
            end

            rmdio <= 1'b1;

            if(ct == 4 && trg == 1'b1)begin
                tx_data <= {2'b01, rw?2'b10:2'b01, phy_adr, reg_adr, rw?2'b11:2'b10, rw?16'hFFFF:data};
            end

            if(ct>31)begin
                rmdio <= tx_data[31];
                tx_data <= {tx_data[30:0], 1'b1};
            end

            if(ct == 48 && mdio == 1'b0)begin
                ack <= 1'b1;
            end
            
            if(ct>48)begin
                rx_data <= {rx_data[14:0], mdio};
            end
        end
    end
endmodule

module CRC_check(
    input clk,
    input rst,

    input [7:0] data,
    input av,
    input stp,

    output logic [7:0] data_gd,
    output logic rdy,
    output logic fin
);

logic[7:0] buffer[2047:0];

logic[31:0] crc;
logic[31:0] crc_next;

logic [7:0] data_i;

assign data_i = {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]};

assign crc_next[0] = crc[24] ^ crc[30] ^ data_i[0] ^ data_i[6];
assign crc_next[1] = crc[24] ^ crc[25] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[6] ^ data_i[7];
assign crc_next[2] = crc[24] ^ crc[25] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[3] = crc[25] ^ crc[26] ^ crc[27] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7];
assign crc_next[4] = crc[24] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[5] = crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[6] = crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[7] = crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[7];
assign crc_next[8] = crc[0] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[9] = crc[1] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5];
assign crc_next[10] = crc[2] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5];
assign crc_next[11] = crc[3] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[12] = crc[4] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6];
assign crc_next[13] = crc[5] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[14] = crc[6] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[7];
assign crc_next[15] =  crc[7] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[16] = crc[8] ^ crc[24] ^ crc[28] ^ crc[29] ^ data_i[0] ^ data_i[4] ^ data_i[5];
assign crc_next[17] = crc[9] ^ crc[25] ^ crc[29] ^ crc[30] ^ data_i[1] ^ data_i[5] ^ data_i[6];
assign crc_next[18] = crc[10] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[19] = crc[11] ^ crc[27] ^ crc[31] ^ data_i[3] ^ data_i[7];
assign crc_next[20] = crc[12] ^ crc[28] ^ data_i[4];
assign crc_next[21] = crc[13] ^ crc[29] ^ data_i[5];
assign crc_next[22] = crc[14] ^ crc[24] ^ data_i[0];
assign crc_next[23] = crc[15] ^ crc[24] ^ crc[25] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[6];
assign crc_next[24] = crc[16] ^ crc[25] ^ crc[26] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[7];
assign crc_next[25] = crc[17] ^ crc[26] ^ crc[27] ^ data_i[2] ^ data_i[3];
assign crc_next[26] = crc[18] ^ crc[24] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[27] = crc[19] ^ crc[25] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[1] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[28] = crc[20] ^ crc[26] ^ crc[29] ^ crc[30] ^ data_i[2] ^ data_i[5] ^ data_i[6];
assign crc_next[29] = crc[21] ^ crc[27] ^ crc[30] ^ crc[31] ^ data_i[3] ^ data_i[6] ^ data_i[7];
assign crc_next[30] = crc[22] ^ crc[28] ^ crc[31] ^ data_i[4] ^ data_i[7];
assign crc_next[31] = crc[23] ^ crc[29] ^ data_i[5];


shortint begin_ptr;
shortint end_ptr;

logic sendout;

logic [7:0] bdata_gd;
logic brdy;
logic bfin;

always_ff@(posedge clk or negedge rst)begin
    if(rst == 1'b0)begin
        begin_ptr <= 0;
        end_ptr <= 0;
        rdy <= 1'b0;
        fin <= 1'b0;

        brdy <= 1'b0;
        bfin <= 1'b0;

        sendout <= 1'b0;

        crc <= 32'hFFFFFFFF;
    end else begin
        data_gd <= bdata_gd;
        rdy <= brdy;
        fin <= bfin;

        bdata_gd <= buffer[begin_ptr];
        brdy <= 1'b0;
        bfin <= 1'b0;



        if(sendout)begin
            brdy <= 1'b1;
            if(begin_ptr == end_ptr)begin
                sendout <= 1'b0;
                bfin <= 1'b1;
            end else begin
                begin_ptr <= begin_ptr + 16'd1;
                if(begin_ptr == 2047)begin_ptr<=0;
            end
        end


        if(stp)begin
            if(crc == 32'hC704DD7B)begin
                //start output the data
                sendout <= 1'b1;
                end_ptr <= (end_ptr + 16'd2043)%16'd2048;
            end else begin
                //drop the data
                begin_ptr <= end_ptr;
            end
            crc <= 32'hFFFFFFFF;
        end else begin
            if(av)begin
                buffer[end_ptr] <= data;
                end_ptr <= end_ptr + 16'd1;
                if(end_ptr == 2047)end_ptr<=0;

                crc <= crc_next;
            end
        end
    end
end


endmodule


module tx_ct(
    input clk, rst,
    input [7:0] data,
    input tx_en,
    output logic tx_av,
    output logic tx_bz,

    output logic [1:0] p_txd,
    output logic p_txen
);

logic[7:0] buffer[2047:0];
shortint begin_ptr;
shortint end_ptr;
logic[7:0] buffer_out;

byte send_status;

byte tick;
shortint send_cnt;

logic int_en;


logic[31:0] crc;
logic[31:0] crc_next;

logic crc_ct;
logic [7:0] crc_in;

logic [7:0] data_i;

assign data_i = {crc_in[0],crc_in[1],crc_in[2],crc_in[3],crc_in[4],crc_in[5],crc_in[6],crc_in[7]};

assign crc_next[0] = crc[24] ^ crc[30] ^ data_i[0] ^ data_i[6];
assign crc_next[1] = crc[24] ^ crc[25] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[6] ^ data_i[7];
assign crc_next[2] = crc[24] ^ crc[25] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[3] = crc[25] ^ crc[26] ^ crc[27] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7];
assign crc_next[4] = crc[24] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[5] = crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[6] = crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[7] = crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[7];
assign crc_next[8] = crc[0] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[9] = crc[1] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5];
assign crc_next[10] = crc[2] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5];
assign crc_next[11] = crc[3] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4];
assign crc_next[12] = crc[4] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[2] ^ data_i[4] ^ data_i[5] ^ data_i[6];
assign crc_next[13] = crc[5] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[30] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[7];
assign crc_next[14] = crc[6] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[7];
assign crc_next[15] =  crc[7] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[3] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[16] = crc[8] ^ crc[24] ^ crc[28] ^ crc[29] ^ data_i[0] ^ data_i[4] ^ data_i[5];
assign crc_next[17] = crc[9] ^ crc[25] ^ crc[29] ^ crc[30] ^ data_i[1] ^ data_i[5] ^ data_i[6];
assign crc_next[18] = crc[10] ^ crc[26] ^ crc[30] ^ crc[31] ^ data_i[2] ^ data_i[6] ^ data_i[7];
assign crc_next[19] = crc[11] ^ crc[27] ^ crc[31] ^ data_i[3] ^ data_i[7];
assign crc_next[20] = crc[12] ^ crc[28] ^ data_i[4];
assign crc_next[21] = crc[13] ^ crc[29] ^ data_i[5];
assign crc_next[22] = crc[14] ^ crc[24] ^ data_i[0];
assign crc_next[23] = crc[15] ^ crc[24] ^ crc[25] ^ crc[30] ^ data_i[0] ^ data_i[1] ^ data_i[6];
assign crc_next[24] = crc[16] ^ crc[25] ^ crc[26] ^ crc[31] ^ data_i[1] ^ data_i[2] ^ data_i[7];
assign crc_next[25] = crc[17] ^ crc[26] ^ crc[27] ^ data_i[2] ^ data_i[3];
assign crc_next[26] = crc[18] ^ crc[24] ^ crc[27] ^ crc[28] ^ crc[30] ^ data_i[0] ^ data_i[3] ^ data_i[4] ^ data_i[6];
assign crc_next[27] = crc[19] ^ crc[25] ^ crc[28] ^ crc[29] ^ crc[31] ^ data_i[1] ^ data_i[4] ^ data_i[5] ^ data_i[7];
assign crc_next[28] = crc[20] ^ crc[26] ^ crc[29] ^ crc[30] ^ data_i[2] ^ data_i[5] ^ data_i[6];
assign crc_next[29] = crc[21] ^ crc[27] ^ crc[30] ^ crc[31] ^ data_i[3] ^ data_i[6] ^ data_i[7];
assign crc_next[30] = crc[22] ^ crc[28] ^ crc[31] ^ data_i[4] ^ data_i[7];
assign crc_next[31] = crc[23] ^ crc[29] ^ data_i[5];



logic [7:0] crc_buffer;





always_comb begin
    //64 byte free
    tx_av <= (end_ptr + 2047 - begin_ptr)%2048 > 63;
    int_en <= tx_av && tx_en;
    if(crc_ct)
        crc_in<=buffer_out;
    else
        crc_in <= 8'b00000000;
    
    tx_bz <= send_status != 0;
end

always_ff@(posedge clk or negedge rst)begin
    if(rst == 1'b0)begin
        begin_ptr <= 0;
        end_ptr <= 0;
        send_status <= 0;
    end else begin
        p_txen <= 1'b0;
        tick<=tick + 8'd1;
        if(tick == 3)begin
            tick <= 0;
        end
        if(int_en)begin
            buffer[begin_ptr] <= data;
            begin_ptr <= begin_ptr + 16'd1;
            if(begin_ptr == 2047)begin_ptr<=0;
        end
        case(send_status)
            0:begin //idle wait for tx_en
                if(begin_ptr != end_ptr)begin
                    send_status <= 1;
                    send_cnt <= 0;
                    crc<=32'hFFFFFFFF;
                end
            end
            1:begin //send preamble and SFD
                send_cnt <= send_cnt + 8'd1;
                p_txd <= 2'b01;
                p_txen <= 1'b1;
                if(send_cnt == 31)begin
                    p_txd <= 2'b11;
                    send_status <=2;
                    send_cnt <= 0;
                    tick <= 0;
                    crc_ct <= 1'b1;
                end
            end
            2:begin //send payload
                if(tick == 0)crc<=crc_next;

                buffer_out <= {2'bXX,buffer_out[7:2]};
                p_txd <= buffer_out[1:0];
                p_txen <= 1'b1;
                if(tick == 2)begin
                    end_ptr <= end_ptr + 16'd1;
                    if(end_ptr == 2047)end_ptr<=0;
                end

                if(tick == 3 && send_cnt < 96)send_cnt <= send_cnt + 8'd1;
                
                if(tick == 3 && (end_ptr - begin_ptr)%2048 == 0)begin
                    crc_ct <= 1'b0;
                    if(send_cnt < 63)
                        send_status <= 3;
                    else begin
                        send_status <= 4;
                        send_cnt <= 0;

                        crc_buffer <= ~{crc[24],crc[25],crc[26],crc[27],crc[28],crc[29],crc[30],crc[31]};
                        crc<={crc[23:0],8'hXX};
                    end
                end
            end
            3:begin //send padding
                if(tick == 0)crc <= crc_next;
                p_txd <= 0;
                p_txen <= 1'b1;
                if(tick == 3)begin
                    send_cnt <= send_cnt + 8'd1;
                    if(send_cnt == 63)begin
                        send_status <= 4;
                        send_cnt <= 0;

                        crc_buffer <= ~{crc[24],crc[25],crc[26],crc[27],crc[28],crc[29],crc[30],crc[31]};
                        crc<={crc[23:0],8'hXX};
                    end
                end
            end
            4:begin //send CRC  
                p_txd <= crc_buffer[1:0];
                crc_buffer <= {2'bXX,crc_buffer[7:2]};
                p_txen <= 1'b1;

                if(tick == 3)begin
                    crc_buffer <= ~{crc[24],crc[25],crc[26],crc[27],crc[28],crc[29],crc[30],crc[31]};
                    crc<={crc[23:0],8'hXX};

                    send_cnt <= send_cnt + 8'd1;
                    if(send_cnt == 3)begin
                        send_status <= 5;
                        send_cnt <= 0;
                    end
                end
            end
            5:begin //wait for 4 cycles
                p_txd <= 2'bXX;
                p_txen <= 1'b0;
                if(tick == 3)begin
                    send_status <= 0;
                end
            end
        endcase
        if(tick == 3)begin
            buffer_out <= buffer[end_ptr];
        end
    end

end


endmodule


//先tx_en，把数据输进来，然后req，开始发送
module udp_generator #(parameter bit [31:0] ip_adr = 32'd0)(
    input clk, rst,
    input [7:0] data,
    input tx_en,
    input req,
    input [31:0] ip_adr_i,
    input [15:0] src_port,
    input [15:0] dst_port,

    output logic [31:0] head_o,
    output logic [7:0] data_o,
    output logic head_en,
    output logic data_en,
    output logic fin,

    output logic busy,

    output logic full
);

logic [7:0] buffer[2047:0];

shortint begin_ptr;
shortint end_ptr;

logic [7:0] buffer_port_i;
logic [7:0] buffer_port_o;
logic buffer_wr;

byte udp_gen_status;
shortint udp_gen_cnt;

logic [17:0] checksum;
logic [17:0] head_checksum;
logic [15:0] send_checksum;
logic [15:0] send_head_checksum;


logic [7:0] lst_in;

logic [15:0] sendlen;

logic [31:0] local_ip;
logic [31:0] local_src_port;
logic [31:0] local_dst_port;

logic [15:0] pack_num;
logic [15:0] head_len;
logic [15:0] udp_len;

always_comb begin
    head_len <= 16'd28 + sendlen[15:0];
    udp_len <= 16'd8 + sendlen[15:0];
    send_checksum <= 16'hFFEF - checksum[15:0];
    if(checksum[15:0]>16'hFFEF)begin
        send_checksum <= 16'hFFEF - 16'd1 - checksum[15:0];
    end
    send_head_checksum <= 16'h0000 - head_checksum[15:0];
end

logic [7:0] udp_head_p1 [3:0] = {8'h08, 8'h00, 8'h45, 8'h00};
logic [7:0] udp_head_p2 [3:0] = {8'h40, 8'h00, 8'h40, 8'h11};

always@(posedge clk or negedge rst)begin
    if(rst == 0)begin
        begin_ptr <= 0;
        end_ptr <= 0;
        head_en <= 1'b0;
        data_en <= 1'b0;
        fin <= 1'b0;

        buffer_wr <= 1'b0;
        udp_gen_status <= 0;

        checksum <= 18'h00000;
        head_checksum <= 18'h00000;
        sendlen <= 0;

        full <= 0;
    end else begin
        buffer_wr <= 1'b0;
        if(buffer_wr && (!full))
            buffer[end_ptr] <= buffer_port_i;
        buffer_port_o <= buffer[begin_ptr];

        full <= (end_ptr + 2048 - begin_ptr)%2048 > (2048-128);

        head_en <= 1'b0;
        data_en <= 1'b0;
        fin <= 1'b0;
        busy <= (udp_gen_status != 0) || req;

        udp_gen_cnt <= udp_gen_cnt + 16'd1;

        if(tx_en)begin
            lst_in <= data;

            buffer_wr <= 1'b1;
            buffer_port_i <= data;
            end_ptr <= (end_ptr + 1)%16'd2048;
            sendlen <= sendlen + 16'd1;
            if(sendlen[0] == 1'b1)begin
                checksum <= {2'b0,checksum[15:0]} + {lst_in,data} + {16'd0,checksum[17:16]};
            end
        end

        case(udp_gen_status)
            0:begin
                if(req)begin
                    udp_gen_status <= 1;
                    udp_gen_cnt <= 0;
                    local_ip <= ip_adr_i;
                    local_src_port <= src_port;
                    local_dst_port <= dst_port;
                    pack_num <= pack_num + 16'd1;

                    head_checksum <= 18'h0C512;
                end
            end
            1:begin 
                //length *2 + protocol + src_ip + dst_ip  + src_port + dst_port
                if(udp_gen_cnt == 0)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]} + {2'b00,sendlen} + {2'b00,sendlen} + 18'h11;
                end
                if(udp_gen_cnt == 1)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]} + {2'b00,ip_adr[31:16]} + {2'b00,ip_adr[15:0]};
                end
                if(udp_gen_cnt == 2)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]} + {2'b00,local_ip[31:16]} + {2'b00,local_ip[15:0]};
                end
                if(udp_gen_cnt == 3)begin
                    checksum <= 18'({2'b0,checksum[15:0]} + {16'd0,checksum[17:16]} + {2'b00,local_src_port} + {2'b00,local_dst_port});
                end
                if(udp_gen_cnt == 4)begin
                    if(sendlen[0] == 1'b1)begin
                        checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]} + {lst_in,8'd00};
                    end
                end
                if(udp_gen_cnt == 5)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]};
                end
                if(udp_gen_cnt == 6)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]};
                end
                if(udp_gen_cnt == 7)begin
                    checksum <= {2'b0,checksum[15:0]} + {16'd0,checksum[17:16]};
                end

                //headchksum, len + id + src_ip + dst_ip
                if(udp_gen_cnt == 0)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]} + {2'b00,pack_num};
                if(udp_gen_cnt == 1)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]} + {2'b00,head_len};
                if(udp_gen_cnt == 2)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]} + {2'b00,local_ip[31:16]} + {2'b00,local_ip[15:0]};
                if(udp_gen_cnt == 3)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]} + {2'b00,ip_adr[31:16]} + {2'b00,ip_adr[15:0]};
                if(udp_gen_cnt == 4)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]};
                if(udp_gen_cnt == 5)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]};
                if(udp_gen_cnt == 6)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]};
                if(udp_gen_cnt == 7)
                    head_checksum <= {2'b0,head_checksum[15:0]} + {16'd0,head_checksum[17:16]};
                
                if(udp_gen_cnt == 0)begin//push ip
                    head_en <= 1'b1;
                    head_o <= local_ip;
                end
                if(udp_gen_cnt == 1)begin//push length
                    head_en <= 1'b1;
                    head_o <= head_len + 14;
                end
                
                data_en <= 1'b1;
                if(udp_gen_cnt < 4)data_o <= udp_head_p1[3-udp_gen_cnt];
                if(udp_gen_cnt >= 4 && udp_gen_cnt < 6)data_o <= head_len[(5-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 6 && udp_gen_cnt < 8)data_o <= pack_num[(7-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 8 && udp_gen_cnt < 12)data_o <= udp_head_p2[11-udp_gen_cnt];
                if(udp_gen_cnt >= 12 && udp_gen_cnt < 14)data_o <= send_head_checksum[(13-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 14 && udp_gen_cnt < 18)data_o <= ip_adr[(17-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 18 && udp_gen_cnt < 22)data_o <= local_ip[(21-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 22 && udp_gen_cnt < 24)data_o <= local_src_port[(23-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 24 && udp_gen_cnt < 26)data_o <= local_dst_port[(25-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 26 && udp_gen_cnt < 28)data_o <= udp_len[(27-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 28 && udp_gen_cnt < 30)data_o <= send_checksum[(29-udp_gen_cnt)*8 +: 8];
                if(udp_gen_cnt >= 30)data_o <= buffer_port_o;

                if(udp_gen_cnt >= 28 && udp_gen_cnt < 28+sendlen)begin
                    begin_ptr <= (begin_ptr + 1)%16'd2048;
                end

                if(udp_gen_cnt == 29+sendlen)begin
                    udp_gen_status <= 2;
                    sendlen <= 0;
                end
            end
            2:begin
                fin <= 1'b1;
                udp_gen_status <= 0;

                checksum <= 18'h00000;
            end         

        endcase
    end
end


endmodule
