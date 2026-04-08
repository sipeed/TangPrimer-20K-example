module sccb_sender #(
    parameter integer DEV_ADDR_WIDTH = 8,
    parameter integer REG_ADDR_WIDTH = 16,           // 8 or 16
    parameter integer REG_DATA_WIDTH = 8,
    parameter integer I2C_FAST_MODE  = 1'b0,         // 0: ~100kHz, 1: ~400kHz
    parameter integer I2C_ACK_MODE   = 1'b0,         // 0: Ignore all ACKs, 1: Only detect the first ACK
    parameter integer INPUT_CLK_FREQ = 26'd50_000_000
)(
    input                         clk,               // 35/50 MHz, etc.
    input                         rst_n,             // reset_n
     
    input  [DEV_ADDR_WIDTH -1:0]  lut_dev_addr,      // 8-bit device address (including R/W=0)
    input  [REG_ADDR_WIDTH -1:0]  lut_reg_addr,      // 8 or 16-bit register address
    input  [REG_DATA_WIDTH -1:0]  lut_reg_data,      // 8-bit lut register data
     
    input                         REG_RDY,           // Trig for send
 
    inout                         SDA,
    inout                         SCL,
    output reg                    DONE,
    output reg                    ACK_OK             // Only valid when I2C_ACK_MODE=1
);

    generate
        if (!(REG_ADDR_WIDTH == 8 || REG_ADDR_WIDTH == 16)) begin : g_check_aw
            initial $error("REG_ADDR_WIDTH must be 8 or 16");
        end
        if (DEV_ADDR_WIDTH < 8) begin : g_check_dw
            initial $error("DEV_ADDR_WIDTH must be >= 8");
        end
        if (REG_DATA_WIDTH < 8) begin : g_check_rw
            initial $error("REG_DATA_WIDTH must be >= 8");
        end
        if (!(I2C_ACK_MODE == 0 || I2C_ACK_MODE == 1)) begin : g_check_ackm
            initial $error("I2C_ACK_MODE must be 0 or 1");
        end
        if (!(I2C_FAST_MODE == 0 || I2C_FAST_MODE == 1 || I2C_FAST_MODE == 2)) begin : g_check_spd
            initial $error("I2C_FAST_MODE must be 0(~100k), 1(~400k), or 2(~50k)");
        end
    endgenerate

    // f_scl ≈ INPUT_CLK_FREQ / (4 * SUBDIV)
    function integer clog2;
        input integer value;
        integer i;
        begin
            i = 0;
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    // f_scl ≈ INPUT_CLK_FREQ / (4 * SUBDIV
    localparam integer SCL_TARGET_HZ = (I2C_FAST_MODE == 2) ? 50_000 : (I2C_FAST_MODE == 1) ? 400_000 :100_000;
    localparam integer SUBDIV_RAW    = (INPUT_CLK_FREQ + (SCL_TARGET_HZ*2)) / (SCL_TARGET_HZ*4);
    localparam integer SUBDIV        = (SUBDIV_RAW < 1) ? 1 : SUBDIV_RAW;
    localparam integer SUBDIV_W      = clog2(SUBDIV);
    localparam integer SCL_ACTUAL_HZ = INPUT_CLK_FREQ / (4 * SUBDIV); // For simulation only

    // Frame: 2'b10 | DEV(8) | ACK | [REG_HI(8) | ACK] | REG_LO(8) | ACK | DATA(8) | ACK | 3'b011
    localparam integer ADDR16       = (REG_ADDR_WIDTH == 16) ? 1 : 0;
    localparam integer FRAME_BITS   = 2 + 8 + 1 + (ADDR16 ? (8 + 1) : 0) + 8 + 1 + 8 + 1 + 3;
    localparam integer STEP_W       = clog2(FRAME_BITS);

    // ACK step index
    localparam integer ACK1_IDX = 2 + 8;                          // 10
    localparam integer ACK2_IDX = 2 + 8 + 1 + (ADDR16 ? 8 : 0);   // 19
    localparam integer ACK3_IDX = 2 + 8 + 1 + (ADDR16 ? (8 + 1) : 0) + 8; // 28
    localparam integer ACK4_IDX = 2 + 8 + 1 + (ADDR16 ? (8 + 1) : 0) + 8 + 1 + 8; // 37 (16-bit address only)

    // Special step inex
    localparam integer STEP0          = 0;                      // Idle High
    localparam integer STEP_START     = 1;                      // START：phase==3 pull down
    localparam integer STEP_STOP_PREP = FRAME_BITS - 3;         // STOP Previous: phase==0 pull down
    localparam integer STEP_STOP_HI1  = FRAME_BITS - 2;         // STOP keep high
    localparam integer STEP_STOP_HI2  = FRAME_BITS - 1;         // STOP keep high (Final Step)

    // Run/Step/Phase
    reg run;
    reg [STEP_W-1:0]   step;   // 0..FRAME_BITS-1 (One bit per step)
    reg [SUBDIV_W-1:0] sub;    // Sub-divider
    reg [1:0]          phase;  // 0,1,2,3 Quarter-section phase
    
    // step_slow: Shadow register for Step
    localparam [STEP_W-1:0] FRAME_BITS_M1 = FRAME_BITS - 1;

    reg [STEP_W-1:0] step_slow;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            step_slow <= {STEP_W{1'b0}};
        else
            step_slow <= step;
    end


    // SCL/SDA and shift data
    reg sio_c;                 
    reg sio_d_send;            // 1 = drive SDA, 0 = release (ACK window)
    reg [FRAME_BITS-1:0] data_temp;

    wire [7:0] dev_lo  = lut_dev_addr[7:0];
    wire [7:0] addr_hi = ADDR16 ? lut_reg_addr[15:8] : 8'h00;
    wire [7:0] addr_lo = lut_reg_addr[7:0];
    wire [7:0] data_lo = lut_reg_data[7:0];

    wire sda_in = SDA;

    reg reg_rdy_q, reg_rdy_qq;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_rdy_q  <= 1'b0;
            reg_rdy_qq <= 1'b0;
        end else begin
            reg_rdy_q  <= REG_RDY;
            reg_rdy_qq <= reg_rdy_q;
        end
    end

    wire DAT_RDY = (reg_rdy_q & ~reg_rdy_qq) & ~run; 

    // START/STOP/DONE/ACK_OK

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            run    <= 1'b0;
            step   <= {STEP_W{1'b0}};
            sub    <= {SUBDIV_W{1'b0}};
            phase  <= 2'd0;
            DONE   <= 1'b0;
            ACK_OK <= 1'b0;
        end 
        else begin
            DONE <= 1'b0;
            if (!run) begin
                if (DAT_RDY) begin
                    run    <= 1'b1;
                    step   <= {STEP_W{1'b0}};
                    sub    <= {SUBDIV_W{1'b0}};
                    phase  <= 2'd0;
                    ACK_OK <= 1'b0; // Restart a transaction here
                end
            end 
            else begin
                if (sub == SUBDIV-1) begin
                    sub <= {SUBDIV_W{1'b0}};
                    if (phase == 2'd3) begin
                        phase <= 2'd0;
                        if (step_slow == FRAME_BITS_M1) begin
                            run  <= 1'b0;
                            step <= {STEP_W{1'b0}};
                            DONE <= 1'b1; // Completed marker pulse
                        end 
                        else begin
                            step <= step_slow + {{(STEP_W-1){1'b0}}, 1'b1};
                        end
                    end 
                    else begin
                        phase <= phase + 2'd1;
                    end
                end 
                else begin
                    sub <= sub + {{(SUBDIV_W-1){1'b0}}, 1'b1};
                end

                // Mode 1: Sample the first ACK and sample later in the SCL high period
                if ((I2C_ACK_MODE == 1) && (step == ACK1_IDX) 
                                        && (phase == 2'd2) 
                                        && (sub == SUBDIV-1)) 
                begin
                    ACK_OK <= (sda_in == 1'b0); // 1'b0 equals a valid response
                end
            end
        end
    end

    // SCL generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sio_c <= 1'b1;
        end 
        else if (!run) begin
            sio_c <= 1'b1;
        end 
        else begin
            if (step == STEP0) begin
                sio_c <= 1'b1;
            end 
            else if (step == STEP_START) begin
                sio_c <= (phase == 2'd3) ? 1'b0 : 1'b1;
            end 
            else if (step == STEP_STOP_PREP) begin
                sio_c <= (phase == 2'd0) ? 1'b0 : 1'b1;
            end 
            else if (step == STEP_STOP_HI1 || step == STEP_STOP_HI2) begin
                sio_c <= 1'b1;
            end 
            else begin // Clock: 0/3 low, 1/2 high
                case (phase)
                    2'd0, 2'd3: sio_c <= 1'b0;
                    2'd1, 2'd2: sio_c <= 1'b1;
                    default:    sio_c <= 1'b1;
                endcase
            end
        end
    end

    // ACK window: Release SDA
    wire ack_step = (step == ACK1_IDX) || (step == ACK2_IDX) 
                                       || (step == ACK3_IDX) 
                                       ||(ADDR16 && (step == ACK4_IDX));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sio_d_send <= 1'b1;
        end 
        else if (!run) begin
            sio_d_send <= 1'b1;
        end 
        else begin
            sio_d_send <= ~ack_step; // Release SDA on ACK bit; this IS NOT the ACK bit drives transmit bit
        end
    end


    // Data loading and shifting (phase shift at the start of each SCL cycle)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_temp <= {FRAME_BITS{1'b1}};
        end 
        else begin
            if (!run && DAT_RDY) begin
                if (ADDR16) begin
                    // 2 | DEV | A | REG_HI | A | REG_LO | A | DATA | A | 3
                    data_temp <= { 2'b10, dev_lo, 1'b1, addr_hi, 1'b1, addr_lo, 1'b1, data_lo, 1'b1, 3'b011 };
                end 
                else begin
                    // 2 | DEV | A | REG_LO | A | DATA | A | 3
                    data_temp <= { 2'b10, dev_lo, 1'b1, addr_lo, 1'b1, data_lo, 1'b1, 3'b011 };
                end
            end 
            //else if (run && (sub == {SUBDIV_W{1'b0}}) && (phase == 2'd3)) begin
            //    data_temp <= { data_temp[FRAME_BITS-2:0], 1'b1 };
            //end
        end
    end
    

    wire sda_bit_now = data_temp[FRAME_BITS-1 - step];
    //assign SDA = sio_d_send ? data_temp[FRAME_BITS-1] : 1'bz;
    assign SDA = sio_d_send ? sda_bit_now : 1'bz;
    assign SCL = sio_c;

endmodule