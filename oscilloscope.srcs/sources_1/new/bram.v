`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2019 20:36:07
// Design Name: 
// Module Name: bram
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


module bram(
        input               clk,
        input               rstn,
        input               data,
        input               dataClk,
        input               received,
        output      [7:0]   dataOut,
        output              dataReady,
        output              full,
        output              empty
    );
    
    localparam [2:0]
        ST_DATAIN   = 3'd0,
        ST_FULL     = 3'd1,
        ST_DATAOUT  = 3'd2,
        ST_WAITREC  = 3'd3,
        ST_EMPTY    = 3'd4;
        
    localparam [14:0]
        BRAMMAXADDR = {15{1'b1}};
        
    reg [2:0]
        state,
        nextState;
    
    wire
        bramWriteEnable,
        bramOutRegCkEn;
        
    reg
        dataBuffer,
        dataClkEdge,
        dataClkPrev;
        
    reg [14:0]
        bramAddr;
        
    reg [3:0]
        bramAddrInc;
        
    wire [7:0]
        dataOutI;
        
//  Address counter:
    always @(posedge clk) begin
        if (~rstn) begin
            bramAddr <= 15'd0;
        end
        else begin
            bramAddr <= bramAddr + bramAddrInc;
        end
    end
    
//  Next state logic:
    always @(*) begin
        if (~rstn) begin
            nextState <= ST_DATAIN;
        end
        else begin
            case (state)
                ST_DATAIN: begin
                    if ((bramAddr == BRAMMAXADDR) && (dataClkEdge)) begin
                        nextState <= ST_FULL;
                    end
                    else begin
                        nextState <= ST_DATAIN;
                    end
                end
                ST_FULL: begin
                    nextState <= ST_DATAOUT;
                end
                ST_DATAOUT: begin
                    nextState <= ST_WAITREC;
                end
                ST_WAITREC: begin
                    if (received) begin
                        if (bramAddr == BRAMMAXADDR-7) begin
                            nextState <= ST_EMPTY;
                        end
                        else begin
                            nextState <= ST_DATAOUT;
                        end
                    end
                    else begin
                        nextState <= ST_WAITREC;
                    end
                end
                ST_EMPTY: begin
                    nextState <= ST_DATAIN;
                end
                default: begin
                    nextState <= ST_DATAIN;
                end
            endcase
        end
    end
    
//  State update:
    always @(posedge clk) begin
        if (~rstn) begin
            state <= ST_DATAIN;
        end
        else begin
            state <= nextState;
        end
    end
    
//  Buffer input data:
    always @(posedge dataClk) begin
        if (~rstn) begin
            dataBuffer <= 1'b0;
        end
        else begin
            dataBuffer <= data;
        end
    end
    
//  Previous data clk signal:
    always @(posedge clk) begin
        if (~rstn) begin
            dataClkPrev <= 1'b0;
        end
        else begin
            dataClkPrev <= dataClk;
        end
    end
    
//  Data clock postive edge detector:
    always @(posedge clk) begin
        if (~rstn) begin
            dataClkEdge <= 1'b0;
        end
        else begin
            if ((dataClkPrev == 1'b0) && (dataClk == 1'b1)) begin
                dataClkEdge <= 1'b1;
            end
            else begin
                dataClkEdge <= 1'b0;
            end
        end
    end
    
//  Address counter increment logic:
    always @(*) begin
        if (~rstn) begin
            bramAddrInc <= 4'd0;
        end
        else begin
            case (state)
                ST_DATAIN: begin
                    bramAddrInc <= dataClkEdge ? 4'd1 : 4'd0;
                end
                ST_FULL: begin
                    bramAddrInc <= 4'd0;
                end
                ST_DATAOUT: begin
                    bramAddrInc <= 4'd8;
                end
                ST_WAITREC: begin
                    bramAddrInc <= 4'd0;
                end
                ST_EMPTY: begin
                    bramAddrInc <= 4'd8;
                end
                default: begin
                    bramAddrInc <= 4'd0;
                end
            endcase
        end
    end
    
//  BRAM write enable signal:
    assign bramWriteEnable = (state == ST_DATAIN) ? dataClkEdge : 1'b0;
    
//  BRAM output register clock enable:
    assign bramOutRegCkEn = (state == ST_DATAOUT);
    
//  Full and empty signals:
    assign full = (state == ST_FULL);
    assign empty = (state == ST_EMPTY);
    
// Data ready signal:
    assign dataReady = (state == ST_WAITREC);
    
//  Data out byte:
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign dataOut[i] = dataOutI[7-i];
        end
    endgenerate
    
// BRAM block:
    BRAM_SINGLE_MACRO #(
        .BRAM_SIZE("36Kb"),             // Target BRAM, "18Kb" or "36Kb"
        .DEVICE("7SERIES"),             // Target Device: "7SERIES"
        .DO_REG(1),                     // Optional output register (0 or 1)
        .INIT(36'h000000000),           // Initial values on output port
        .INIT_FILE ("NONE"),
        .WRITE_WIDTH(1),                // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        .READ_WIDTH(8),                 // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        .SRVAL(36'h000000000),          // Set/Reset value forr port output
        .WRITE_MODE("WRITE_FIRST")      // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    ) BRAM_SINGLE_MACRO_inst (
        .DO(dataOutI),                   // Output data, width defined by READ_WIDTH parameter
        .ADDR(bramAddr),                // Input address, width defined by read/write port depth
        .CLK(clk),                      // 1-bit input clock
        .DI(dataBuffer),                // Input data port, width defined by WRITE_WIDTH parameter
        .EN(1'b1),                      // 1-bit input RAM enable
        .REGCE(bramOutRegCkEn),         // 1-bit input output register enable
        .RST(~rstn),                    // 1-bit input reset
        .WE(bramWriteEnable)            // Input write enable, width defined by write port depth  
    );
endmodule
