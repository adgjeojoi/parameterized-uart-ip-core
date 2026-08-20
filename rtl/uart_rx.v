`timescale 1ns / 1ps

// ==============================================================================
// Author:       zhao
// Create Date:  2026/08/16
// Module Name:  uart_rx (UART Receiver)
// Project:      Robust Parameterized UART IP
// 
// Description:  A highly parameterized, robust UART Receiver featuring 
//               3-stage CDC protection and precise center-aligned sampling. 
//               Ideal for high-reliability data acquisition systems.
//               (一个高度参数化且高鲁棒性的 UART 接收模块，具备 3 级跨时钟域
//               防护与精准的中心对齐采样机制。非常适合用于高可靠性的数据采集系统。)
//
// License:      MIT License
// ==============================================================================


module uart_rx #(
    parameter CLK_FREQ   = 50000000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8,
    parameter STOP_WIDTH = 1,         //可设置为0,1,2 | Can be set to 0, 1, or 2
    parameter CHECK_TYPE = 0          //可设置为0,1,2 | Can be set to 0, 1, or 2                                    
) (
    input                       clk,
    input                       reset,
    input                       uart_rxd,
    output reg [DATA_WIDTH-1:0] uart_rx_data,
    output reg                  rx_valid,       //数据就绪可以输出的标志信号 | Data valid pulse ready for output
    output reg                  uart_frame_err  //帧错误总报错信号 | Frame error global flag

);


  localparam BAUD_CNT_MAX = (CLK_FREQ / BAUD_RATE) - 1;
  localparam BAUD_CNT_MAX_HALF = BAUD_CNT_MAX / 2;

  localparam PARITY_WIDTH = (CHECK_TYPE == 0) ? 0 : 1;
  localparam PAYLOAD_WIDTH = DATA_WIDTH + PARITY_WIDTH;
  localparam TOTAL_WIDTH = PAYLOAD_WIDTH + STOP_WIDTH;

  //第一部分，跨时钟域打两拍 CDC 
  //Part 1: Clock Domain Crossing (CDC) synchronization
  
  reg uart_rxd_d0;
  reg uart_rxd_d1;
  reg uart_rxd_d2;
  always @(posedge clk) begin
    uart_rxd_d0 <= uart_rxd;
    uart_rxd_d1 <= uart_rxd_d0;
    uart_rxd_d2 <= uart_rxd_d1;
  end



  //第二部分，计数器设计，BAUD计数器和bit计数器
  //Part 2: Counter design, Baud counter and Bit counter
  
  reg [$clog2(BAUD_CNT_MAX)-1:0] baud_cnt;
  reg [                     3:0] bit_cnt;
  reg                            rx_busy;  //接收开始标志信号 | Receive busy flag

  //baud计数器 | Baud rate counter

  always @(posedge clk) begin
    if (reset) begin
      baud_cnt <= 'b0;
    end else if (~rx_busy || baud_cnt >= BAUD_CNT_MAX) begin
      baud_cnt <= 'b0;
    end else if (rx_busy) begin
      baud_cnt <= baud_cnt + 1'b1;
    end
  end

  //bit计数器 | Bit counter

  always @(posedge clk) begin
    if (reset) begin
      bit_cnt <= 'b0;
    end else if (~rx_busy) begin
      bit_cnt <= 'b0;
    end else if (baud_cnt >= BAUD_CNT_MAX) begin
      bit_cnt <= bit_cnt + 1'b1;
    end
  end

  //计数器控制rx_busy | rx_busy controlled by counters and edge detection
  always @(posedge clk) begin
    if (reset) begin
      rx_busy <= 'b0;
    end else if (bit_cnt >= TOTAL_WIDTH && baud_cnt >= BAUD_CNT_MAX) begin
      rx_busy <= 'b0;
    end else if (~bit_cnt && ~uart_rxd_d1 && uart_rxd_d2) begin
      rx_busy <= 1'b1;
    end
  end





  //串行输入存储 | Serial input storage

  reg [DATA_WIDTH-1:0] uart_rx_data_r;  //影子寄存器 | Shadow register

  always @(posedge clk) begin
    if (reset) begin
      uart_rx_data_r <= 'b0;
    end else if (bit_cnt >= 1 && bit_cnt <= DATA_WIDTH && baud_cnt == BAUD_CNT_MAX_HALF) begin
      uart_rx_data_r <= {uart_rxd_d1, uart_rx_data_r[DATA_WIDTH-1:1]};
    end
  end



  //校验过程 | Parity Check & Calculation
  reg parity_err;  //校验错误标志信号 | Parity error flag

  generate
    case (CHECK_TYPE)

      0: begin : no_check
        always @(posedge clk) begin
          if (reset) begin
            parity_err <= 'b0;
          end
        end
      end

      1: begin  //奇校验，数据位+校验位，1的个数为奇数，异或结果为1 | Odd parity: odd number of 1s in data + parity bits, XOR result is 1
        always @(posedge clk) begin
          if (reset) begin
            parity_err <= 'b0;
          end else if (~rx_busy) begin
            parity_err <= 'b0;
          end else if (bit_cnt == PAYLOAD_WIDTH && baud_cnt == BAUD_CNT_MAX_HALF) begin
            parity_err <= ~((^uart_rx_data_r) ^ uart_rxd_d1);
          end
        end
      end

      2: begin  //偶校验，数据位+校验位，1的个数为偶数，异或结果为0 | Even parity: even number of 1s in data + parity bits, XOR result is 0
        always @(posedge clk) begin
          if (reset) begin
            parity_err <= 'b0;
          end else if (~rx_busy) begin
            parity_err <= 'b0;
          end else if (bit_cnt == PAYLOAD_WIDTH && baud_cnt == BAUD_CNT_MAX_HALF) begin
            parity_err <= (^uart_rx_data_r) ^ uart_rxd_d1;
          end
        end
      end

      default:
      ;
    endcase
  endgenerate


  //停止位检测 | Stop bit detection
  reg stop_err;  //停止位报错信号 | Stop bit error flag

  always @(posedge clk) begin
    if (reset || ~rx_busy) begin
      stop_err <= 'b0;
    end
        else if (bit_cnt>PAYLOAD_WIDTH&&bit_cnt<=TOTAL_WIDTH&&baud_cnt==BAUD_CNT_MAX_HALF) begin
      if (uart_rxd_d1 == 'b0) begin
        stop_err <= 'b1;
      end
    end
  end


  //输出，以及valid信号与frame_err信号控制 | Output logic, valid and frame_err signal control

  always @(posedge clk) begin
    if (reset) begin
      rx_valid <= 'b0;
      uart_frame_err <= 'b0;
      uart_rx_data <= 'b0;
    end else if (bit_cnt == TOTAL_WIDTH && baud_cnt == BAUD_CNT_MAX_HALF) begin
      if (stop_err || parity_err || uart_rxd_d1 == 1'b0) begin
        rx_valid <= 'b0;
        uart_frame_err <= 'b1;
      end else begin
        rx_valid <= 'b1;
        uart_frame_err <= 'b0;
        uart_rx_data <= uart_rx_data_r;
      end
    end else begin
      rx_valid <= 'b0;
      uart_frame_err <= 'b0;
    end
  end



endmodule