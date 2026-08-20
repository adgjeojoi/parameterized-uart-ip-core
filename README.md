# Configurable UART RTL Core

A lightweight and synthesizable **parameterized UART transmitter/receiver written in Verilog**.

Unlike fixed UART implementations such as `115200-8N1`, this design allows the UART timing and frame format to be configured through Verilog parameters.

Only a few parameters need to be changed to reuse the same RTL design for different FPGA clock frequencies and UART configurations.

## Key Feature: Fully Parameterized UART Configuration

The main feature of this project is that the UART format is **not hard-coded**.

The following parameters can be configured directly during module instantiation:

| Parameter | Description | Example |
|---|---|---:|
| `CLK_FREQ` | FPGA system clock frequency | `50_000_000` |
| `BAUD_RATE` | UART baud rate | `115200` |
| `DATA_WIDTH` | Number of UART data bits | `8` |
| `STOP_WIDTH` | Number of stop bits | `1` / `2` |
| `CHECK_TYPE` | Parity mode | `0=None`, `1=Odd`, `2=Even` |

Therefore, the same UART RTL can be reused for configurations such as:

- **8N1** — 8 data bits, no parity, 1 stop bit
- **8O1** — 8 data bits, odd parity, 1 stop bit
- **8E1** — 8 data bits, even parity, 1 stop bit
- **7E2** — 7 data bits, even parity, 2 stop bits

No modification of the UART TX/RX state logic is required.

## Example Configuration

For a **50 MHz FPGA clock, 115200 baud, 8-bit data, odd parity and 1 stop bit**:

```verilog
uart_top #(
    .CLK_FREQ   (50_000_000),
    .BAUD_RATE  (115200),
    .DATA_WIDTH (8),
    .STOP_WIDTH (1),
    .CHECK_TYPE (1)
) u_uart (
    .clk      (clk),
    .reset    (reset),
    .uart_rxd (uart_rxd),
    .uart_txd (uart_txd)
);
```

To change the design to standard **115200-8N1**, only change:

```verilog
.CHECK_TYPE (0)
```

To use the same UART core on a **100 MHz FPGA**, only change:

```verilog
.CLK_FREQ (100_000_000)
```

The baud-rate timing is automatically recalculated from `CLK_FREQ` and `BAUD_RATE`.

## UART Frame

The UART frame generated and decoded by this design is:

```text
          DATA_WIDTH bits        Optional
        <--------------->         Parity        STOP_WIDTH
        +---------------+        +------+       +--------+
 Start  |               |        |      |       |        |
   0    | D0 D1 ... Dn  |        | P    |       | 1 ...  |
--------+---------------+--------+------+-------+---------> time
         LSB first
```

UART idle level is logic `1`, and data is transmitted **LSB first**.

## Project Structure

```text
.
├── uart_rx.v          # Parameterized UART receiver
├── uart_tx.v          # Parameterized UART transmitter
├── uart_top.v         # UART RX-TX loopback example
├── tb_uart_top.v      # Simulation testbench
└── README.md
```

### `uart_rx.v`

UART receiver with:

- asynchronous RX input synchronization
- center-aligned bit sampling
- configurable data width
- optional odd/even parity checking
- configurable stop-bit checking
- `rx_valid` output pulse
- frame error detection

### `uart_tx.v`

UART transmitter with:

- configurable baud rate
- configurable data width
- optional odd/even parity generation
- configurable stop bits
- internal transmit data register
- `tx_busy` status output

### `uart_top.v`

A simple loopback demonstration:

```text
uart_rxd
    │
    ▼
+---------+
| UART RX |
+---------+
    │
    │ parallel data
    ▼
+---------+
| UART TX |
+---------+
    │
    ▼
uart_txd
```

Received UART data is automatically transmitted back through the TX module.

## Simulation

The included testbench currently uses:

```text
System Clock : 50 MHz
Baud Rate    : 115200
Data Width   : 8 bits
Parity       : Odd
Stop Bits    : 1
```

The testbench transmits:

```text
0x55
0xA3
```

The RX module decodes the incoming serial frames and the TX module sends the received data back through the loopback path.

Example simulation waveform:

```markdown
![UART Loopback Simulation](docs/uart_loopback_waveform.png)
```

## Design Notes

The baud-rate counter is calculated from:

```text
CLK_FREQ / BAUD_RATE
```

This makes the UART module independent of a specific FPGA clock frequency.

For example:

```text
CLK_FREQ  = 50 MHz
BAUD_RATE = 115200
```

gives approximately:

```text
434 FPGA clock cycles / UART bit
```

The receiver also synchronizes the asynchronous `uart_rxd` input into the FPGA clock domain before UART frame detection and sampling.

## Possible Future Improvements

- Self-checking testbench
- Automatic multi-configuration regression test
- RX/TX FIFO
- Fractional baud-rate generator
- Oversampling and majority-vote RX sampling
- Additional framing/parity error test cases
- Hardware verification on FPGA development boards

## License

MIT License.
