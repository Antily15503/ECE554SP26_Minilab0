`default_nettype none
module mem_controller #(
    parameter DATA_WIDTH = 8,
    parameter NUM_MACS = 8,
    parameter FIFO_DEPTH = 8
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,          // Start data fetch
    
    // Avalon MM Master Interface
    output reg  [31:0]                  avm_address,
    output reg                          avm_read,
    input  wire [63:0]                  avm_readdata,
    input  wire                         avm_readdatavalid,
    input  wire                         avm_waitrequest,
    
    // FIFO write interface for A matrix (8 FIFOs, one per row/MAC)
    output reg  [DATA_WIDTH-1:0]        fifo_a_data [0:NUM_MACS-1],
    output reg  [NUM_MACS-1:0]          fifo_a_wren,
    input  wire [NUM_MACS-1:0]          fifo_a_full,
    
    // FIFO write interface for B vector (1 FIFO)
    output reg  [DATA_WIDTH-1:0]        fifo_b_data,
    output reg                          fifo_b_wren,
    input  wire                         fifo_b_full,
    
    // Status outputs
    output reg                          done,           // All FIFOs filled
    output reg  [2:0]                   state_out       // Current state for debug
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE        = 3'd0,
        FETCH_A     = 3'd1,
        WAIT_A      = 3'd2,
        WRITE_A     = 3'd3,
        FETCH_B     = 3'd4,
        WAIT_B      = 3'd5,
        WRITE_B     = 3'd6,
        DONE_STATE  = 3'd7
    } state_t;
    
    state_t state, next_state;
    
    // Counters
    reg [3:0] row_cnt;              // Which row of A (0-7)
    reg [3:0] col_cnt;              // Which column/byte in row (0-7)
    reg [63:0] row_data;            // Latched row data from memory
    

    assign state_out = state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = FETCH_A;
            end
            
            FETCH_A: begin
                // Stay in FETCH_A until waitrequest is deasserted
                if (!avm_waitrequest)
                    next_state = WAIT_A;
            end
            
            WAIT_A: begin
                if (avm_readdatavalid)
                    next_state = WRITE_A;
            end
            
            WRITE_A: begin
                // Write 8 bytes to FIFO row_cnt, one byte per cycle
                if (col_cnt == 4'd7) begin
                    if (row_cnt == 4'd7)
                        next_state = FETCH_B;  // All A rows done, fetch B
                    else
                        next_state = FETCH_A;  // Fetch next row
                end
            end
            
            FETCH_B: begin
                if (!avm_waitrequest)
                    next_state = WAIT_B;
            end
            
            WAIT_B: begin
                if (avm_readdatavalid)
                    next_state = WRITE_B;
            end
            
            WRITE_B: begin
                if (col_cnt == 4'd7)
                    next_state = DONE_STATE;
            end
            
            DONE_STATE: begin
                // Stay in done state
                next_state = DONE_STATE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Datapath logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            avm_address <= 32'd0;
            avm_read <= 1'b0;
            row_cnt <= 4'd0;
            col_cnt <= 4'd0;
            row_data <= 64'd0;
            done <= 1'b0;
            fifo_a_wren <= '0;
            fifo_b_wren <= 1'b0;
            fifo_b_data <= '0;
            for (int i = 0; i < NUM_MACS; i++) begin
                fifo_a_data[i] <= '0;
            end
        end else begin
            // Default values
            avm_read <= 1'b0;
            fifo_a_wren <= '0;
            fifo_b_wren <= 1'b0;
            
            case (state)
                IDLE: begin
                    row_cnt <= 4'd0;
                    col_cnt <= 4'd0;
                    done <= 1'b0;
                    if (start) begin
                        avm_address <= 32'd0;  // Start with row 0
                        avm_read <= 1'b1;
                    end
                end
                
                FETCH_A: begin
                    avm_address <= {28'd0, row_cnt};  // Address 0-7 for rows
                    avm_read <= 1'b1;
                end
                
                WAIT_A: begin
                    if (avm_readdatavalid) begin
                        row_data <= avm_readdata;
                        col_cnt <= 4'd0;
                    end
                end
                
                WRITE_A: begin
                    fifo_a_data[row_cnt] <= row_data[(7-col_cnt)*8 +: 8];
                    fifo_a_wren[row_cnt] <= 1'b1;
                    
                    if (col_cnt == 4'd7) begin
                        col_cnt <= 4'd0;
                        if (row_cnt < 4'd7) begin
                            row_cnt <= row_cnt + 1;
                        end
                    end else begin
                        col_cnt <= col_cnt + 1;
                    end
                end
                
                FETCH_B: begin
                    avm_address <= 32'd8;  // Address 8 for B vector
                    avm_read <= 1'b1;
                    col_cnt <= 4'd0;
                end
                
                WAIT_B: begin
                    if (avm_readdatavalid) begin
                        row_data <= avm_readdata;
                        col_cnt <= 4'd0;
                    end
                end
                
                WRITE_B: begin
                    fifo_b_data <= row_data[(7-col_cnt)*8 +: 8];
                    fifo_b_wren <= 1'b1;
                    col_cnt <= col_cnt + 1;
                end
                
                DONE_STATE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule
`default_nettype wire
