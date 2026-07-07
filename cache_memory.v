`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 23:02:19
// Design Name: 
// Module Name: cache_memory
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

module cache_memory #

(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 8,
    parameter CACHE_LINES = 16,

    parameter INDEX_BITS  = 4,
    parameter TAG_WIDTH   = 4
)

(
    input clk,
    input rst,

    //////////////////////////////////////////////////////
    // Control Signals
    //////////////////////////////////////////////////////

    input wr,
    input allocate,

    //////////////////////////////////////////////////////
    // Address
    //////////////////////////////////////////////////////

    input [INDEX_BITS-1:0] index,
    input [TAG_WIDTH-1:0]  tag,

    //////////////////////////////////////////////////////
    // Data Inputs
    //////////////////////////////////////////////////////

    input [DATA_WIDTH-1:0] wdata,
    input [DATA_WIDTH-1:0] alloc_data,

    input alloc_dirty,

    //////////////////////////////////////////////////////
    // Cache Read Outputs
    //////////////////////////////////////////////////////

    output hit,
    output [DATA_WIDTH-1:0] rdata,

    //////////////////////////////////////////////////////
    // Current Cache Line Information
    //////////////////////////////////////////////////////

    output current_valid,
    output current_dirty,

    output [TAG_WIDTH-1:0] current_tag,
    output [DATA_WIDTH-1:0] current_data,

    //////////////////////////////////////////////////////
    // Debug Outputs
    //////////////////////////////////////////////////////

    output [DATA_WIDTH-1:0] debug_data,
    output                  debug_dirty

);

//////////////////////////////////////////////////////////
// Cache Arrays
//////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] data_mem [0:CACHE_LINES-1];

reg [TAG_WIDTH-1:0] tag_mem [0:CACHE_LINES-1];

reg valid_mem [0:CACHE_LINES-1];

reg dirty_mem [0:CACHE_LINES-1];

integer i;

//////////////////////////////////////////////////////////
// Combinational Read Logic
//////////////////////////////////////////////////////////

assign rdata = data_mem[index];

assign current_data  = data_mem[index];
assign current_tag   = tag_mem[index];
assign current_valid = valid_mem[index];
assign current_dirty = dirty_mem[index];

//////////////////////////////////////////////////////////
// Debug Signals
//////////////////////////////////////////////////////////

assign debug_data  = data_mem[index];
assign debug_dirty = dirty_mem[index];

//////////////////////////////////////////////////////////
// Hit Logic
//////////////////////////////////////////////////////////

assign hit = current_valid &&
             (current_tag == tag);

//////////////////////////////////////////////////////////
// Sequential Logic
//////////////////////////////////////////////////////////

always @(posedge clk)
begin

    if(rst)
    begin

        for(i=0;i<CACHE_LINES;i=i+1)
        begin
            data_mem[i]  <= 0;
            tag_mem[i]   <= 0;
            valid_mem[i] <= 0;
            dirty_mem[i] <= 0;
        end

    end

    else
    begin

        /////////////////////////////////////////////////
        // Allocate New Cache Line
        /////////////////////////////////////////////////

        if(allocate)
        begin

            data_mem[index]  <= alloc_data;
            tag_mem[index]   <= tag;
            valid_mem[index] <= 1'b1;
            dirty_mem[index] <= alloc_dirty;

        end

        /////////////////////////////////////////////////
        // CPU Write
        /////////////////////////////////////////////////

        else if(wr)
        begin
         $display("WRITE: time=%0t wr=%b index=%0d data=%0d",
                    $time, wr, index, wdata);
$display("After Write data_mem[%0d]=%0d", index, data_mem[index]);

            data_mem[index]  <= wdata;
            dirty_mem[index] <= 1'b1;

        end

    end

end

endmodule