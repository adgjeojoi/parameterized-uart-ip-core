`timescale 1ns / 1ps

// ==============================================================================
// Author:       ZHAO
// Create Date:  2026/08/16
// Module Name:  uart_top (UART Loopback Top Level)
// Project:      Robust Parameterized UART IP
// 
// Description:  A highly parameterized, robust UART top-level module configured 
//               for loopback testing. It seamlessly connects the UART Receiver (RX) 
//               to the UART Transmitter (TX) for hardware verification.
//               (一个高度参数化且高鲁棒性的 UART 顶层模块，配置为回环测试模式。
//               它将 UART 接收器 (RX) 与发送器 (TX) 无缝连接，用于硬件验证。)
//
// License:      MIT License
// ==============================================================================

module uart_top #(
    parameter CLK_FREQ   = 50000000,  // 系统时钟频率 | System clock frequency
    parameter BAUD_RATE  = 115200,    // 串口波特率 | UART baud rate
    parameter DATA_WIDTH = 8,         // 数据位宽 | Data bit width
    parameter STOP_WIDTH = 1,         // 停止位宽 (0,1,2) | Stop bit width (0, 1, or 2)
    parameter CHECK_TYPE = 0          // 校验类型 (0无, 1奇, 2偶) | Parity type (0: None, 1: Odd, 2: Even)
)(
    input  wire clk,                  // 系统纯净时钟 | System clean clock
    input  wire reset,                // 系统纯净复位 (高电平有效) | System clean reset (active high)
    input  wire uart_rxd,             // 串行数据接收引脚 | Serial data receive pin
    output wire uart_txd              // 串行数据发送引脚 | Serial data transmit pin
);

    // ==========================================================================
    // 内部信号连线 | Internal Signal Connections
    // ==========================================================================
    
    wire [DATA_WIDTH-1:0] loopback_data;   // 回环数据总线 | Loopback data bus
    wire                  loopback_valid;  // 回环数据有效脉冲 | Loopback data valid pulse
    wire                  tx_is_busy;      // 发送端忙碌标志 | Transmitter busy flag
    wire                  rx_frame_err;    // 接收帧错误标志 | Receive frame error flag


    // ==========================================================================
    // 1. 例化高可靠性接收模块 | 1. Instantiate the robust UART Receiver
    // ==========================================================================
    uart_rx #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .DATA_WIDTH (DATA_WIDTH),
        .STOP_WIDTH (STOP_WIDTH),
        .CHECK_TYPE (CHECK_TYPE)
    ) u_uart_rx (
        .clk            (clk),
        .reset          (reset),
        .uart_rxd       (uart_rxd),
        .uart_rx_data   (loopback_data),    // 抛出接收数据 | Output received data
        .rx_valid       (loopback_valid),   // 抛出单拍就绪脉冲 | Output 1-tick valid pulse
        .uart_frame_err (rx_frame_err)      // 抛出帧错误标志 | Output frame error flag
    );


    // ==========================================================================
    // 2. 例化无死锁发送模块 | 2. Instantiate the deadlock-free UART Transmitter
    // ==========================================================================
    uart_tx #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .DATA_WIDTH (DATA_WIDTH),
        .STOP_WIDTH (STOP_WIDTH),
        .CHECK_TYPE (CHECK_TYPE)
    ) u_uart_tx (
        .clk            (clk),
        .reset          (reset),
        // 【核心握手逻辑】：仅当 RX 有效且 TX 空闲时，触发一次发送 
        // 【Core handshake logic】: Trigger transmission only when RX is valid and TX is idle
        .uart_tx_en     (loopback_valid & ~tx_is_busy), 
        .uart_tx_data   (loopback_data),    // 吞入 RX 发来的数据 | Latch data from RX
        .uart_txd       (uart_txd),
        .tx_busy        (tx_is_busy)        // 抛出发送忙碌状态 | Output TX busy state
    );

endmodule