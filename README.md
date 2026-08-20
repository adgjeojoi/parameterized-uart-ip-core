# 🚀 Robust Parameterized UART IP Core

<div align="center">
  <img alt="Verilog" src="https://img.shields.io/badge/Language-Verilog_HDL-blue.svg">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green.svg">
  <img alt="Status" src="https://img.shields.io/badge/Status-Verified_&_Simulated-success.svg">
  <img alt="Author" src="https://img.shields.io/badge/Author-12818-orange.svg">
</div>

<br>

A highly parameterized, robust UART (Universal Asynchronous Receiver-Transmitter) IP core written in Verilog. Designed for mission-critical data acquisition systems, it features a deadlock-free FSM, pipelined parity snapshots, and strict 3-stage CDC (Clock Domain Crossing) protection.

本项目是一个基于 Verilog 编写的高度参数化、高鲁棒性 UART 串口通信 IP 核。专为高可靠性数据采集系统设计，具备无死锁状态机、流水线式校验快照以及严密的 3 级跨时钟域防护。

---

## 🌟 Key Features (核心硬核特性)

*   **Fully Parameterized (全参数化一键配置)** 
    Support dynamic parameterization of System Clock, Baud Rate, Data Width (e.g., 8/9-bit), Stop Bits (1/2), and Parity (None/Odd/Even). Counter bit-widths are auto-inferred via `$clog2()`. 
    *(支持系统时钟、波特率、数据位宽、停止位及校验模式的顶层泛型传参，底层计数器通过 `$clog2()` 自动推导位宽，极大提升代码复用率。)*

*   **Industrial-Grade CDC (工业级 3 级跨时钟域防护)** 
    The RX PHY embeds a 3-stage register pipeline (`d0`, `d1`, `d2`) to completely isolate metastability from asynchronous external inputs before safe edge detection.
    *(接收端采用 3 级寄存器级联，第一级硬抗亚稳态，后两级进行安全的边沿检测，彻底封死外部异步信号带来的亚稳态泄漏。)*

*   **Deadlock-Free FSM (MAX-1 无死锁状态机)** 
    Strict priority logic and cycle-aligned `MAX - 1` architecture eliminate any potential timing deadlocks during continuous heavy-load transmission.
    *(严格确立控制流优先级，利用 `MAX - 1` 架构实现底层物理节拍 100% 对齐，消除连续高负载收发下潜在的时序死锁。)*

*   **1-Tick Zero-Delay Handshake (单拍零延迟握手)** 
    Separates data logic from flags. It asserts a clean 1-clock-cycle `valid` pulse upon successful verification, perfectly ready for AXI4-Stream or asynchronous FIFOs.
    *(接收数据与标志位绝对解耦，校验成功后输出极度干净的单周期 `valid` 脉冲，可无缝挂载下游异步 FIFO 或 AXI-Stream 接口。)*

## 🔬 Target Applications (核心应用场景)

This IP is specifically tailored for hardware architectures that demand **Zero-Packet-Loss** under noisy environments. 
*(专为需要在复杂电磁环境下保证**零丢包**的硬件架构打造。非常适合以下高精度仪器设备的数据回传：)*

- **Noise Thermometry DAQ:** Precision acquisition for noise temperature signals. *(噪声温度测量的高精度数据采集)*
- **Quantum Voltage Standards:** Stable interface for ultra-precise sensor readings. *(量子电压标准测量的超稳态接口)*
- **Mission-Critical Industrial Control:** Real-time feedback loops. *(关键工业控制的实时反馈环路)*

## 📁 Repository Structure (工程目录结构)

```text
├── rtl/                 # Hardware Design Sources (底层 RTL 源码)
│   ├── uart_top.v       # Loopback integration top (回环测试顶层)
│   ├── uart_rx.v        # Receiver module (接收物理层)
│   └── uart_tx.v        # Transmitter module (发送物理层)
├── sim/                 # Simulation Sources (仿真测试激励)
│   └── tb_uart_top.v    # Automated Loopback Testbench
├── images/              # Media Assets
│   └── waveform.png     
├── .gitignore
└── README.md
