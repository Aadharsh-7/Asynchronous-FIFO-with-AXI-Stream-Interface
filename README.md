# Asynchronous FIFO with AXI-Stream Interface

## Overview

This project implements a parameterized **Asynchronous FIFO (First-In First-Out)** using Verilog HDL with an **AXI-Stream interface**.

The FIFO is designed to transfer data between independent write and read clock domains. Gray-code pointers and two-stage synchronizers are used to safely transfer pointer information across the clock domains.

The design was simulated and implemented on an FPGA board for hardware validation.

## Features

* Parameterized FIFO depth and data width
* Independent write and read clock domains
* Binary read and write pointers
* Gray-code pointer conversion
* Two-stage synchronizers for Clock Domain Crossing (CDC)
* Full and Empty flag generation
* AXI-Stream Slave interface on the input side
* AXI-Stream Master interface on the output side
* `TVALID` / `TREADY` handshake
* FPGA hardware implementation and testing

## Architecture

```text
                 AXI-Stream Input
                       │
        s_axis_tdata   │
        s_axis_tvalid  │
        s_axis_tready  │
                       ▼
              +----------------+
              |                |
              |  Async FIFO    |
              |                |
              |  Memory        |
              |  Gray Pointers |
              |  Synchronizers |
              |                |
              +----------------+
                       │
                       ▼
                 AXI-Stream Output
                       
        m_axis_tdata
        m_axis_tvalid
        m_axis_tready
```

## FIFO Architecture

### Write Domain

The write side operates using `wr_clk`.

When an AXI-Stream transfer occurs:

```text
s_axis_tvalid = 1
s_axis_tready = 1
```

the input data is written into the FIFO memory and the write pointer is incremented.

### Read Domain

The read side operates using `rd_clk`.

When:

```text
m_axis_tvalid = 1
m_axis_tready = 1
```

the data is read from the FIFO and the read pointer is incremented.

### Clock Domain Crossing

Since the write and read sides use independent clocks, the binary pointers are converted to Gray code before being transferred between clock domains.

Two-stage synchronizers are used to synchronize the Gray-coded pointers.

```text
Write Pointer
     ↓
Binary → Gray
     ↓
2-Stage Synchronizer
     ↓
Read Domain
```

and

```text
Read Pointer
     ↓
Binary → Gray
     ↓
2-Stage Synchronizer
     ↓
Write Domain
```

## AXI-Stream Interface

### Slave Interface

The input side uses:

| Signal          | Description                            |
| --------------- | -------------------------------------- |
| `s_axis_tdata`  | Input data                             |
| `s_axis_tvalid` | Indicates valid input data             |
| `s_axis_tready` | Indicates FIFO is ready to accept data |

A data transfer occurs when:

```text
s_axis_tvalid && s_axis_tready
```

### Master Interface

The output side uses:

| Signal          | Description                 |
| --------------- | --------------------------- |
| `m_axis_tdata`  | Output data                 |
| `m_axis_tvalid` | Indicates valid output data |
| `m_axis_tready` | Indicates receiver is ready |

A data transfer occurs when:

```text
m_axis_tvalid && m_axis_tready
```

## Parameters

| Parameter | Description              | Default |
| --------- | ------------------------ | ------: |
| `DEPTH`   | Number of FIFO locations |       8 |
| `WIDTH`   | Width of each data word  |       8 |

## Verification

The design was tested using a Verilog testbench for:

* Reset functionality
* AXI-Stream write operation
* AXI-Stream read operation
* FIFO empty condition
* FIFO full condition
* Different write and read clock frequencies
* Simultaneous read and write operations
* AXI `TVALID` / `TREADY` handshaking

## FPGA Implementation

The design was synthesized and implemented on an FPGA board to verify the FIFO operation on actual hardware.

A test data pattern was written into the FIFO and the corresponding output data was observed after the read operation.

## Learning Outcomes

Through this project, I gained practical understanding of:

* Verilog RTL design
* FIFO architecture
* Pointer-based memory management
* Binary-to-Gray code conversion
* Clock Domain Crossing
* Synchronizer design
* AXI-Stream handshaking
* Simulation and waveform analysis
* FPGA implementation and debugging

## Future Enhancements

* SystemVerilog Assertions (SVA)
* Self-checking verification environment
* Functional coverage
* Programmable `almost_full` and `almost_empty` flags
* Improved AXI-Stream output handling
* Performance and resource utilization analysis

## Tools Used

* Verilog HDL
* Vivado
*BOOLEAN FPGA development board

## Author

Aadharsh
