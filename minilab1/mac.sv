`default_nettype none
module MAC #(
    parameter DATA_WIDTH = 8
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      En,         // Enable signal (propagates with 1 cycle delay)
    input  wire                      Clr,        // Clear accumulated result
    input  wire [DATA_WIDTH-1:0]     Ain,        // A input from FIFO
    input  wire [DATA_WIDTH-1:0]     Bin,        // B input (propagates through MAC chain)
    output reg  [DATA_WIDTH*3-1:0]   Cout,       // 24-bit accumulated output
    output reg                       En_out,     // Delayed enable for next MAC
    output reg  [DATA_WIDTH-1:0]     Bout        // Delayed B for next MAC
);

    logic [DATA_WIDTH*2-1:0] mult_result;
    assign mult_result = Ain * Bin;
    
    logic [DATA_WIDTH*3-1:0] add_result;
    assign add_result = {{(DATA_WIDTH){1'b0}}, mult_result} + Cout;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Cout <= '0;
        else if (Clr)
            Cout <= '0;
        else if (En)
            Cout <= add_result;
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            En_out <= 1'b0;
            Bout <= '0;
        end else begin
            En_out <= En;
            Bout <= Bin;
        end
    end

endmodule
`default_nettype wire
