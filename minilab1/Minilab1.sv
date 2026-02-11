`default_nettype none
//==============================================================================
// Minilab1 Top-Level Module
// Matrix-Vector Multiplication System for DE1-SoC Board
//==============================================================================
module Minilab1 (
    // Clock inputs
    input  wire        CLOCK_50,
    input  wire        CLOCK2_50,
    input  wire        CLOCK3_50,
    input  wire        CLOCK4_50,
    
    // 7-Segment displays (active low)
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    
    // LEDs
    output wire [9:0]  LEDR,
    
    // Push buttons (active low)
    input  wire [3:0]  KEY,
    
    // Slide switches
    input  wire [9:0]  SW
);

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam DATA_WIDTH = 8;
    localparam NUM_MACS = 8;
    localparam FIFO_DEPTH = 8;
    
    // Top-level state machine states
    localparam [2:0] ST_IDLE    = 3'd0;
    localparam [2:0] ST_FETCH   = 3'd1;
    localparam [2:0] ST_COMPUTE = 3'd2;
    localparam [2:0] ST_DONE    = 3'd3;
    
    //==========================================================================
    // Internal signals
    //==========================================================================
    wire clk;
    wire rst_n;
    
    assign clk = CLOCK_50;
    assign rst_n = KEY[0];  // Active low reset
    
    // Top-level state machine
    reg [2:0] state, next_state;
    
    // Memory controller signals
    wire [31:0] avm_address;
    wire        avm_read;
    wire [63:0] avm_readdata;
    wire        avm_readdatavalid;
    wire        avm_waitrequest;
    wire        mem_ctrl_done;
    wire [2:0]  mem_ctrl_state;
    reg         mem_ctrl_start;
    
    // FIFO interface signals
    wire [DATA_WIDTH-1:0]   fifo_a_data [0:NUM_MACS-1];
    wire [NUM_MACS-1:0]     fifo_a_wren;
    wire [NUM_MACS-1:0]     fifo_a_full;
    wire [DATA_WIDTH-1:0]   fifo_b_data;
    wire                    fifo_b_wren;
    wire                    fifo_b_full;
    
    // Matrix-vector multiplier signals
    wire                    all_fifos_full;
    wire                    compute_done;
    reg                     start_compute;
    reg                     clr_accum;
    wire [DATA_WIDTH*3-1:0] mac_out [0:NUM_MACS-1];
    
    // Display selection
    wire [2:0] mac_sel;
    wire [23:0] selected_mac_out;
    
    //==========================================================================
    // Memory Module Instance
    //==========================================================================
    mem_wrapper mem_inst (
        .clk(clk),
        .reset_n(rst_n),
        .address(avm_address),
        .read(avm_read),
        .readdata(avm_readdata),
        .readdatavalid(avm_readdatavalid),
        .waitrequest(avm_waitrequest)
    );
    
    //==========================================================================
    // Memory Controller Instance
    //==========================================================================
    mem_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_MACS(NUM_MACS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) mem_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(mem_ctrl_start),
        .avm_address(avm_address),
        .avm_read(avm_read),
        .avm_readdata(avm_readdata),
        .avm_readdatavalid(avm_readdatavalid),
        .avm_waitrequest(avm_waitrequest),
        .fifo_a_data(fifo_a_data),
        .fifo_a_wren(fifo_a_wren),
        .fifo_a_full(fifo_a_full),
        .fifo_b_data(fifo_b_data),
        .fifo_b_wren(fifo_b_wren),
        .fifo_b_full(fifo_b_full),
        .done(mem_ctrl_done),
        .state_out(mem_ctrl_state)
    );
    
    //==========================================================================
    // Matrix-Vector Multiplier Instance
    //==========================================================================
    mat_vec_mult #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_MACS(NUM_MACS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) mat_vec_mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_compute(start_compute),
        .clr_accum(clr_accum),
        .fifo_a_data(fifo_a_data),
        .fifo_a_wren(fifo_a_wren),
        .fifo_a_full(fifo_a_full),
        .fifo_b_data(fifo_b_data),
        .fifo_b_wren(fifo_b_wren),
        .fifo_b_full(fifo_b_full),
        .all_fifos_full(all_fifos_full),
        .compute_done(compute_done),
        .mac_out(mac_out)
    );
    
    //==========================================================================
    // Top-Level State Machine
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end
    
    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                // Start when KEY[1] is pressed (active low)
                if (!KEY[1])
                    next_state = ST_FETCH;
            end
            
            ST_FETCH: begin
                if (mem_ctrl_done)
                    next_state = ST_COMPUTE;
            end
            
            ST_COMPUTE: begin
                if (compute_done)
                    next_state = ST_DONE;
            end
            
            ST_DONE: begin
                // Stay in done state, can restart with KEY[1]
                if (!KEY[1])
                    next_state = ST_IDLE;
            end
            
            default: next_state = ST_IDLE;
        endcase
    end
    
    // Control signal generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ctrl_start <= 1'b0;
            start_compute <= 1'b0;
            clr_accum <= 1'b0;
        end else begin
            // Default
            clr_accum <= 1'b0;
            
            case (state)
                ST_IDLE: begin
                    mem_ctrl_start <= 1'b0;
                    start_compute <= 1'b0;
                    if (!KEY[1]) begin
                        clr_accum <= 1'b1;  // Clear accumulators before starting
                    end
                end
                
                ST_FETCH: begin
                    mem_ctrl_start <= 1'b1;
                    if (mem_ctrl_done) begin
                        start_compute <= 1'b1;
                    end
                end
                
                ST_COMPUTE: begin
                    mem_ctrl_start <= 1'b0;
                    start_compute <= 1'b1;
                end
                
                ST_DONE: begin
                    mem_ctrl_start <= 1'b0;
                    start_compute <= 1'b0;
                end
            endcase
        end
    end
    
    //==========================================================================
    // Display Logic
    //==========================================================================
    // SW[2:0] selects which MAC output to display (0-7)
    // SW[9] enables display
    assign mac_sel = SW[2:0];
    
    // Mux to select MAC output
    assign selected_mac_out = mac_out[mac_sel];
    
    // 7-segment display instances
    wire [6:0] hex0_val, hex1_val, hex2_val, hex3_val, hex4_val, hex5_val;
    
    seg7_decoder seg0 (.hex_val(selected_mac_out[3:0]),   .seg(hex0_val));
    seg7_decoder seg1 (.hex_val(selected_mac_out[7:4]),   .seg(hex1_val));
    seg7_decoder seg2 (.hex_val(selected_mac_out[11:8]),  .seg(hex2_val));
    seg7_decoder seg3 (.hex_val(selected_mac_out[15:12]), .seg(hex3_val));
    seg7_decoder seg4 (.hex_val(selected_mac_out[19:16]), .seg(hex4_val));
    seg7_decoder seg5 (.hex_val(selected_mac_out[23:20]), .seg(hex5_val));
    
    // Display enable based on SW[9] and state
    assign HEX0 = (SW[9] && state == ST_DONE) ? hex0_val : 7'b1111111;
    assign HEX1 = (SW[9] && state == ST_DONE) ? hex1_val : 7'b1111111;
    assign HEX2 = (SW[9] && state == ST_DONE) ? hex2_val : 7'b1111111;
    assign HEX3 = (SW[9] && state == ST_DONE) ? hex3_val : 7'b1111111;
    assign HEX4 = (SW[9] && state == ST_DONE) ? hex4_val : 7'b1111111;
    assign HEX5 = (SW[9] && state == ST_DONE) ? hex5_val : 7'b1111111;
    
    //==========================================================================
    // LED Output
    //==========================================================================
    // LEDR[2:0] = current state
    // LEDR[5:3] = memory controller state
    // LEDR[6] = all FIFOs full
    // LEDR[7] = compute done
    // LEDR[8] = mem controller done
    // LEDR[9] = heartbeat (optional)
    
    assign LEDR[2:0] = state;
    assign LEDR[5:3] = mem_ctrl_state;
    assign LEDR[6] = all_fifos_full;
    assign LEDR[7] = compute_done;
    assign LEDR[8] = mem_ctrl_done;
    assign LEDR[9] = 1'b0;

endmodule
`default_nettype wire
