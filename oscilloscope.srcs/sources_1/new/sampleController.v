`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2019 13:40:20
// Design Name: 
// Module Name: sampleController
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
//
//  Receive: triggerPol (1) 0x00 neg edge, 0x01 pos edge | smplSpd (1) 0x00 50 ns, 0x01 100 ns, 0x02 200 ns, 0x03 500 ns; 0x04 1 us, 0x05 2 us, 0x06 5 us, 0x07 10 us

module sampleController (
        input               clk,
        input               rstn,
        input       [3:0]   ck_io,
        input               trigger,
        input       [2:0]   smplSpd,
        input               triggerPol,
        input               start,
        input       [3:0]   bramFull,
        input       [3:0]   bramEmpty,
        output reg  [3:0]   smplOut,
        output reg          smplClk,
        output      [3:0]   led
    );
    
    localparam [9:0]
        SC_ZERO         = 10'd0,
        SC_TWO          = 10'd2,
        SC_00           = 10'd4,
        SC_01           = 10'd9,
        SC_02           = 10'd19,
        SC_03           = 10'd49,
        SC_04           = 10'd99,
        SC_05           = 10'd199,
        SC_06           = 10'd499,
        SC_07           = 10'd999;
    
    localparam [1:0]
        ST_WAITSTART    = 2'd0,
        ST_SMPL         = 2'd1,
        ST_BRAMFULL     = 2'd2;
        
    localparam
        POL_NEGEDGE     = 1'b0,
        POL_POSEDGE     = 1'b1;
    
    reg [15:0]
        ledCnt;
    
    reg [9:0]
        smplCnt,
        smplCntMax;
        
    reg [3:0]
        fullCnt,
        emptyCnt;
        
    reg [1:0]
        state,
        nextState;
        
    reg
        triggerPrev,
        triggerEdge,
        smplStarted;
        
    wire
        fullCntRst,
        emptyCntRst,
        smplNow;
        
//  Next state logic:
    always @(*) begin
        if (~rstn) begin
            nextState <= ST_WAITSTART;
        end
        else begin
            case (state)
                ST_WAITSTART: begin
                    if (start) begin
                        nextState <= ST_SMPL;
                    end
                    else begin
                        nextState <= ST_WAITSTART;
                    end
                end
                ST_SMPL: begin
                    if (fullCnt == 4'd4) begin
                        nextState <= ST_BRAMFULL;
                    end
                    else begin
                        nextState <= ST_SMPL;
                    end
                end
                ST_BRAMFULL: begin
                    if (emptyCnt == 4'd4) begin
                        nextState <= ST_WAITSTART;
                    end
                    else begin
                        nextState <= ST_BRAMFULL;
                    end
                end
                default: begin
                    nextState <= ST_WAITSTART;
                end
            endcase
        end
    end
    
//  State update:
    always @(posedge clk) begin
        if (~rstn) begin
            state <= ST_WAITSTART;
        end
        else begin
            state <= nextState;
        end
    end
    
//  BRAM full counter:
    always @(posedge clk) begin
        if (~rstn || fullCntRst) begin
            fullCnt <= 4'd0;
        end
        else begin
            fullCnt <= fullCnt + bramFull[3] + bramFull[2] + bramFull[1] + bramFull[0];
        end
    end
      
//  BRAM empty counter:
    always @(posedge clk) begin
        if (~rstn || emptyCntRst) begin
            emptyCnt <= 4'd0;
        end
        else begin
            emptyCnt <= emptyCnt + bramEmpty[3] + bramEmpty[2] + bramEmpty[1] + bramEmpty[0];
        end
    end
    
//  Previous trigger:
    always @(posedge clk) begin
        if (~rstn) begin
            triggerPrev <= 1'b0;
        end
        else begin
            triggerPrev <= trigger;
        end
    end
    
//  Detect trigger edge:
    always @(*) begin
        if (~rstn) begin
            triggerEdge <= 1'b0;
        end
        else begin
            if (state == ST_SMPL) begin
                case (triggerPol)
                    POL_NEGEDGE: begin
                        if ((triggerPrev == 1'b1) && (trigger == 1'b0)) begin
                            triggerEdge <= 1'b1;
                        end
                        else begin
                            triggerEdge <= 1'b0;
                        end
                    end
                    POL_POSEDGE: begin
                        if ((triggerPrev == 1'b0) && (trigger == 1'b1)) begin
                            triggerEdge <= 1'b1;
                        end
                        else begin
                            triggerEdge <= 1'b0;
                        end
                    end
                    default: begin
                        triggerEdge <= 1'b0;
                    end
                endcase
            end
            else begin
                triggerEdge <= 1'b0;
            end
        end
    end
    
//  Sampling started:
    always @(posedge clk) begin
        if (~rstn) begin
            smplStarted <= 1'b0;
        end
        else begin
            if (state == ST_SMPL) begin
                if (triggerEdge) begin
                    smplStarted <= 1'b1;
                end
            end
            else begin  
                smplStarted <= 1'b0;
            end
        end
    end
    
//  Sample counter:
    always @(posedge clk) begin
        if (~rstn || triggerEdge) begin
            smplCnt <= SC_ZERO;
        end
        else begin
            if (smplCnt == smplCntMax) begin
                smplCnt <= SC_ZERO;
            end
            else begin
                smplCnt <= smplCnt + 1'b1;
            end
        end
    end
    
//  Sample counter max value:
    always @(*) begin
        if (~rstn) begin
            smplCntMax <= SC_ZERO;
        end
        else begin
            case (smplSpd)
                3'd0: begin
                    smplCntMax <= SC_00;
                end
                3'd1: begin
                    smplCntMax <= SC_01;
                end
                3'd2: begin
                    smplCntMax <= SC_02;
                end
                3'd3: begin
                    smplCntMax <= SC_03;
                end
                3'd4: begin
                    smplCntMax <= SC_04;
                end
                3'd5: begin
                    smplCntMax <= SC_05;
                end
                3'd6: begin
                    smplCntMax <= SC_06;
                end
                3'd7: begin
                    smplCntMax <= SC_07;
                end
                default: begin
                    smplCntMax <= SC_ZERO;
                end
            endcase
        end
    end
    
//  Sample output register:
    always @(posedge clk) begin
        if (~rstn) begin
            smplOut <= 4'd0;
        end
        else begin
            if (smplNow) begin
                smplOut <= ck_io;
            end
        end
    end
    
//  Sample output clock:
    always @(*) begin
        if (~rstn) begin
            smplClk <= 1'b0;
        end
        else begin
            if ((smplCnt == SC_TWO) && (state == ST_SMPL) && smplStarted) begin
                smplClk <= 1'b1;
            end
            else begin
                smplClk <= 1'b0;
            end
        end
    end
    
//  Sample led counter:
    always @(posedge clk) begin
        if (~rstn || (state == ST_WAITSTART)) begin
            ledCnt <= 15'd0;
        end
        else begin
            if (smplNow) begin
                if (ledCnt != {15{1'b1}}) begin
                    ledCnt <= ledCnt + 1'b1;
                end
            end
        end
    end
    
//  Sample now signal:
    assign smplNow = ((state == ST_SMPL) && (smplCnt == SC_ZERO) && smplStarted);
    
//  Full and empty counters reset:
    assign fullCntRst = (state == ST_WAITSTART);
    assign emptyCntRst = (state == ST_WAITSTART);
    
//  Leds:
    assign led = ledCnt[14:11];

endmodule
