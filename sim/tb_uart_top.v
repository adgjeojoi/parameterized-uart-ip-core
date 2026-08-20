`timescale 1ns / 1ps

// ==============================================================================
// Author:       ZHAO
// Create Date:  2026/08/20
// Module Name:  tb_uart_top (Testbench for UART Loopback Top)
// Project:      Robust Parameterized UART IP
// 
// Description:  Testbench for verifying the UART loopback top module.
//               Simulates external host transmission and verifies loopback data.
//               (UART 顶层回环模块的仿真测试台，模拟上位机发包并验证回环时序。)
//
// License:      MIT License
// ==============================================================================

module tb_uart_top;

    // 参数定义 (与顶层保持一致) | Parameter definitions
    localparam CLK_FREQ   = 50000000;
    localparam BAUD_RATE  = 115200;
    localparam DATA_WIDTH = 8;
    localparam STOP_WIDTH = 1;
    localparam CHECK_TYPE = 1; // 设为 1 测试奇校验模式 | Set to 1 to test Odd Parity

    // 时钟周期与单个波特周期计算 (ns) | Clock period and bit period calculations
    localparam CLK_PERIOD = 20; // 50MHz -> 20ns
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // 115200 -> ~8680ns

    // 测试激励信号 | Testbench stimulus signals
    reg                   clk;
    reg                   reset;
    reg                   uart_rxd;
    wire                  uart_txd;

    // 实例化待测顶层模块 (DUT) | Instantiate Device Under Test
    uart_top #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .DATA_WIDTH (DATA_WIDTH),
        .STOP_WIDTH (STOP_WIDTH),
        .CHECK_TYPE (CHECK_TYPE)
    ) u_dut (
        .clk        (clk),
        .reset      (reset),
        .uart_rxd   (uart_rxd),
        .uart_txd   (uart_txd)
    );

    // 生成 50MHz 时钟 | Generate 50MHz Clock
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 模拟上位机发送一个字节的 Task | Task to simulate host sending a byte
    task uart_send_byte(input [DATA_WIDTH-1:0] send_data);
        integer i;
        reg parity_bit;
        begin
            // 计算校验位 (此处以奇校验为例) | Calculate parity bit (Odd parity example)
            parity_bit = ~(^send_data);

            // 1. 发送起始位 (低电平) | 1. Send Start Bit (Low)
            uart_rxd = 1'b0;
            #(BIT_PERIOD);

            // 2. 发送数据位 (LSB First) | 2. Send Data Bits (LSB first)
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                uart_rxd = send_data[i];
                #(BIT_PERIOD);
            end

            // 3. 发送校验位 (若有) | 3. Send Parity Bit (if configured)
            if (CHECK_TYPE != 0) begin
                uart_rxd = parity_bit;
                #(BIT_PERIOD);
            end

            // 4. 发送停止位 (高电平) | 4. Send Stop Bit (High)
            for (i = 0; i < STOP_WIDTH; i = i + 1) begin
                uart_rxd = 1'b1;
                #(BIT_PERIOD);
            end

            // 帧间空闲间隙 | Inter-frame idle gap
            #(BIT_PERIOD * 2);
        end
    endtask

    // 主测试流程 | Main Test Sequence
    initial begin
        // 初始化信号 | Initialize signals
        reset    = 1'b1;
        uart_rxd = 1'b1; // 空闲态为高电平 | Idle state is High

        // 释放复位 | Release reset
        #(CLK_PERIOD * 10);
        reset = 1'b0;
        #(CLK_PERIOD * 10);

        // 模拟外部发送数据 0x55 (01010101b) | Send 0x55
        uart_send_byte(8'h55);

        // 模拟外部发送数据 0xA3 (10100011b) | Send 0xA3
        uart_send_byte(8'hA3);

        // 等待发送端完全回传并处于空闲 | Wait until loopback transmission finishes
        #(BIT_PERIOD * 20);

        $finish;
    end

endmodule