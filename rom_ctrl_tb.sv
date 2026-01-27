`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 10:41:00 PM
// Design Name: 
// Module Name: rom_ctrl_t
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module rom_ctrl_tb();

    logic [7:0] i_addr, o_data;
    logic i_clk, i_en;

    rom_ctrl DUT(.*);
    
    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = ~i_clk;
    end

    initial begin
        @(negedge i_clk);
        i_en = 1'b0;
        @(posedge i_clk);
        @(negedge i_clk);
        assert(o_data == '0) else $error("Data is nonzero when enable is low!");

        i_en = 1'b1;
        for (int i = 0; i < 8; i++) begin
            @(negedge i_clk);
            i_addr = 8'h01 << i;
            @(posedge i_clk);
            
            @(negedge i_clk);
            assert (o_data == rom_ctrl.rom[i]) else $error("o_data=%x while rom[%d]=%x", o_data, i,
                rom_ctrl.rom[i]);
        end

        $display("YAHOO!!!");
        $stop();
    end

endmodule
