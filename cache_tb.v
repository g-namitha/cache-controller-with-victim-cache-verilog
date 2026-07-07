`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.07.2026 22:00:24
// Design Name: 
// Module Name: cache_tb
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
module cache_system_tb;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;

reg clk;
reg rst;

reg cpu_rd;
reg cpu_wr;

reg [ADDR_WIDTH-1:0] cpu_addr;
reg [DATA_WIDTH-1:0] cpu_wdata;

wire [DATA_WIDTH-1:0] cpu_rdata;
wire ready;

//////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////

cache_top DUT
(
    .clk(clk),
    .rst(rst),

    .cpu_rd(cpu_rd),
    .cpu_wr(cpu_wr),

    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),

    .cpu_rdata(cpu_rdata),

    .ready(ready)
);

//////////////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////////////

always #5 clk = ~clk;

//////////////////////////////////////////////////////////
// Monitor
//////////////////////////////////////////////////////////

initial
begin
    $monitor("T=%0t Ready=%b RD=%b WR=%b Addr=%h WData=%0d RData=%0d",
             $time, ready, cpu_rd, cpu_wr,
             cpu_addr, cpu_wdata, cpu_rdata);
end

//////////////////////////////////////////////////////////
// CPU READ TASK
//////////////////////////////////////////////////////////

task cpu_read;

input [7:0] addr;

begin

    @(posedge clk);

    cpu_addr = addr;
    cpu_rd   = 1'b1;

    wait(ready==0);
    wait(ready==1);

    @(posedge clk);

    cpu_rd = 1'b0;

    @(posedge clk);

end

endtask

//////////////////////////////////////////////////////////
// CPU WRITE TASK
//////////////////////////////////////////////////////////

task cpu_write;

input [7:0] addr;
input [31:0] data;

begin

    @(posedge clk);

    cpu_addr  = addr;
    cpu_wdata = data;
    cpu_wr    = 1'b1;

    wait(ready==0);
    wait(ready==1);

    @(posedge clk);

    cpu_wr = 1'b0;

    @(posedge clk);

end

endtask

//////////////////////////////////////////////////////////
// Test Sequence
//////////////////////////////////////////////////////////

initial
begin

    clk = 0;

    rst = 1;

    cpu_rd = 0;
    cpu_wr = 0;

    cpu_addr = 0;
    cpu_wdata = 0;

    repeat(3) @(posedge clk);

    rst = 0;

    //////////////////////////////////////////////////////
    // TEST 1
    //////////////////////////////////////////////////////

    $display("\n===== TEST 1 : FIRST READ (MISS) =====");

    cpu_read(8'hA5);

    $display("Read Data = %0d",cpu_rdata);

    //////////////////////////////////////////////////////
    // TEST 2
    //////////////////////////////////////////////////////

    $display("\n===== TEST 2 : READ HIT =====");

    cpu_read(8'hA5);

    $display("Read Data = %0d",cpu_rdata);

    //////////////////////////////////////////////////////
    // TEST 3
    //////////////////////////////////////////////////////

    $display("\n===== TEST 3 : WRITE HIT =====");

    cpu_write(8'hA5,32'd999);

    //////////////////////////////////////////////////////
    // TEST 4
    //////////////////////////////////////////////////////

    $display("\n===== TEST 4 : VERIFY WRITE =====");

    cpu_read(8'hA5);

    $display("Read Data = %0d",cpu_rdata);

    //////////////////////////////////////////////////////
    // TEST 5
    //////////////////////////////////////////////////////

    $display("\n===== TEST 5 : CACHE REPLACEMENT =====");

    cpu_read(8'hB5);

    $display("Read Data = %0d",cpu_rdata);

    //////////////////////////////////////////////////////
    // TEST 6
    //////////////////////////////////////////////////////

    $display("\n===== TEST 6 : VICTIM CACHE LOOKUP =====");

    cpu_read(8'hA5);

    $display("Read Data = %0d",cpu_rdata);

    #50;

    $display("\n===== SIMULATION FINISHED =====");

    $finish;

end

endmodule