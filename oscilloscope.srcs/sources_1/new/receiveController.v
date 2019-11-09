`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2019 00:26:09
// Design Name: 
// Module Name: receiveController
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

module receiveController(
        input               clk,
        input               rstn,
        input               received,
        input       [7:0]   rx_byte,
        output reg          triggerPol,
        output reg  [2:0]   smplSpd,
        output reg          start
    );
    
    localparam
        ST_POL  = 1'b0,
        ST_SPD  = 1'b1;
        
    reg
        state,
        nextState;
        
//  Next state logic:
    always @(*) begin
        if (~rstn) begin
            nextState <= ST_POL;
        end
        else begin
            case (state)
                ST_POL: begin
                    if (received) begin
                        nextState <= ST_SPD;
                    end
                    else begin
                        nextState <= ST_POL;
                    end
                end
                ST_SPD: begin
                    if (received) begin
                        nextState <= ST_POL;
                    end
                    else begin
                        nextState <= ST_SPD;
                    end
                end
                default: begin
                    nextState <= ST_POL;
                end
            endcase
        end
    end
    
//  State update:
    always @(posedge clk) begin
        if (~rstn) begin
            state <= ST_POL;
        end
        else begin
            state <= nextState;
        end
    end
    
//  Collect data:
    always @(posedge clk) begin
        if (~rstn) begin
            triggerPol <= 1'b0;
            smplSpd <= 3'd0;
        end
        else begin
            if (received) begin
                case (state)
                    ST_POL: begin
                        triggerPol <= rx_byte[0];
                    end
                    ST_SPD: begin
                        smplSpd <= rx_byte[2:0];
                    end
                endcase
            end
        end
    end
    
//  Start signal:
    always @(posedge clk) begin
        if (~rstn) begin
            start <= 1'b0;
        end
        else begin
            if (received && (state == ST_SPD)) begin
                start <= 1'b1;
            end
            if (start) begin
                start <= 1'b0;
            end
        end
    end
    
endmodule
