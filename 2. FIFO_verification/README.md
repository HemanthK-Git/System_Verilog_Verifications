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

```
┌─────────────────────────────────────────────────────────┐
│                    Top Module (tb)                      │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────────┐ │
│  │  Interface   │──│     DUT     │  │  Environment  │ │
│  │  (fif)       │  │ (sync_fifo) │  │     (env)     │ │
│  └──────────────┘  └─────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │         Environment Components        │
        ├───────────────────────────────────────┤
        │  ┌──────────┐    ┌────────────┐      │
        │  │Generator │───→│   Driver   │      │
        │  └──────────┘    └────────────┘      │
        │       │               │               │
        │   Mailbox         Interface           │
        │       │               │               │
        │  ┌──────────┐    ┌────────────┐      │
        │  │ Monitor  │───→│ Scoreboard │      │
        │  └──────────┘    └────────────┘      │
        └───────────────────────────────────────┘
```

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

**Key Concept:** Uses **non-blocking assignments (`<=`)** for interface signals.

### 5. **Monitor** (`monitor`)
Passively observes DUT behavior and captures data.

**Features:**
- Samples all signals (inputs + outputs) at each clock edge
- Creates new transaction for each observation
- Sends captured data to Scoreboard

**Key Concept:** Uses **blocking assignments (`=`)** for transaction fields.

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

## 🔑 Key Concepts Demonstrated

### Blocking vs Non-Blocking Assignments
| Context | Operator | Example |
|---------|----------|---------|
| Interface signals (hardware-like) | `<=` | `fif.data_in <= trdrv.data_in;` |
| Class members (software-like) | `=` | `trmon.data_out = fif.data_out;` |

**Why?** Prevents race conditions and ensures correct data capture in verification.

### Object Creation Patterns
| Component Type | Pattern | Reason |
|----------------|---------|--------|
| Producer (Monitor, Generator) | `new()` each iteration | Each transaction is unique |
| Consumer (Driver, Scoreboard) | `new()` once in constructor | Reuse container |

### Mailbox Communication
```
Generator → [gen_to_drv] → Driver
Monitor → [mon_to_scb] → Scoreboard
```

### Constrained Random Verification
- Weighted distribution of operations
- Automatic stimulus generation
- Better coverage than directed tests

## 🛠️ Simulation Requirements

**This testbench requires a commercial simulator with full SystemVerilog support:**

### Supported Simulators
- **ModelSim/QuestaSim** (Mentor Graphics)
- **VCS** (Synopsys)  
- **Xcelium** (Cadence)

### NOT Supported
- ❌ Iverilog (lacks OOP features)
- ❌ Verilator (limited SV support)

## 🚀 Compilation & Simulation

### ModelSim/QuestaSim
```bash
# Compile
vlog -sv fifo_sync.sv fifo_sync_tb.sv

# Simulate
vsim -c tb -do "run -all; quit"

# With GUI
vsim tb
run -all
```

### VCS
```bash
# Compile and elaborate
vcs -sverilog fifo_sync.sv fifo_sync_tb.sv

# Run
./simv
```

### Xcelium
```bash
# Compile and run
xrun -sv fifo_sync.sv fifo_sync_tb.sv
```

## 📊 Expected Output

```
[drv]: reset working
[drv]: data_in=123, write_en=1, read_en=0
[scr]: data_in=123
[mon]: data_out=0, full=0, empty=1
[drv]: data_in=45, write_en=1, read_en=0
[scr]: data_in=45
...
[drv]: data_in=78, write_en=0, read_en=1
[scb]: PASS - Expected: 123, Got: 123
...
```

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

## 🔧 Customization

### Change Transaction Count
```systemverilog
// In top module
env.gen.count = 50;  // Generate 50 transactions
```

### Modify Operation Distribution
```systemverilog
// In transaction class
constraint operation_constraint {
  operation dist {
    0 := 50,  // More writes
    1 := 30,  // Fewer reads
    2 := 15,  // More simultaneous
    3 := 5    // Less idle
  };
}
```

### Adjust Simulation Time
```systemverilog
// In environment run() task
#2000;  // Run for 2000ns instead of 1000ns
```

## 🐛 Known Limitations

- Requires commercial simulator
- No waveform dumping (add `$dumpfile`/`$dumpvars` if needed)
- Fixed FIFO depth (16 entries)
- No coverage collection (can be added)

## 📚 References

- SystemVerilog IEEE 1800-2017 Standard
- "SystemVerilog for Verification" by Chris Spear
- UVM (Universal Verification Methodology) concepts

## 👤 Author

**Hemanth Kumar**
- Learning-focused implementation
- Built from scratch without copying reference code
- Emphasis on understanding verification methodology

## 📝 License

Educational/Learning Purpose

---

**Status:** ✅ Complete - All 8 components implemented and tested
