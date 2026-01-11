# Synchronous FIFO Verification

## Overview
This project demonstrates SystemVerilog verification of a synchronous FIFO design using a layered testbench architecture.

## Design Specifications
- **Data Width**: 8 bits
- **Depth**: 16 entries
- **Type**: Synchronous (single clock domain)
- **Features**: 
  - Simultaneous read/write capability
  - Full and empty flags
  - Asynchronous reset

## Files
- `fifo_sync.sv` - RTL design of synchronous FIFO
- `fifo_sync_tb.sv` - SystemVerilog testbench with verification components

## Testbench Architecture

### Components Implemented
1. **Interface** - Connects testbench to DUT
2. **Transaction** - Data packet with constrained randomization
3. **Generator** - Creates random test scenarios
4. **Driver** - Drives stimulus to DUT
5. **Monitor** - Observes DUT outputs

### Transaction Operations
- **Operation 0**: Write only (40% probability)
- **Operation 1**: Read only (40% probability)
- **Operation 2**: Simultaneous read/write (10% probability)
- **Operation 3**: Idle (10% probability)

## Key Learning Points
- SystemVerilog interface usage
- Constrained random verification
- Mailbox-based communication
- Blocking vs non-blocking assignments in testbench
- `post_randomize()` function for dependent randomization

## Status
🚧 **In Progress** - Scoreboard, Environment, and Top module pending

## Author
Hemanth Kumar
