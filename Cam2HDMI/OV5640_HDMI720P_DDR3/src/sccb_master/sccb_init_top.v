module sccb_init_top #(
    parameter integer LUT_ADDR_WIDTH = 8,
    parameter integer DEV_ADDR_WIDTH = 8,
    parameter integer REG_ADDR_WIDTH = 16,
    parameter integer REG_DATA_WIDTH = 8,
    parameter integer I2C_FAST_MODE  = 1'b0,    // 0: ~100kHz, 1: ~400kHz
    parameter integer I2C_ACK_MODE   = 0,       // 0: ignore all, 1: only first ACK
    parameter integer INPUT_CLK_FREQ = 26'd50_000_000,
    parameter integer STARTUP_US     = 2000     // power-up wait before kicking, e.g., 2ms
)(
    input                        clk,
    input                        rst_n,

    input  [DEV_ADDR_WIDTH -1:0] lut_dev_addr,
    input  [REG_ADDR_WIDTH -1:0] lut_reg_addr,
    input  [REG_DATA_WIDTH -1:0] lut_reg_data,

    output [LUT_ADDR_WIDTH -1:0] lut_index,

    inout                        SDA,
    inout                        SCL,
    output                       INIT_DONE
);

    // Sender instance (note: ACK_MODE name)
    wire sender_done;
    reg  reg_rdy;

    // Latched copy of current LUT word
    reg [DEV_ADDR_WIDTH-1:0] dev_r;
    reg [REG_ADDR_WIDTH-1:0] reg_r;
    reg [REG_DATA_WIDTH-1:0] dat_r;

    reg [DEV_ADDR_WIDTH-1:0] dev_rr;
    reg [REG_ADDR_WIDTH-1:0] reg_rr;
    reg [REG_DATA_WIDTH-1:0] dat_rr;

    sccb_sender #(
        .DEV_ADDR_WIDTH (DEV_ADDR_WIDTH ),
        .REG_ADDR_WIDTH (REG_ADDR_WIDTH ),
        .REG_DATA_WIDTH (REG_DATA_WIDTH ),
        .I2C_FAST_MODE  (I2C_FAST_MODE  ),
        .INPUT_CLK_FREQ (INPUT_CLK_FREQ ),
        .I2C_ACK_MODE   (I2C_ACK_MODE   )  
    ) u_sender (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .lut_dev_addr   (dev_r          ),
        .lut_reg_addr   (reg_r          ),
        .lut_reg_data   (dat_r          ),
        .REG_RDY        (reg_rdy        ),
        .SDA            (SDA            ),
        .SCL            (SCL            ),
        .DONE           (sender_done    ),
        .ACK_OK         (               )  // unused in this top
    );


    // Pipeline LUT outputs before kicking sender
    localparam [7:0]  END_MARK_DEV = 8'hff;
    localparam [15:0] END_MARK_REG = 16'hffff;
    localparam [7:0]  END_MARK_DAT = 8'hff;

    reg [LUT_ADDR_WIDTH-1:0] index = {LUT_ADDR_WIDTH{1'b0}};
    assign lut_index = index;

    // Optional startup delay
    localparam integer STARTUP_CYC = (INPUT_CLK_FREQ/1_000_000) * STARTUP_US;
    localparam integer STARTUP_W   = (STARTUP_CYC <= 1) ? 1 : $clog2(STARTUP_CYC+1);
    reg [STARTUP_W-1:0] pwr_cnt = {STARTUP_W{1'b0}};
    wire startup_done = (pwr_cnt == STARTUP_CYC[STARTUP_W-1:0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwr_cnt <= 0;
        else if (!startup_done)
            pwr_cnt <= pwr_cnt + 1'b1;
    end

    // Init FSM: IDLE -> LOAD -> ALIGN -> KICK -> WAIT -> NEXT -> DONE
    localparam S_IDLE  = 7'b000_0001,
               S_LOAD  = 7'b000_0010,
               S_ALIGN = 7'b000_0100,
               S_KICK  = 7'b000_1000,
               S_WAIT  = 7'b001_0000,
               S_NEXT  = 7'b010_0000,
               S_DONE  = 7'b100_0000;

    reg [6:0] state;
    reg       done  = 1'b0;

    assign INIT_DONE = done;

    // END mark detection on the aligned (stable) registers
    wire LUT_DONE = (dev_r == END_MARK_DEV) &&
                    (reg_r == END_MARK_REG) &&
                    (dat_r == END_MARK_DAT);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            index   <= {LUT_ADDR_WIDTH{1'b0}};
            reg_rdy <= 1'b0;
            done    <= 1'b0;
    
            dev_r   <= {DEV_ADDR_WIDTH{1'b0}};
            reg_r   <= {REG_ADDR_WIDTH{1'b0}};
            dat_r   <= {REG_DATA_WIDTH{1'b0}};
            dev_rr  <= {DEV_ADDR_WIDTH{1'b0}};
            reg_rr  <= {REG_ADDR_WIDTH{1'b0}};
            dat_rr  <= {REG_DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                S_IDLE: begin
                    done    <= 1'b0;
                    reg_rdy <= 1'b0;
                    if (startup_done) begin
                        index <= {LUT_ADDR_WIDTH{1'b0}};
                        state <= S_LOAD;
                    end
                end
    
                // 1st cycle: capture LUT outputs into rr
                S_LOAD: begin
                    dev_rr <= lut_dev_addr;
                    reg_rr <= lut_reg_addr;
                    dat_rr <= lut_reg_data;
                    state  <= S_ALIGN;
                end
    
                // 2nd cycle: align rr into r (used by sender and end-check)
                S_ALIGN: begin
                    dev_r <= dev_rr;
                    reg_r <= reg_rr;
                    dat_r <= dat_rr;
                    state <= S_KICK;
                end
    
                S_KICK: begin
                    if (LUT_DONE) begin
                        state <= S_DONE;
                    end else begin
                        reg_rdy <= 1'b1;     // one-cycle pulse
                        state   <= S_WAIT;
                    end
                end
    
                S_WAIT: begin
                    reg_rdy <= 1'b0;
                    if (sender_done)
                        state <= S_NEXT;
                end
    
                S_NEXT: begin
                    index <= index + 1'b1;
                    state <= S_LOAD;
                end
    
                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_DONE;
                end
    
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule