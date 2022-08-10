module key_blink#(
    parameter frequency     = 27_000_000,       // OSCILLATOR frequency
    parameter default_count = (frequency/10)*5, // 0.5s
    parameter counter_1     = (frequency/10)*2, // 0.2s
    parameter counter_2     = (frequency/10)*8, // 0.8s
    parameter counter_3     = (frequency/10)*12, // 1.2s
    parameter counter_4     = (frequency/10)*20, // 2s

    parameter io_count = 120                  // IO numbers
)(
    input                     clk , // Clock in
    input      [1:0]          rst_n_i,
    input      [4:1]          user_key,
    output reg [io_count-1:0] led_o
);

assign rst_n = rst_n_i[0] ^ ~rst_n_i[1] ;

wire       led_idel;
reg [$clog2(default_count)-1:0] count_0 ;
reg        idel_0  ; 
reg [$clog2(counter_1)-1:0]     count_1 ;
reg        idel_1  ; 
reg [$clog2(counter_2)-1:0]     count_2 ;
reg        idel_2  ; 
reg [$clog2(counter_3)-1:0]     count_3 ;
reg        idel_3  ; 
reg [$clog2(counter_4)-1:0]     count_4 ;
reg        idel_4  ; 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_0 <= 'd0;
        idel_0  <= 'd0;
    end
    else if(count_0 < default_count - 1) begin
        count_0 <= count_0 + 1'b1;
        idel_0  <= 'd0;
    end
    else begin
        count_0 <= 'd0;
        idel_0  <= 'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_1 <= 'd0;
        idel_1  <= 'd0;
    end
    else if(count_1 < counter_1 - 1) begin
        count_1 <= count_1 + 1'b1;
        idel_1  <= 'd0;
    end
    else begin
        count_1 <= 'd0;
        idel_1  <= 'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_2 <= 'd0;
        idel_2  <= 'd0;
    end
    else if(count_2 < counter_2 - 1) begin
        count_2 <= count_2 + 1'b1;
        idel_2  <= 'd0;
    end
    else begin
        count_2 <= 'd0;
        idel_2  <= 'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_3 <= 'd0;
        idel_3  <= 'd0;
    end
    else if(count_3 < counter_3 - 1) begin
        count_3 <= count_3 + 1'b1;
        idel_3  <= 'd0;
    end
    else begin
        count_3 <= 'd0;
        idel_3  <= 'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_4 <= 'd0;
        idel_4  <= 'd0;
    end
    else if(count_4 < counter_4 - 1) begin
        count_4 <= count_4 + 1'b1;
        idel_4  <= 'd0;
    end
    else begin
        count_4 <= 'd0;
        idel_4  <= 'd1;
    end
end

assign led_idel = !user_key[4] ? idel_4 : !user_key[3] ? idel_3 : !user_key[2] ? idel_2 : !user_key[1] ? idel_1 : idel_0 ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        led_o <= ~('d0);
    else if(led_idel)
        led_o <= ~led_o;
    else
        led_o <= led_o;    
end

endmodule