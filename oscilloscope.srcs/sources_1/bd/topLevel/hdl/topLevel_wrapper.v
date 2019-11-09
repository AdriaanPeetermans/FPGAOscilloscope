//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2700185 Thu Oct 24 18:46:05 MDT 2019
//Date        : Sat Nov  9 15:49:14 2019
//Host        : aask running 64-bit major release  (build 9200)
//Command     : generate_target topLevel_wrapper.bd
//Design      : topLevel_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module topLevel_wrapper
   (CLK100MHZ,
    ck_io,
    ck_rst,
    led,
    trigger,
    uart_rxd_out,
    uart_txd_in);
  input CLK100MHZ;
  input [3:0]ck_io;
  input ck_rst;
  output [3:0]led;
  input trigger;
  output uart_rxd_out;
  input uart_txd_in;

  wire CLK100MHZ;
  wire [3:0]ck_io;
  wire ck_rst;
  wire [3:0]led;
  wire trigger;
  wire uart_rxd_out;
  wire uart_txd_in;

  topLevel topLevel_i
       (.CLK100MHZ(CLK100MHZ),
        .ck_io(ck_io),
        .ck_rst(ck_rst),
        .led(led),
        .trigger(trigger),
        .uart_rxd_out(uart_rxd_out),
        .uart_txd_in(uart_txd_in));
endmodule
