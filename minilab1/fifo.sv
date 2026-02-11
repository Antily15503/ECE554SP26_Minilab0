`default_nettype none
module FIFO #(
    parameter DEPTH = 8,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   rden,       // Read enable
    input  wire                   wren,       // Write enable
    input  wire [DATA_WIDTH-1:0]  i_data,     // Input data
    output reg  [DATA_WIDTH-1:0]  o_data,     // Output data
    output wire                   full,       // FIFO full flag
    output wire                   empty       // FIFO empty flag
);

    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    
    reg [$clog2(DEPTH):0] read_ptr;
    reg [$clog2(DEPTH):0] write_ptr;
    
    assign empty = (read_ptr == write_ptr);
    assign full = (read_ptr[$clog2(DEPTH)-1:0] == write_ptr[$clog2(DEPTH)-1:0]) && 
                  (read_ptr[$clog2(DEPTH)] != write_ptr[$clog2(DEPTH)]);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= '0;
        end else if (wren && !full) begin
            fifo_mem[write_ptr[$clog2(DEPTH)-1:0]] <= i_data;
            write_ptr <= write_ptr + 1;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= '0;
            o_data <= '0;
        end else if (rden && !empty) begin
            o_data <= fifo_mem[read_ptr[$clog2(DEPTH)-1:0]];
            read_ptr <= read_ptr + 1;
        end
    end

endmodule
`default_nettype wire
