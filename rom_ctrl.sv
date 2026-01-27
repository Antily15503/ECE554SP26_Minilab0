`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 10:25:44 PM
// Design Name: 
// Module Name: rom_ctrl
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

module rom_ctrl(
    input  logic i_clk,
    input  logic [7:0] i_addr,
    input  logic i_en,
    output logic [7:0] o_data
);

    logic [7:0] rom [7:0] = {
        8'h48,
        8'h67,
        8'h44,
        8'ha3,
        8'hbb,
        8'hde,
        8'had,
        8'h07
    };

    always_ff @(posedge i_clk) begin
        if (!i_en) begin
            o_data <= '0;
        end
        else begin
            case (i_addr)
                8'h01:   o_data <= rom[0];
                8'h02:   o_data <= rom[1];
                8'h04:   o_data <= rom[2];
                8'h08:   o_data <= rom[3];
                8'h10:   o_data <= rom[4];
                8'h20:   o_data <= rom[5];
                8'h40:   o_data <= rom[6];
                8'h80:   o_data <= rom[7];
                default: o_data <= 'x;
            endcase
        end
    end

endmodule
