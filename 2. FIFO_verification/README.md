# Synchronous FIFO Verification - Complete Testbench

## 📋 Overview
A complete SystemVerilog verification environment for a synchronous FIFO design, built using layered testbench architecture with constrained random verification methodology.

## 🎯 Design Specifications

### FIFO Features
- **Data Width:** 8 bits
- **Depth:** 16 entries
- **Type:** Synchronous (single clock domain)
- **Operations:** 
  - Write only
  - Read only
  - Simultaneous read/write
  - Idle
- **Flags:** Full and Empty status indicators
- **Reset:** Asynchronous active-high reset

## 📁 Files

| File | Description |
|------|-------------|
| `fifo_sync.sv` | RTL design of synchronous FIFO |
| `fifo_sync_tb.sv` | Complete verification testbench |

## 🏗️ Testbench Architecture

### Components

### 1. **Interface** (`fifo_interface`)
Bundles all DUT signals for clean testbench-DUT connection.

**Signals:**
- `clk`, `rst`
- `data_in[7:0]`, `write_en`, `read_en`
- `data_out[7:0]`, `full`, `empty`

### 2. **Transaction** (`transaction`)
Represents a single test stimulus/response packet.

**Fields:**
- **Randomizable:** `data_in[7:0]`, `operation[1:0]`
- **Control:** `write_en`, `read_en`
- **Outputs:** `data_out[7:0]`, `full`, `empty`

**Constraint:**
```systemverilog
operation dist {
  0 := 40,  // Write only (40%)
  1 := 40,  // Read only (40%)
  2 := 10,  // Simultaneous (10%)
  3 := 10   // Idle (10%)
};
```

**`post_randomize()` function:** Decodes operation into write_en/read_en signals.

### 3. **Generator** (`generator`)
Creates constrained random transactions and sends to Driver.

**Key Features:**
- Configurable transaction count
- Randomization with constraints
- Mailbox communication to Driver

### 4. **Driver** (`driver`)
Drives stimulus to DUT through interface.

**Tasks:**
- `reset()` - Resets the DUT
- `run()` - Continuously drives transactions from Generator


### 6. **Scoreboard** (`scoreboard`)
Checks DUT correctness using a reference model.

**Components:**
- **Reference Model:** Queue-based FIFO model
- **Write Check:** Stores data in queue when write occurs
- **Read Check:** Compares DUT output with expected value
- **Counters:** Tracks pass/fail statistics

**Algorithm:**
```
if (write_en && !full):
    queue.push_back(data_in)

if (read_en && !empty):
    expected = queue.pop_front()
    if (expected == data_out):
        PASS
    else:
        FAIL
```

### 7. **Environment** (`environment`)
Manager class that creates and connects all components.

**Responsibilities:**
- Creates mailboxes for communication
- Instantiates all components
- Connects interface to Driver and Monitor
- Orchestrates test execution

**Tasks:**
- `pre_test()` - Setup and reset
- `test()` - Runs all components in parallel
- `run()` - Complete test flow

### 8. **Top Module** (`tb`)
Main testbench that ties everything together.

**Features:**
- Interface instantiation
- DUT instantiation and connection
- Clock generation (10ns period)
- Environment creation and test execution


## 📈 Verification Metrics

- **Transaction Count:** Configurable (default: 20)
- **Operation Coverage:** All 4 operation types
- **Pass/Fail Tracking:** Automatic scoreboard checking
- **Reference Model:** Queue-based golden model

## 🎓 Learning Outcomes

This testbench demonstrates:
- ✅ Layered testbench architecture
- ✅ Constrained random verification
- ✅ Reference model checking
- ✅ Mailbox-based communication
- ✅ SystemVerilog OOP concepts
- ✅ Interface-based connectivity
- ✅ Parallel execution with fork-join



## 📚 References

- SystemVerilog IEEE 1800-2017 Standard
- "SystemVerilog for Verification" by Chris Spear
- UVM (Universal Verification Methodology) concepts


**Status:** ✅ Complete - All 8 components implemented and tested
