# Robust Parameterized UART IP 🚀

**Author:** 12818  
**License:** MIT  

A highly parameterized, robust UART (Universal Asynchronous Receiver-Transmitter) IP core written in Verilog. Designed for high-reliability data acquisition systems, it features a deadlock-free FSM, pipelined parity snapshots, and strict 3-stage CDC (Clock Domain Crossing) protection.

本项目是一个基于 Verilog 编写的高度参数化、高鲁棒性 UART 串口通信 IP 核。专为高可靠性数据采集系统设计，具备无死锁状态机、流水线式校验快照以及严密的 3 级跨时钟域防护。

---

## 🌟 Key Features (核心特性)

- **Highly Parameterized (高度参数化):** 
  Fully adjustable system clock frequency, baud rate, data width (e.g., 8-bit, 9-bit), stop bits (1 or 2), and parity types (None, Odd, Even) via top-level parameters. Counter widths are automatically inferred using `$clog2()`.
  *(全参数化配置，可通过顶层参数一键调节系统时钟、波特率、数据位宽、停止位及奇偶校验模式。底层计数器位宽通过 `$clog2()` 自动推导。)*

- **Robust CDC Protection (工业级 CDC 防护):** 
  The RX module utilizes a 3-stage register pipeline (`d0`, `d1`, `d2`) to effectively mitigate metastability from asynchronous external signals, ensuring safe edge detection.
  *(接收端采用 3 级寄存器级联，第一级硬抗亚稳态，后两级进行安全的边沿检测，彻底封死外部异步信号带来的亚稳态泄漏。)*

- **Deadlock-Free FSM (无死锁状态机):** 
  Strict priority encoding in control flows and perfect cycle alignment using the `MAX - 1` architecture prevents timing deadlocks.
  *(严格确立复位与清零优先级的控制流，利用 `MAX - 1` 架构实现底层物理节拍 100% 对齐，消除潜在的时序死锁。)*

- **1-Tick Handshake (单拍握手接口):** 
  Outputs a clean 1-clock-cycle `valid` pulse upon successful reception and parity check, ready for seamless integration with downstream AXI4-Stream interfaces or FIFOs.
  *(接收端数据与标志位绝对同步分离，输出干净利落的单时钟周期 `valid` 脉冲，可无缝挂载下游的异步 FIFO 或 AXI-Stream 接口。)*

## 🔬 Applications (应用场景)

Ideal for lab environments and industrial systems requiring mission-critical physical layer (PHY) communication. It ensures zero-packet-loss transmission for high-precision measurement setups, such as:
- Noise thermometry data acquisition
- Quantum voltage standard readouts
- High-speed motor control feedback loops

*(非常适合需要关键任务物理层 (PHY) 通信的实验室环境和工业系统。可确保高精度测量设备的数据零丢包回传，例如：噪声温度测量数据采集、量子电压标准读数回传、高速电机控制反馈环路等。)*

## 📁 File Structure (文件结构)

```text
├── rtl/
│   ├── uart_top.v       # Top-level loopback demo (回环测试顶层)
│   ├── uart_rx.v        # UART Receiver PHY (接收端物理层)
│   └── uart_tx.v        # UART Transmitter PHY (发送端物理层)
├── sim/
│   └── tb_uart_top.v    # Automated Testbench (自动化仿真测试台)
├── images/
│   └── waveform.png     # Simulation waveform (仿真波形图)
├── .gitignore
└── README.md