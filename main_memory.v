`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 02:59:32
// Design Name: 
// Module Name: main_memory
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


module main_memory #

(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)

(
    input clk,

    input mem_rd,
    input mem_wr,

    input  [ADDR_WIDTH-1:0] addr,
    input  [DATA_WIDTH-1:0] wdata,

    output reg [DATA_WIDTH-1:0] rdata
);

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

integer i;

initial
begin
    for(i=0;i<(1<<ADDR_WIDTH);i=i+1)
        mem[i] = i;
end

always @(posedge clk)
begin

    if(mem_wr)
        mem[addr] <= wdata;

    if(mem_rd)
        rdata <= mem[addr];

end

endmodule