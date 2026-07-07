`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 03:40:51
// Design Name: 
// Module Name: victim_cache
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


module victim_cache #

(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 8,
    parameter VICTIM_LINES = 4
)

(
    input clk,
    input rst,

    input lookup_en,
    input insert_en,

    input [ADDR_WIDTH-1:0] lookup_addr,

    input [ADDR_WIDTH-1:0] insert_addr,
    input [DATA_WIDTH-1:0] insert_data,

    output reg victim_hit,

    output reg [DATA_WIDTH-1:0] victim_data_out
);

reg [DATA_WIDTH-1:0]
    victim_data [0:VICTIM_LINES-1];

reg [ADDR_WIDTH-1:0]
    victim_addr [0:VICTIM_LINES-1];

reg victim_valid [0:VICTIM_LINES-1];

reg [1:0] victim_ptr;

integer i;
integer j;

always @(posedge clk)
begin

    if(rst)
    begin

        for(i=0;i<VICTIM_LINES;i=i+1)
        begin
            victim_valid[i] <= 0;
            victim_addr[i]  <= 0;
            victim_data[i]  <= 0;
        end

        victim_ptr <= 0;

    end

    else if(insert_en)
    begin

        victim_addr[victim_ptr]
            <= insert_addr;

        victim_data[victim_ptr]
            <= insert_data;

        victim_valid[victim_ptr]
            <= 1'b1;

        victim_ptr <= victim_ptr + 1;

    end

end

always @(*)
begin

    victim_hit      = 0;
    victim_data_out = 0;

    if(lookup_en)
    begin

        for(j=0;j<VICTIM_LINES;j=j+1)
        begin

            if(victim_valid[j] &&
               victim_addr[j] == lookup_addr)
            begin

                victim_hit      = 1;
                victim_data_out = victim_data[j];
            end

        end

    end

end

endmodule