`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2019 01:10:50
// Design Name: 
// Module Name: sendController
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


module sendController (
        input               clk,
        input               rstn,
        input       [7:0]   data0,
        input       [7:0]   data1,
        input       [7:0]   data2,
        input       [7:0]   data3,
        input       [3:0]   ready,
        input               is_transmitting,
        input       [3:0]   full,
        input       [3:0]   empty,
        output      [3:0]   rec,
        output reg          transmit,
        output reg  [7:0]   tx_byte
    );
    
    localparam [1:0]
        ST_WAITFULL     = 2'd0,
        ST_WAITREADY    = 2'd1,
        ST_SEND         = 2'd2;
        
    reg
        sendReady,
        is_transmittingPrev,
        hasTransmitted;
        
    reg [1:0]
        state,
        nextState,
        whichWait;
        
    reg [2:0]
        fullCnt,
        emptyCnt;
        
    wire
        fullCntRst,
        emptyCntRst;
    
//  Next state logic:
    always @(*) begin
        if (~rstn) begin
            nextState <= ST_WAITFULL;
        end
        else begin
            case (state)
                ST_WAITFULL: begin
                    if (fullCnt == 3'd4) begin
                        nextState <= ST_WAITREADY;
                    end
                    else begin
                        nextState <= ST_WAITFULL;
                    end
                end
                ST_WAITREADY: begin
                    if (emptyCnt == 3'd4) begin
                        nextState <= ST_WAITFULL;
                    end
                    else if (ready[whichWait]) begin
                        nextState <= ST_SEND;
                    end
                    else begin
                        nextState <= ST_WAITREADY;
                    end
                end
                ST_SEND: begin
                    if (sendReady) begin
                        nextState <= ST_WAITREADY;
                    end
                    else begin
                        nextState <= ST_SEND;
                    end
                end
                default: begin
                    nextState <= ST_WAITFULL;
                end
            endcase
        end
    end
    
//  State update:
    always @(posedge clk) begin
        if (~rstn) begin
            state <= ST_WAITFULL;
        end
        else begin
            state <= nextState;
        end
    end
    
//  Full counter:
    always @(posedge clk) begin
        if (~rstn || fullCntRst) begin
            fullCnt <= 3'd0;
        end
        else begin
            fullCnt <= fullCnt + full[3] + full[2] + full[1] + full[0];
        end
    end
    
//  Empty counter:
    always @(posedge clk) begin
        if (~rstn || emptyCntRst) begin
            emptyCnt <= 3'd0;
        end
        else begin
            emptyCnt <= emptyCnt + empty[3] + empty[2] + empty[1] + empty[0];
        end
    end
    
//  Which wait:
    always @(posedge clk) begin
        if (~rstn) begin
            whichWait <= 2'd0;
        end
        else begin
            if (sendReady) begin
                whichWait <= whichWait + 1'b1;
            end
        end
    end
    
//  Tx_byte:
    always @(*) begin
        if (~rstn) begin
            tx_byte <= 8'd0;
        end
        else begin
            case (whichWait)
                2'd0: begin
                    tx_byte <= data0;
                end
                2'd1: begin
                    tx_byte <= data1;
                end
                2'd2: begin
                    tx_byte <= data2;
                end
                2'd3: begin
                    tx_byte <= data3;
                end
                default: begin
                    tx_byte <= 8'd0;
                end
            endcase
        end
    end
    
//  Has already transmitted:
    always @(posedge clk) begin
        if (~rstn) begin
            hasTransmitted <= 1'b0;
        end
        else begin
            if (state == ST_SEND) begin
                hasTransmitted <= 1'b1;
            end
            else begin
                hasTransmitted <= 1'b0;
            end
        end
    end
    
//  Transmit signal:
    always @(posedge clk) begin
        if (~rstn) begin
            transmit <= 1'b0;
        end
        else begin
            if ((state == ST_SEND) && (~hasTransmitted)) begin
                transmit <= 1'b1;
            end
            if (transmit) begin
                transmit <= 1'b0;
            end
        end
    end
    
//  Send ready signal:
    always @(posedge clk) begin
        if (~rstn) begin
            sendReady <= 1'b0;
        end
        else begin
            if ((is_transmittingPrev == 1'b1) && (is_transmitting == 1'b0)) begin
                sendReady <= 1'b1;
            end
            if (sendReady) begin
                sendReady <= 1'b0;
            end
        end
    end
    
//  Is_transmitting delay:
    always @(posedge clk) begin
        if (~rstn) begin
            is_transmittingPrev <= 1'b0;
        end
        else begin
            is_transmittingPrev <= is_transmitting;
        end
    end
    
//  Full and empty coounter reset:
    assign fullCntRst = (state == ST_WAITREADY);
    assign emptyCntRst = (state == ST_WAITFULL);
    
//  Receive signal:
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign rec[i] = (sendReady && (whichWait == i));
        end
    endgenerate
    
endmodule