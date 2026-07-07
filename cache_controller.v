`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 02:59:03
// Design Name: 
// Module Name: cache_controller
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
module cache_controller #

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

    input  [ADDR_WIDTH-1:0] cpu_addr,
    input  [DATA_WIDTH-1:0] cpu_wdata,

    output reg [DATA_WIDTH-1:0] cpu_rdata,
    output reg ready,

    //////////////////////////////////////////////////////
    // Cache Memory Interface
    //////////////////////////////////////////////////////

    output reg cache_wr,
    output reg cache_allocate,

    output reg [DATA_WIDTH-1:0] cache_wdata,
    output reg [DATA_WIDTH-1:0] cache_alloc_data,

    output reg cache_alloc_dirty,

    input cache_hit,

    input [DATA_WIDTH-1:0] cache_rdata,

    input current_valid,
    input current_dirty,

    input [TAG_WIDTH-1:0] current_tag,
    input [DATA_WIDTH-1:0] current_data,

    //////////////////////////////////////////////////////
    // Main Memory Interface
    //////////////////////////////////////////////////////

    output reg mem_rd,
    output reg mem_wr,

    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_wdata,

    input [DATA_WIDTH-1:0] mem_rdata,

    //////////////////////////////////////////////////////
    // Victim Cache Interface
    //////////////////////////////////////////////////////

    output reg victim_lookup,
    output reg victim_insert,

    output reg [ADDR_WIDTH-1:0] victim_lookup_addr,
    output reg [ADDR_WIDTH-1:0] victim_insert_addr,

    output reg [DATA_WIDTH-1:0] victim_insert_data,

    input victim_hit,
    input [DATA_WIDTH-1:0] victim_data,

    //////////////////////////////////////////////////////
    // Performance Monitor
    //////////////////////////////////////////////////////

    output reg hit_event,
    output reg miss_event,
    output reg victim_hit_event,

    output reg read_event,
    output reg write_event,

    output reg memory_access_event

);
//////////////////////////////////////////////////////////
// Address Decoder
//////////////////////////////////////////////////////////

wire [INDEX_BITS-1:0] addr_index;
wire [TAG_WIDTH-1:0]  addr_tag;

assign addr_index = req_addr[INDEX_BITS-1:0];

assign addr_tag = req_addr[ADDR_WIDTH-1:INDEX_BITS];
//////////////////////////////////////////////////////////
// FSM States
//////////////////////////////////////////////////////////

localparam IDLE         = 4'd0;
localparam LOOKUP       = 4'd1;
localparam WRITE_HIT    = 4'd2;
localparam VICTIM_CHECK = 4'd3;
localparam WRITE_BACK   = 4'd4;
localparam MEM_READ     = 4'd5;
localparam MEM_WAIT     = 4'd6;
localparam ALLOCATE     = 4'd7;
localparam DONE         = 4'd8;
//////////////////////////////////////////////////////////
// State Registers
//////////////////////////////////////////////////////////

reg [3:0] present_state;
reg [3:0] next_state;

//////////////////////////////////////////////////////////
// Latched CPU Request
//////////////////////////////////////////////////////////

reg req_rd;
reg req_wr;

reg [ADDR_WIDTH-1:0] req_addr;
reg [DATA_WIDTH-1:0] req_wdata;
always @(posedge clk)
begin

    if(rst)
    begin

        present_state <= IDLE;

        req_rd <= 1'b0;
        req_wr <= 1'b0;

        req_addr <= {ADDR_WIDTH{1'b0}};
        req_wdata <= {DATA_WIDTH{1'b0}};

    end

    else
    begin

        present_state <= next_state;

        ////////////////////////////////////////////////////
        // Latch CPU Request only in IDLE
        ////////////////////////////////////////////////////

        if(present_state == IDLE)
        begin

            if(cpu_rd || cpu_wr)
            begin

                req_rd <= cpu_rd;
                req_wr <= cpu_wr;

                req_addr <= cpu_addr;
                req_wdata <= cpu_wdata;

            end

        end

    end

end

//////////////////////////////////////////////////////////
// Next State Logic
//////////////////////////////////////////////////////////

always @(*)
begin

    //----------------------------------------------------
    // Default
    //----------------------------------------------------

    next_state = present_state;

    case(present_state)

    //////////////////////////////////////////////////////
    // IDLE
    //////////////////////////////////////////////////////

    IDLE:
    begin

        if(cpu_rd || cpu_wr)
            next_state = LOOKUP;
        else
            next_state = IDLE;

    end

    //////////////////////////////////////////////////////
    // LOOKUP
    //////////////////////////////////////////////////////

    LOOKUP:
    begin

        if(cache_hit)
        begin

           if(req_wr)
            next_state = WRITE_HIT;
            else
                next_state = DONE;

        end

        else
        begin

            next_state = VICTIM_CHECK;

        end

    end

    //////////////////////////////////////////////////////
    // WRITE HIT
    //////////////////////////////////////////////////////

    WRITE_HIT:
    begin

        next_state = DONE;

    end

    //////////////////////////////////////////////////////
    // VICTIM CHECK
    //////////////////////////////////////////////////////

    VICTIM_CHECK:
    begin

        //------------------------------------------------
        // Victim Cache Hit
        //------------------------------------------------

        if(victim_hit)
        begin

            next_state = DONE;

        end

        //------------------------------------------------
        // Victim Cache Miss
        //------------------------------------------------

        else
        begin

            //------------------------------------------------
            // Dirty Cache Line
            //------------------------------------------------

            if(current_valid && current_dirty)

                next_state = WRITE_BACK;

            //------------------------------------------------
            // Clean Cache Line
            //------------------------------------------------

            else

                next_state = MEM_READ;

        end

    end

    //////////////////////////////////////////////////////
    // WRITE BACK
    //////////////////////////////////////////////////////

    WRITE_BACK:
    begin

        next_state = MEM_READ;

    end

    //////////////////////////////////////////////////////
    // MEMORY READ REQUEST
    //////////////////////////////////////////////////////

    MEM_READ:
    begin

        //------------------------------------------------
        // Memory receives read request
        //------------------------------------------------

        next_state = MEM_WAIT;

    end

    //////////////////////////////////////////////////////
    // MEMORY WAIT
    //////////////////////////////////////////////////////

    MEM_WAIT:
    begin

        //------------------------------------------------
        // Wait one clock for synchronous memory
        //------------------------------------------------

        next_state = ALLOCATE;

    end

    //////////////////////////////////////////////////////
    // ALLOCATE
    //////////////////////////////////////////////////////

    ALLOCATE:
    begin

        next_state = DONE;

    end

    //////////////////////////////////////////////////////
    // DONE
    //////////////////////////////////////////////////////

    DONE:
    begin

        next_state = IDLE;

    end

    //////////////////////////////////////////////////////
    // DEFAULT
    //////////////////////////////////////////////////////

    default:
    begin

        next_state = IDLE;

    end

    endcase

end
//////////////////////////////////////////////////////////
// Output Logic
//////////////////////////////////////////////////////////

always @(*)
begin

    //////////////////////////////////////////////////////
    // Default Outputs
    //////////////////////////////////////////////////////

    ready = 1'b0;
    

    //----------------------------------------------------
    // Cache Memory
    //----------------------------------------------------

    cache_wr = 1'b0;
    cache_allocate = 1'b0;

    cache_wdata = {DATA_WIDTH{1'b0}};
    cache_alloc_data = {DATA_WIDTH{1'b0}};
    cache_alloc_dirty = 1'b0;

    //----------------------------------------------------
    // Main Memory
    //----------------------------------------------------

    mem_rd = 1'b0;
    mem_wr = 1'b0;

    mem_addr = req_addr;
    mem_wdata = {DATA_WIDTH{1'b0}};

    //----------------------------------------------------
    // Victim Cache
    //----------------------------------------------------

    victim_lookup = 1'b0;
    victim_insert = 1'b0;

    victim_lookup_addr = req_addr;
    victim_insert_addr = {ADDR_WIDTH{1'b0}};
    victim_insert_data = {DATA_WIDTH{1'b0}};

    //----------------------------------------------------
    // Performance Monitor
    //----------------------------------------------------

    hit_event = 1'b0;
    miss_event = 1'b0;

    victim_hit_event = 1'b0;

    read_event = 1'b0;
    write_event = 1'b0;

    memory_access_event = 1'b0;

    //////////////////////////////////////////////////////
    // FSM Outputs
    //////////////////////////////////////////////////////

    case(present_state)

    //////////////////////////////////////////////////////
    // IDLE
    //////////////////////////////////////////////////////

    IDLE:
    begin

        ready = 1'b1;

    end

    //////////////////////////////////////////////////////
    // LOOKUP
    //////////////////////////////////////////////////////

    LOOKUP:
    begin

        if(cache_hit)
        begin

            hit_event = 1'b1;

            if(req_rd)
            begin
            
                read_event = 1'b1;
            
                cpu_rdata = cache_rdata;
            
            end
            
            else if(req_wr)
            begin
            
                write_event = 1'b1;
            
            end
        end
        else
        begin

            miss_event = 1'b1;

        end

    end

    //////////////////////////////////////////////////////
    // WRITE HIT
    //////////////////////////////////////////////////////

    WRITE_HIT:
begin

    /////////////////////////////////////////////
    // Perform Cache Write
    /////////////////////////////////////////////

    cache_wr = 1'b1;

    cache_wdata = req_wdata;

    /////////////////////////////////////////////
    // Performance Monitor
    /////////////////////////////////////////////

    write_event = 1'b1;

end

    //////////////////////////////////////////////////////
    // VICTIM CHECK
    //////////////////////////////////////////////////////

    VICTIM_CHECK:
    begin

        victim_lookup = 1'b1;

        victim_lookup_addr = req_addr;

        if(victim_hit)
        begin

            victim_hit_event = 1'b1;

            cpu_rdata = victim_data;

        end

    end

    //////////////////////////////////////////////////////
    // WRITE BACK
    //////////////////////////////////////////////////////

    WRITE_BACK:
    begin

        mem_wr = 1'b1;

        memory_access_event = 1'b1;

        mem_addr = {current_tag, addr_index};

        mem_wdata = current_data;

    end

    //////////////////////////////////////////////////////
    // MEMORY READ
    //////////////////////////////////////////////////////

    MEM_READ:
    begin

        mem_rd = 1'b1;

        memory_access_event = 1'b1;

        mem_addr = req_addr;

    end

    //////////////////////////////////////////////////////
    // MEMORY WAIT
    //////////////////////////////////////////////////////

    MEM_WAIT:
begin

    /////////////////////////////////////////////
    // Keep Memory Read Active
    /////////////////////////////////////////////

    mem_rd = 1'b1;

    mem_addr = req_addr;

    memory_access_event = 1'b1;

end

    //////////////////////////////////////////////////////
    // ALLOCATE
    //////////////////////////////////////////////////////

    ALLOCATE:
    begin
    
        /////////////////////////////////////////////
        // Save Evicted Cache Line
        /////////////////////////////////////////////
    
        if(current_valid)
        begin
    
            victim_insert = 1'b1;
    
            victim_insert_addr = {current_tag,addr_index};
    
            victim_insert_data = current_data;
    
        end
    
        /////////////////////////////////////////////
        // Allocate New Cache Line
        /////////////////////////////////////////////
    
        cache_allocate = 1'b1;
    
        cache_alloc_data = mem_rdata;
    
        cache_alloc_dirty = 1'b0;
    
    end
    //////////////////////////////////////////////////////
    // DONE
    //////////////////////////////////////////////////////
 DONE:
begin

    /////////////////////////////////////////////
    // Transaction Complete
    /////////////////////////////////////////////

    ready = 1'b1;

    

end

    //////////////////////////////////////////////////////
    // DEFAULT
    //////////////////////////////////////////////////////

    default:
    begin

        ready = 1'b1;

    end

    endcase

end

endmodule