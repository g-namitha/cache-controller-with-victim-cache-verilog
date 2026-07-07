`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 02:32:43
// Design Name: 
// Module Name: perfomance_monitor
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


module performance_monitor #

(
    parameter COUNTER_WIDTH = 32
)

(
    input clk,
    input rst,

    input hit_event,
    input miss_event,

    input victim_hit_event,

    input read_event,
    input write_event,

    input memory_access_event,

    output reg [COUNTER_WIDTH-1:0] hit_count,

    output reg [COUNTER_WIDTH-1:0] miss_count,

    output reg [COUNTER_WIDTH-1:0] victim_hit_count,

    output reg [COUNTER_WIDTH-1:0] read_count,

    output reg [COUNTER_WIDTH-1:0] write_count,

    output reg [COUNTER_WIDTH-1:0] memory_access_count
);

always @(posedge clk)
begin

    if(rst)
    begin

        hit_count           <= 0;
        miss_count          <= 0;
        victim_hit_count    <= 0;

        read_count          <= 0;
        write_count         <= 0;

        memory_access_count <= 0;

    end

    else
    begin

        if(hit_event)
            hit_count <= hit_count + 1;

        if(miss_event)
            miss_count <= miss_count + 1;

        if(victim_hit_event)
            victim_hit_count <= victim_hit_count + 1;

        if(read_event)
            read_count <= read_count + 1;

        if(write_event)
            write_count <= write_count + 1;

        if(memory_access_event)
            memory_access_count <= memory_access_count + 1;

    end

end

endmodule