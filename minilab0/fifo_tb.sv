`timescale 1ps/1ps

module testbench_fifo();

    logic clk;
    logic rst_n;
    logic rden;
    logic wren;
    logic [DATA_WIDTH-1:0] i_data;
    logic [DATA_WIDTH-1:0] o_data;
    logic full;
    logic empty;

    FIF0 #(.DEPTH(4), .DATA_WIDTH(16)) DUT(.clk(clk),
                                 .rst_n(rst_n),
                                 .rden(rden),
                                 .wren(wren),
                                 .i_data(i_data),
                                 .o_data(o_data),
                                 .full(full),
                                 .empty(empty)
                                );


    inital begin
        clk = 0;
        forever clk = ~clk; // 10 time units clock period

        wren = 1;
        i_data = 8'hA5;
        @(posedge clk);

        wren = 0;
        rden = 1;   
        @(negedge clk); // possible a delay here for data to be valid

        if (o_data !== 8'hA5) begin
            $display("Test Failed: Expected 0xA5, got %h", o_data);
        end
        rden = 1;
        @(negedge clk);

        if(o_data !== 8'hxx) begin // FIFO is empty, expect undefined, but could be different based on implementation
            $display("Test Failed: Expected 0x00 on empty read, got %h", o_data);
        end
        rden = 0;
        wren = 1;
        i_data = 8'h3C;
        @(posedge clk);

        wren = 1;
        i_data = 8'h7E;
        @(posedge clk);
        @(posedge clk); // 3 clocks to fill FIFO
        @(posedge clk);

        @(negedge clk); 
        if(!full) begin
            $display("Test Failed: FIFO should be full");
        end

        rden = 1;
        wren = 0;
        @(negedge clk);
        if (o_data !== 8'h3C) begin
            $display("Test Failed: Expected 0x3C, got %h", o_data);
        end
        @(negedge clk);
        if (o_data !== 8'h7E) begin
            $display("Test Failed: Expected 0x7E, got %h", o_data);
        end
        @(negedge clk);
        @(negedge clk);
        @ (negedge clk);
        if(!empty) begin
            $display("Test Failed: FIFO should be empty");
        end





    end

endmodule