`default_nettype none
module mat_vec_mult #(
    parameter DATA_WIDTH = 8,
    parameter NUM_MACS = 8,
    parameter FIFO_DEPTH = 8
)(
    input  wire                         clk,
    input  wire                         rst_n,
    
    // Control signals
    input  wire                         start_compute,
    input  wire                         clr_accum,
    
    // FIFO write interface for A matrix
    input  wire [DATA_WIDTH-1:0]        fifo_a_data [0:NUM_MACS-1],
    input  wire [NUM_MACS-1:0]          fifo_a_wren,
    output wire [NUM_MACS-1:0]          fifo_a_full,
    
    // FIFO write interface for B vector
    input  wire [DATA_WIDTH-1:0]        fifo_b_data,
    input  wire                         fifo_b_wren,
    output wire                         fifo_b_full,
    
    // Status
    output wire                         all_fifos_full,
    output wire                         compute_done,
    
    // MAC outputs (24 bits each)
    output wire [DATA_WIDTH*3-1:0]      mac_out [0:NUM_MACS-1]
);

    // Internal signals
    wire [DATA_WIDTH-1:0]   fifo_a_out [0:NUM_MACS-1];
    wire [NUM_MACS-1:0]     fifo_a_empty;
    wire [DATA_WIDTH-1:0]   fifo_b_out;
    wire                    fifo_b_empty;
    
    // Read enables
    reg  [NUM_MACS-1:0]     fifo_a_rden;
    reg                     fifo_b_rden;
    
    reg                     mac_en;
    
    wire [NUM_MACS-1:0]     mac_en_out_dummy;
    wire [DATA_WIDTH-1:0]   mac_b_out_dummy [0:NUM_MACS-1];
    
    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        START    = 3'd1,  // Start FIFO reads
        RUN      = 3'd2,  // MAC operations
        DONE_ST  = 3'd3
    } state_t;
    
    state_t state;
    reg [3:0] cnt;
    
    assign all_fifos_full = (&fifo_a_full) && fifo_b_full;
    assign compute_done = (state == DONE_ST);
    
    genvar i;
    generate
        for (i = 0; i < NUM_MACS; i = i + 1) begin : fifo_a_gen
            FIFO #(
                .DEPTH(FIFO_DEPTH),
                .DATA_WIDTH(DATA_WIDTH)
            ) fifo_a_inst (
                .clk(clk),
                .rst_n(rst_n),
                .rden(fifo_a_rden[i]),
                .wren(fifo_a_wren[i]),
                .i_data(fifo_a_data[i]),
                .o_data(fifo_a_out[i]),
                .full(fifo_a_full[i]),
                .empty(fifo_a_empty[i])
            );
        end
    endgenerate
    
    FIFO #(
        .DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo_b_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rden(fifo_b_rden),
        .wren(fifo_b_wren),
        .i_data(fifo_b_data),
        .o_data(fifo_b_out),
        .full(fifo_b_full),
        .empty(fifo_b_empty)
    );
    
    generate
        for (i = 0; i < NUM_MACS; i = i + 1) begin : mac_gen
            MAC #(
                .DATA_WIDTH(DATA_WIDTH)
            ) mac_inst (
                .clk(clk),
                .rst_n(rst_n),
                .En(mac_en),
                .Clr(clr_accum),
                .Ain(fifo_a_out[i]),
                .Bin(fifo_b_out),  // All MACs see same B value
                .Cout(mac_out[i]),
                .En_out(mac_en_out_dummy[i]),
                .Bout(mac_b_out_dummy[i])
            );
        end
    endgenerate
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt <= 4'd0;
            fifo_a_rden <= '0;
            fifo_b_rden <= 1'b0;
            mac_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    fifo_a_rden <= '0;
                    fifo_b_rden <= 1'b0;
                    mac_en <= 1'b0;
                    cnt <= 4'd0;
                    
                    if (start_compute && all_fifos_full) begin
                        state <= START;
                    end
                end
                
                START: begin
                    // Start reading all FIFOs
                    fifo_a_rden <= {NUM_MACS{1'b1}};
                    fifo_b_rden <= 1'b1;
                    state <= RUN;
                    cnt <= 4'd0;
                end
                
                RUN: begin
                    cnt <= cnt + 1;
                    
                    // Data valid 1 cycle after read
                    mac_en <= 1'b1;
                    
                    // Read for 8 cycles (0-7)
                    if (cnt < 4'd7) begin
                        fifo_a_rden <= {NUM_MACS{1'b1}};
                        fifo_b_rden <= 1'b1;
                    end else begin
                        fifo_a_rden <= '0;
                        fifo_b_rden <= 1'b0;
                    end
                    
                    // Done after 8 MAC operations
                    if (cnt == 4'd8) begin
                        mac_en <= 1'b0;
                        state <= DONE_ST;
                    end
                end
                
                DONE_ST: begin
                    fifo_a_rden <= '0;
                    fifo_b_rden <= 1'b0;
                    mac_en <= 1'b0;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
