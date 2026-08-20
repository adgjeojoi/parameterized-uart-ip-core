`timescale 1ns / 1ps

// ==============================================================================
// Author:       zhao
// Create Date:  2026/08/16
// Module Name:  uart_tx (UART Transmitter)
// Project:      Robust Parameterized UART IP
// 
// Description:  A highly parameterized, robust UART Transmitter featuring 
//               pipelined parity snapshot and a deadlock-free FSM. 
//               Ideal for high-reliability data acquisition systems.
//               (一个高度参数化且高鲁棒性的 UART 发送模块，采用流水线式
//               校验快照技术与无死锁状态机架构。非常适合用于高可靠性的数据采集系统。)
//
// License:      MIT License
// ==============================================================================

module uart_tx #(
    parameter CLK_FREQ   = 50000000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8,
    parameter STOP_WIDTH = 1,         //可设置为0,1,2 | Can be set to 0, 1, or 2
    parameter CHECK_TYPE = 0          //可设置为0,1,2 | Can be set to 0, 1, or 2

) (
    input                       clk,
    input                       reset,
    input                       uart_tx_en,    // 发送使能信号 | Transmit enable signal
    input      [DATA_WIDTH-1:0] uart_tx_data,  // 要发送的并行数据 | Parallel data to be transmitted
    output reg                  uart_txd,      // 输出的串行数据 | Serial data output
    output reg                  tx_busy        // 正在发送标志信号 | Transmission busy flag

);
  localparam BAUD_CNT_MAX = (CLK_FREQ / BAUD_RATE) - 1;

  localparam PARITY_WIDTH = (CHECK_TYPE == 0) ? 0 : 1;
  localparam PAYLOAD_WIDTH = DATA_WIDTH + PARITY_WIDTH;
  localparam TOTAL_WIDTH = PAYLOAD_WIDTH + STOP_WIDTH;


  //第一部分，计数器设计，BAUD计数器和bit计数器
  //Part 1: Counter design, Baud counter and Bit counter
  
  reg [$clog2(BAUD_CNT_MAX)-1:0] baud_cnt;
  reg [                     3:0] bit_cnt;


  // baud计数器 | Baud rate counter

  always @(posedge clk) begin
    if (reset) begin
      baud_cnt <= 'b0;
    end else if (~tx_busy || baud_cnt >= BAUD_CNT_MAX) begin
      baud_cnt <= 'b0;
    end else if (tx_busy) begin
      baud_cnt <= baud_cnt + 1'b1;
    end
  end

  // bit计数器 | Bit counter

  always @(posedge clk) begin
    if (reset) begin
      bit_cnt <= 'b0;
    end else if (~tx_busy) begin
      bit_cnt <= 'b0;
    end else if (baud_cnt >= BAUD_CNT_MAX) begin
      bit_cnt <= bit_cnt + 1'b1;
    end
  end


  //第二部分，影子寄存器，当发送使能信号拉高时，将外部的并行数据储存
  //Part 2: Shadow register, stores external parallel data when TX enable is asserted
  
  reg [DATA_WIDTH-1:0] uart_tx_data_d;  // 影子寄存器 | Shadow register
  reg tx_parity;  // 可能会用于校验的数据异或结果 | XOR result of data, potentially used for parity bit

  always @(posedge clk) begin
    if (uart_tx_en && ~tx_busy) begin
      uart_tx_data_d <= uart_tx_data;
      tx_parity <= ^(uart_tx_data);
    end else if (tx_busy && bit_cnt <= DATA_WIDTH - 1 && baud_cnt >= BAUD_CNT_MAX) begin
      uart_tx_data_d <= uart_tx_data_d >> 1;
    end
  end

  //第三部分,tx_busy的动作和输出控制
  //Part 3: tx_busy behavior and output logic

  // tx_busy联动外部输入的uart_tx_en | tx_busy driven by external uart_tx_en
  always @(posedge clk) begin
    if (reset) begin
      tx_busy <= 'b0;
    end else if (bit_cnt == TOTAL_WIDTH && baud_cnt == BAUD_CNT_MAX) begin
      tx_busy <= 'b0;
    end else if (uart_tx_en) begin
      tx_busy <= 1'b1;
    end
  end


  // 输出信号 | Output signal logic
  generate
    case (CHECK_TYPE)
      0: begin

        always @(posedge clk) begin
          if (reset) begin
            uart_txd <= 1'b1;  // 空闲状态为高电平 | Idle state is high
          end else if (uart_tx_en && ~tx_busy) begin
            uart_txd <= 1'b0;  // 发送起始位 | Transmit start bit
          end else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1) begin
            uart_txd <= uart_tx_data_d[0];  // 发送数据位 | Transmit data bit
          end
                else if (baud_cnt==BAUD_CNT_MAX&&bit_cnt>=PAYLOAD_WIDTH&&bit_cnt<=TOTAL_WIDTH) begin
            uart_txd <= 1'b1;  // 发送停止位 | Transmit stop bit
          end
        end
      end

      1: begin

        always @(posedge clk) begin
          if (reset) begin
            uart_txd <= 1'b1;  // 空闲状态为高电平 | Idle state is high
          end else if (uart_tx_en && ~tx_busy) begin
            uart_txd <= 1'b0;  // 发送起始位 | Transmit start bit
          end else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1) begin
            uart_txd <= uart_tx_data_d[0];  // 发送数据位 | Transmit data bit
          end else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == PAYLOAD_WIDTH - 1) begin
            uart_txd <= ~tx_parity;  // 发送校验位 | Transmit parity bit
          end
                else if (baud_cnt==BAUD_CNT_MAX&&bit_cnt>=PAYLOAD_WIDTH&&bit_cnt<=TOTAL_WIDTH) begin
            uart_txd <= 1'b1;  // 发送停止位 | Transmit stop bit
          end
        end
      end


      2:

      always @(posedge clk) begin
        if (reset) begin
          uart_txd <= 1'b1;  // 空闲状态为高电平 | Idle state is high
        end else if (uart_tx_en && ~tx_busy) begin
          uart_txd <= 1'b0;  // 发送起始位 | Transmit start bit
        end else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1) begin
          uart_txd <= uart_tx_data_d[0];  // 发送数据位 | Transmit data bit
        end else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == PAYLOAD_WIDTH - 1) begin
          uart_txd <= tx_parity;  // 发送校验位 | Transmit parity bit
        end
                else if (baud_cnt==BAUD_CNT_MAX&&bit_cnt>=PAYLOAD_WIDTH&&bit_cnt<=TOTAL_WIDTH) begin
          uart_txd <= 1'b1;  // 发送停止位 | Transmit stop bit
        end
      end


      default:
      ;
    endcase
  endgenerate


endmodule
