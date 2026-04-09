module uart_tx
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)
(
	input                        clk,              //clock input
	input                        rst_n,            //asynchronous reset input, low active 
	input[7:0]                   tx_data,          //data to send
	input                        tx_data_valid,    //data to be sent is valid
	output                       tx_data_ready,    //send ready
	output                       tx_pin,           //serial data output
    output                       tx_busy
);
//calculates the clock cycle for baud rate 
localparam              integer CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
localparam              integer CNT_W = (CYCLE <= 1) ? 1 : $clog2(CYCLE);
localparam [CNT_W-1:0]          CYCLE_MAX = CYCLE-1;

//initial begin
//  if (CYCLE < 2) $error("CYCLE too small: check CLK_FRE and BAUD_RATE");
//end

//state machine code
localparam [2:0]                 S_IDLE       = 3'd1;
localparam [2:0]                 S_START      = 3'd2;//start bit
localparam [2:0]                 S_SEND_BYTE  = 3'd3;//data bits
localparam [2:0]                 S_STOP       = 3'd4;//stop bit

reg[CNT_W-1:0]                   cycle_cnt;     //baud counter
reg[2:0]                         state;
reg[2:0]                         next_state;
reg[2:0]                         bit_cnt;       //bit counter
reg[7:0]                         tx_data_latch; //latch data to send
reg                              tx_reg;        //serial data output

wire   bit_tick = (cycle_cnt == CYCLE_MAX);
wire   accept = (state == S_IDLE) && tx_data_valid;
assign tx_data_ready = (state == S_IDLE);
assign tx_busy = (state != S_IDLE);

assign tx_pin = tx_reg;
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		state <= S_IDLE;
	else
		state <= next_state;
end

always@(*)
begin
	case(state)
		S_IDLE:
			if(tx_data_valid == 1'b1)
				next_state = S_START;
			else
				next_state = S_IDLE;
		S_START:
			if(bit_tick)
				next_state = S_SEND_BYTE;
			else
				next_state = S_START;
		S_SEND_BYTE:
			if(bit_tick  && bit_cnt == 3'd7)
				next_state = S_STOP;
			else
				next_state = S_SEND_BYTE;
		S_STOP:
			if(bit_tick)
				next_state = S_IDLE;
			else
				next_state = S_STOP;
		default:
			next_state = S_IDLE;
	endcase
end

/*
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_ready <= 1'b0;
		end
	else if(state == S_IDLE)
		if(tx_data_valid == 1'b1)
			tx_data_ready <= 1'b0;
		else
			tx_data_ready <= 1'b1;
	else if(state == S_STOP && cycle_cnt == CYCLE - 1)
			tx_data_ready <= 1'b1;
end
*/

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_latch <= 8'd0;
		end
	else if(accept)
			tx_data_latch <= tx_data;
		
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			bit_cnt <= 3'd0;
		end
	else if(state == S_SEND_BYTE)
		if(cycle_cnt == CYCLE - 1)
			bit_cnt <= bit_cnt + 3'd1;
		else
			bit_cnt <= bit_cnt;
	else
		bit_cnt <= 3'd0;
end

/*
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		cycle_cnt <= 'd0;
	else if((state == S_SEND_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
		cycle_cnt <= 'd0;
	else
		cycle_cnt <= cycle_cnt + 'd1;	
end
*/

always @(posedge clk or negedge rst_n) begin
   if(!rst_n) cycle_cnt <= 'd0;
   else if (state == S_IDLE) 
     cycle_cnt <= 'd0;             
   else if (bit_tick)        
     cycle_cnt <= 'd0;
   else                      
     cycle_cnt <= cycle_cnt + 1'b1;
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		tx_reg <= 1'b1;
	else
		case(state)
			S_IDLE,S_STOP:
				tx_reg <= 1'b1; 
			S_START:
				tx_reg <= 1'b0; 
			S_SEND_BYTE:
				tx_reg <= tx_data_latch[bit_cnt];
			default:
				tx_reg <= 1'b1; 
		endcase
end

endmodule 