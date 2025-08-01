# Asynchronous FIFO Design Documentation

This document provides a detailed explanation of the Verilog modules that constitute this asynchronous First-In, First-Out (FIFO) memory design. The primary purpose of this FIFO is to safely pass data from a system operating on a write clock (`w_clk`) to another system operating on a read clock (`r_clk`), where `w_clk` and `r_clk` are asynchronous to each other.

## Core Concepts

The design is based on the standard and robust methodology of using Gray code pointers to cross clock domains.

-   **Binary Pointers**: Internally, the read and write modules use standard binary counters for simple arithmetic (incrementing).
-   **Gray Code Pointers**: Before a pointer is sent across a clock domain, it is converted to Gray code. In Gray code, only one bit changes between any two consecutive numbers. This prevents data corruption when the pointer is sampled by a different clock, as the value read will either be the old value or the new value—never a completely invalid, metastable state.
-   **Pointer Synchronizers**: When a Gray-coded pointer arrives in a new clock domain, it is passed through a 2-flop synchronizer to align it with the local clock and resolve any metastability.
-   **Full/Empty Logic**: The full and empty conditions are determined by comparing the local pointer with the synchronized pointer from the other domain. The comparison logic is specifically designed to work with Gray-coded pointers.

---

## Module Index

1.  [**`FIFO_top`**](#fifo_top): The top-level module that integrates all sub-modules.
2.  [**`Write_pointer`**](#write_pointer): Manages the write-side logic, including the write address and full flag.
3.  [**`Read_pointer`**](#read_pointer): Manages the read-side logic, including the read address and empty flag.
4.  [**`binary_to_gray`**](#binary_to_gray): A combinational utility module to convert a binary value to Gray code.
5.  [**`r2w_sync`**](#r2w_sync): Synchronizes the Gray-coded read pointer to the write-clock domain.
6.  [**`w2r_sync`**](#w2r_sync): Synchronizes the Gray-coded write pointer to the read-clock domain.
7.  [**`FIFO_memory`**](#fifo_memory): The dual-port RAM that stores the data.

---

## `FIFO_top`

This module connects all the components of the FIFO system. It handles the clock domain crossings by instantiating the pointer-management modules, the synchronizers, and the memory block.

### Ports

| Port      | Direction | Width        | Description                                            |
| :-------- | :-------- | :----------- | :----------------------------------------------------- |
| `w_clk`   | Input     | 1-bit        | The clock for the write domain.                        |
| `r_clk`   | Input     | 1-bit        | The clock for the read domain.                         |
| `w_rst_n` | Input     | 1-bit        | Active-low asynchronous reset for the write domain.    |
| `r_rst_n` | Input     | 1-bit        | Active-low asynchronous reset for the read domain.     |
| `w_en`    | Input     | 1-bit        | Write Enable. A '1' initiates a write operation.       |
| `r_en`    | Input     | 1-bit        | Read Enable. A '1' initiates a read operation.         |
| `wdata`   | Input     | `data`-bits  | The data to be written into the FIFO.                  |
| `rdata`   | Output    | `data`-bits  | The data read from the FIFO.                           |
| `w_full`  | Output    | 1-bit        | Flag indicating the FIFO is full.                      |
| `r_empty` | Output    | 1-bit        | Flag indicating the FIFO is empty.                     |

### Internal Signals

| Signal         | Width      | Description                                                              |
| :------------- | :--------- | :----------------------------------------------------------------------- |
| `r_ptr`        | `addr+1`   | Gray-coded read pointer from the `Read_pointer` module.                  |
| `w_ptr`        | `addr+1`   | Gray-coded write pointer from the `Write_pointer` module.                |
| `synced_r_ptr` | `addr+1`   | `r_ptr` after being synchronized to the `w_clk` domain.                  |
| `synced_w_ptr` | `addr+1`   | `w_ptr` after being synchronized to the `r_clk` domain.                  |
| `r_addr`       | `addr`     | The binary address for the RAM's read port.                              |
| `w_addr`       | `addr`     | The binary address for the RAM's write port.                             |

---

## `Write_pointer`

This module is responsible for all write-side operations. It generates the write address for the RAM, increments the write pointer when `w_en` is high, and determines if the FIFO is full.

### Ports

| Port       | Direction | Width    | Description                                                              |
| :--------- | :-------- | :------- | :----------------------------------------------------------------------- |
| `w_clk`    | Input     | 1-bit    | Write clock.                                                             |
| `w_rst_n`  | Input     | 1-bit    | Active-low reset.                                                        |
| `w_en`     | Input     | 1-bit    | Write enable signal.                                                     |
| `s_rd_ptr` | Input     | `SIZE+1` | The **synchronized, Gray-coded** read pointer from the read domain.      |
| `w_full`   | Output    | 1-bit    | Flag indicating the FIFO is full.                                        |
| `w_addr`   | Output    | `SIZE`   | The **binary** address for the RAM's write port.                         |
| `w_ptr`    | Output    | `SIZE+1` | The **Gray-coded** write pointer to be sent to the read domain.          |

### Internal Variables

| Variable     | Width    | Description                                                              |
| :----------- | :------- | :----------------------------------------------------------------------- |
| `w_bin`      | `SIZE+1` | The internal **binary** write pointer, used for incrementing.            |
| `w_bin_nxt`  | `SIZE+1` | The next value of the binary pointer.                                    |
| `w_gray_nxt` | `SIZE+1` | The Gray-code equivalent of `w_bin_nxt`.                                 |

### Operation

1.  On reset, the internal binary pointer (`w_bin`) and the output Gray pointer (`w_ptr`) are set to 0.
2.  The module continuously calculates the next binary pointer (`w_bin_nxt`) by adding 1 to `w_bin` if `w_en` is high and the FIFO is not full.
3.  This `w_bin_nxt` is converted to Gray code (`w_gray_nxt`) by the `binary_to_gray` module.
4.  The famous "full" condition is checked by comparing `w_gray_nxt` to the synchronized read pointer `s_rd_ptr`. The FIFO is full if the next write would make the write pointer equal to the read pointer's Gray code equivalent (with the top two bits inverted).
5.  On each rising edge of `w_clk`, `w_bin` and `w_ptr` are updated with their "next" values.

---

## `Read_pointer`

This module mirrors the `Write_pointer` for the read side. It generates the read address for the RAM, increments the read pointer when `r_en` is high, and determines if the FIFO is empty.

### Ports

| Port       | Direction | Width    | Description                                                              |
| :--------- | :-------- | :------- | :----------------------------------------------------------------------- |
| `r_clk`    | Input     | 1-bit    | Read clock.                                                              |
| `r_rst_n`  | Input     | 1-bit    | Active-low reset.                                                        |
| `r_en`     | Input     | 1-bit    | Read enable signal.                                                      |
| `s_wr_ptr` | Input     | `SIZE+1` | The **synchronized, Gray-coded** write pointer from the write domain.    |
| `r_empty`  | Output    | 1-bit    | Flag indicating the FIFO is empty.                                       |
| `r_addr`   | Output    | `SIZE`   | The **binary** address for the RAM's read port.                          |
| `r_ptr`    | Output    | `SIZE+1` | The **Gray-coded** read pointer to be sent to the write domain.          |

### Internal Variables

| Variable     | Width    | Description                                                              |
| :----------- | :------- | :----------------------------------------------------------------------- |
| `r_bin`      | `SIZE+1` | The internal **binary** read pointer, used for incrementing.             |
| `r_bin_nxt`  | `SIZE+1` | The next value of the binary pointer.                                    |
| `r_gray_nxt` | `SIZE+1` | The Gray-code equivalent of `r_bin_nxt`.                                 |

### Operation

1.  On reset, the internal binary pointer (`r_bin`) and the output Gray pointer (`r_ptr`) are set to 0. The `r_empty` flag is set to 1.
2.  The module calculates the next binary pointer (`r_bin_nxt`) by adding 1 to `r_bin` if `r_en` is high and the FIFO is not empty.
3.  This `r_bin_nxt` is converted to Gray code (`r_gray_nxt`).
4.  The "empty" condition is checked by comparing the current `r_ptr` to the synchronized write pointer `s_wr_ptr`. If they are identical, the FIFO is empty.
5.  On each rising edge of `r_clk`, `r_bin` and `r_ptr` are updated.

---

## `binary_to_gray`

A simple, combinational logic module that converts a binary number to its Gray code equivalent.

### Ports

| Port   | Direction | Width    | Description             |
| :----- | :-------- | :------- | :---------------------- |
| `bin`  | Input     | `SIZE+1` | The binary input value. |
| `gray` | Output    | `SIZE+1` | The Gray code output.   |

### Operation

The conversion is done using the formula: `gray = bin ^ (bin >> 1)`.

---

## `r2w_sync` & `w2r_sync`

These are the crucial 2-flop pointer synchronizer modules. `r2w_sync` takes the read pointer (`r_ptr`) from the read domain and safely synchronizes it to the write clock (`w_clk`). `w2r_sync` does the opposite.

### Ports (`r2w_sync` example)

| Port       | Direction | Width      | Description                                                 |
| :--------- | :-------- | :--------- | :---------------------------------------------------------- |
| `s_wr_ptr` | Output    | `ADDRSIZE+1` | The synchronized pointer, now safe to use in the write domain. |
| `rptr`     | Input     | `ADDRSIZE+1` | The Gray-coded pointer from the read domain.                |
| `w_clk`    | Input     | 1-bit      | The destination clock (write clock).                        |
| `w_rst_n`  | Input     | 1-bit      | The destination domain's active-low reset.                  |

### Operation

The input pointer is passed through two cascaded flip-flops clocked by the destination clock. This standard structure minimizes the probability of metastability affecting the destination logic.

---

## `FIFO_memory`

This module represents the dual-port RAM where the data is stored. It has one write port and one read port.

*(Note: The content for this file was not available in the repository, but its instantiation in `FIFO_top` defines its expected interface.)*

### Expected Ports

| Port     | Direction | Width        | Description                                                              |
| :------- | :-------- | :----------- | :----------------------------------------------------------------------- |
| `rdata`  | Output    | `DATASIZE`   | Data read from the `raddr`.                                              |
| `wdata`  | Input     | `DATASIZE`   | Data to be written at `waddr`.                                           |
| `waddr`  | Input     | `ADDRSIZE`   | The write address.                                                       |
| `raddr`  | Input     | `ADDRSIZE`   | The read address.                                                        |
| `wclken` | Input     | 1-bit        | Write Clock Enable. The write happens when this and `wclk` are high.     |
| `wfull`  | Input     | 1-bit        | The full flag (often used to gate the write enable).                     |
| `wclk`   | Input     | 1-bit        | The write clock.                                                         |
