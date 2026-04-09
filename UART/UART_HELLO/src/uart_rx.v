module uart_rx #(
    parameter integer CLK_FRE   = 50,              //clock frequency(Mhz)
    parameter integer BAUD_RATE = 115200    	   //serial baud rate
)(
	input                        clk,              //clock input
	input                        rst_n,            //asynchronous reset input, low active 
	output reg[7:0]              rx_data,          //received serial data
	output reg                   rx_data_valid,    //received serial data is valid
	input                        rx_data_ready,    //data receiver module ready
	input                        rx_pin            //serial data input
);
localparam integer CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
localparam integer CNT_W = (CYCLE <= 1) ? 1 : $clog2(CYCLE+1);

//initial begin
//  if (CYCLE < 2) $error("CYCLE too small: check CLK_FRE and BAUD_RATE");
//end


localparam [2:0] S_IDLE     = 3'd1;
localparam [2:0] S_START    = 3'd2;					//start bit
localparam [2:0] S_REC_BYTE = 3'd3;					//data bits
localparam [2:0] S_STOP     = 3'd4;					//stop bit
localparam [2:0] S_DATA     = 3'd5;

reg [2:0]  		state, next_state;
reg        		rx_d0, rx_d1;						//delay for rx_pin
wire       		rx_negedge;							//negedge of rx_pin

reg [7:0]  		rx_bits;							//temporary storage of received data
reg [CNT_W-1:0] cycle_cnt;							//baud counter
reg [2:0]  		bit_cnt;							//bit counter

assign rx_negedge = rx_d1 & ~rx_d0;

// 2-FF sync
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_d0 <= 1'b1;
        rx_d1 <= 1'b1;
    end else begin
        rx_d0 <= rx_pin;
        rx_d1 <= rx_d0;
    end
end

// state reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= S_IDLE;
    else       state <= next_state;
end

// next state
always @(*) begin
    case(state)
        S_IDLE: begin
            if(rx_negedge) next_state = S_START;
            else           next_state = S_IDLE;
        end

        // start bit: confirm at half-bit
        S_START: begin
            if(cycle_cnt == (CYCLE/2 - 1)) begin
                if(rx_d0 == 1'b0) next_state = S_REC_BYTE; // valid start
                else              next_state = S_IDLE;     // glitch
            end else begin
                next_state = S_START;
            end
        end

        S_REC_BYTE: begin
            if(cycle_cnt == (CYCLE - 1) && bit_cnt == 3'd7)
                next_state = S_STOP;
            else
                next_state = S_REC_BYTE;
        end

        // stop bit: sample mid-bit; require '1'
        S_STOP: begin
            if(cycle_cnt == (CYCLE - 1)) begin
                if(rx_d0 == 1'b1) next_state = S_DATA;  // good stop
                else              next_state = S_IDLE;  // framing error -> drop
            end else begin
                next_state = S_STOP;
            end
        end

        S_DATA: begin
            if(rx_data_ready) next_state = S_IDLE;
            else              next_state = S_DATA;
        end

        default: next_state = S_IDLE;
    endcase
end

// cycle counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cycle_cnt <= {CNT_W{1'b0}};
    end else begin
        if(next_state != state) begin
            cycle_cnt <= {CNT_W{1'b0}};
        end else begin
            // count within state
            if(state == S_REC_BYTE) begin
                if(cycle_cnt == (CYCLE-1)) cycle_cnt <= {CNT_W{1'b0}};
                else                       cycle_cnt <= cycle_cnt + 1'b1;
            end else begin
                // for START/STOP we only need up to half-bit
                if(cycle_cnt == (CYCLE-1)) cycle_cnt <= {CNT_W{1'b0}};
                else                       cycle_cnt <= cycle_cnt + 1'b1;
            end
        end
    end
end

// bit counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bit_cnt <= 3'd0;
    end else if(state == S_REC_BYTE) begin
        if(cycle_cnt == (CYCLE-1)) bit_cnt <= bit_cnt + 3'd1;
    end else begin
        bit_cnt <= 3'd0;
    end
end

// sample bits at mid-bit
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_bits <= 8'd0;
    end
    else if(state == S_REC_BYTE && cycle_cnt == (CYCLE - 1)) begin
        rx_bits[bit_cnt] <= rx_d0;
    end
end

// latch to output on entering DATA (only when stop bit good)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_data <= 8'd0;
    end else if(state == S_STOP && next_state == S_DATA) begin
        rx_data <= rx_bits;
    end
end

// valid handshake
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_data_valid <= 1'b0;
    end else begin
        if(state == S_STOP && next_state == S_DATA)
            rx_data_valid <= 1'b1;
        else if(state == S_DATA && rx_data_ready)
            rx_data_valid <= 1'b0;
    end
end

endmodule