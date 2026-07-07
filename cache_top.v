`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 02:06:02
// Design Name: 
// Module Name: cache_top
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
module cache_top #

(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter INDEX_BITS = 4,
    parameter TAG_WIDTH  = 4
)

(

    //////////////////////////////////////////////////////
    // Clock & Reset
    //////////////////////////////////////////////////////

    input clk,
    input rst,

    //////////////////////////////////////////////////////
    // CPU Interface
    //////////////////////////////////////////////////////

    input cpu_rd,
    input cpu_wr,

    input [ADDR_WIDTH-1:0] cpu_addr,
    input [DATA_WIDTH-1:0] cpu_wdata,

    output [DATA_WIDTH-1:0] cpu_rdata,
    output ready

);

//////////////////////////////////////////////////////////
// Cache Memory Wires
//////////////////////////////////////////////////////////

wire cache_wr;
wire cache_allocate;

wire [DATA_WIDTH-1:0] cache_wdata;
wire [DATA_WIDTH-1:0] cache_alloc_data;

wire cache_alloc_dirty;

wire cache_hit;

wire [DATA_WIDTH-1:0] cache_rdata;

wire current_valid;
wire current_dirty;

wire [TAG_WIDTH-1:0] current_tag;
wire [DATA_WIDTH-1:0] current_data;

//////////////////////////////////////////////////////////
// Debug Wires
//////////////////////////////////////////////////////////

wire [DATA_WIDTH-1:0] debug_data;
wire                  debug_dirty;

//////////////////////////////////////////////////////////
// Main Memory Wires
//////////////////////////////////////////////////////////

wire mem_rd;
wire mem_wr;

wire [ADDR_WIDTH-1:0] mem_addr;
wire [DATA_WIDTH-1:0] mem_wdata;
wire [DATA_WIDTH-1:0] mem_rdata;

//////////////////////////////////////////////////////////
// Victim Cache Wires
//////////////////////////////////////////////////////////

wire victim_lookup;
wire victim_insert;

wire [ADDR_WIDTH-1:0] victim_lookup_addr;
wire [ADDR_WIDTH-1:0] victim_insert_addr;

wire [DATA_WIDTH-1:0] victim_insert_data;

wire victim_hit;
wire [DATA_WIDTH-1:0] victim_data;

//////////////////////////////////////////////////////////
// Controller -> Performance Monitor Wires
//////////////////////////////////////////////////////////

wire hit_event;
wire miss_event;
wire victim_hit_event;

wire read_event;
wire write_event;

wire memory_access_event;

//////////////////////////////////////////////////////////
// Performance Monitor Wires
//////////////////////////////////////////////////////////

wire [31:0] hit_count;
wire [31:0] miss_count;
wire [31:0] victim_hit_count;

wire [31:0] read_count;
wire [31:0] write_count;

wire [31:0] memory_access_count;

//////////////////////////////////////////////////////////
// Address Decoder
//////////////////////////////////////////////////////////

wire [INDEX_BITS-1:0] addr_index;
wire [TAG_WIDTH-1:0]  addr_tag;

assign addr_index = cpu_addr[INDEX_BITS-1:0];
assign addr_tag   = cpu_addr[ADDR_WIDTH-1:INDEX_BITS];

//////////////////////////////////////////////////////////
// Cache Controller
//////////////////////////////////////////////////////////

cache_controller #

(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .INDEX_BITS(INDEX_BITS),
    .TAG_WIDTH(TAG_WIDTH)
)

CONTROLLER
(

    .clk(clk),
    .rst(rst),

    //////////////////////////////////////////////////////
    // CPU
    //////////////////////////////////////////////////////

    .cpu_rd(cpu_rd),
    .cpu_wr(cpu_wr),

    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),

    .cpu_rdata(cpu_rdata),
    .ready(ready),

    //////////////////////////////////////////////////////
    // Cache
    //////////////////////////////////////////////////////

    .cache_wr(cache_wr),
    .cache_allocate(cache_allocate),

    .cache_wdata(cache_wdata),
    .cache_alloc_data(cache_alloc_data),

    .cache_alloc_dirty(cache_alloc_dirty),

    .cache_hit(cache_hit),

    .cache_rdata(cache_rdata),

    .current_valid(current_valid),
    .current_dirty(current_dirty),

    .current_tag(current_tag),
    .current_data(current_data),

    //////////////////////////////////////////////////////
    // Main Memory
    //////////////////////////////////////////////////////

    .mem_rd(mem_rd),
    .mem_wr(mem_wr),

    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),

    .mem_rdata(mem_rdata),

    //////////////////////////////////////////////////////
    // Victim Cache
    //////////////////////////////////////////////////////

    .victim_lookup(victim_lookup),
    .victim_insert(victim_insert),

    .victim_lookup_addr(victim_lookup_addr),
    .victim_insert_addr(victim_insert_addr),

    .victim_insert_data(victim_insert_data),

    .victim_hit(victim_hit),
    .victim_data(victim_data),

    //////////////////////////////////////////////////////
    // Performance Monitor
    //////////////////////////////////////////////////////

    .hit_event(hit_event),
    .miss_event(miss_event),

    .victim_hit_event(victim_hit_event),

    .read_event(read_event),
    .write_event(write_event),

    .memory_access_event(memory_access_event)

);
//////////////////////////////////////////////////////////
// Cache Memory
//////////////////////////////////////////////////////////

cache_memory #

(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .CACHE_LINES(16),
    .INDEX_BITS(INDEX_BITS),
    .TAG_WIDTH(TAG_WIDTH)
)

CACHE
(

    .clk(clk),
    .rst(rst),

    .wr(cache_wr),
    .allocate(cache_allocate),

    .index(addr_index),
    .tag(addr_tag),

    .wdata(cache_wdata),
    .alloc_data(cache_alloc_data),

    .alloc_dirty(cache_alloc_dirty),

    .hit(cache_hit),

    .rdata(cache_rdata),

    .current_valid(current_valid),
    .current_dirty(current_dirty),

    .current_tag(current_tag),
    .current_data(current_data),

    .debug_data(debug_data),
    .debug_dirty(debug_dirty)

);

//////////////////////////////////////////////////////////
// Main Memory
//////////////////////////////////////////////////////////

main_memory #

(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)

MEMORY
(

    .clk(clk),

    .mem_rd(mem_rd),
    .mem_wr(mem_wr),

    .addr(mem_addr),

    .wdata(mem_wdata),

    .rdata(mem_rdata)

);

//////////////////////////////////////////////////////////
// Victim Cache
//////////////////////////////////////////////////////////

victim_cache #

(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)

VICTIM
(

    .clk(clk),
    .rst(rst),

    .lookup_en(victim_lookup),
    .insert_en(victim_insert),

    .lookup_addr(victim_lookup_addr),
    .insert_addr(victim_insert_addr),

    .insert_data(victim_insert_data),

    .victim_hit(victim_hit),

    .victim_data_out(victim_data)

);

//////////////////////////////////////////////////////////
// Performance Monitor
//////////////////////////////////////////////////////////

performance_monitor #

(
    .COUNTER_WIDTH(32)
)

MONITOR
(

    .clk(clk),
    .rst(rst),

    .hit_event(hit_event),
    .miss_event(miss_event),

    .victim_hit_event(victim_hit_event),

    .read_event(read_event),
    .write_event(write_event),

    .memory_access_event(memory_access_event),

    .hit_count(hit_count),
    .miss_count(miss_count),

    .victim_hit_count(victim_hit_count),

    .read_count(read_count),
    .write_count(write_count),

    .memory_access_count(memory_access_count)

);

endmodule