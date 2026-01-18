
# <div align = center> Ethernet Frame Parser

<div align = center>

![Language](https://img.shields.io/badge/Language-SystemVerilog-blue) ![OS](https://img.shields.io/badge/Tested%20On-Ubuntu%2022.04-E95420?logo=ubuntu)  ![Domain](https://img.shields.io/badge/Domain-Packet%20Processing-success) ![Architecture](https://img.shields.io/badge/Architecture-Streaming%20Pipeline-orange) ![Interface](https://img.shields.io/badge/Interface-AXI4--Stream-informational) ![Processing](https://img.shields.io/badge/Processing-Frame--Based-yellow) ![Verification](https://img.shields.io/badge/Verification-Unit%20%7C%20Integration-brightgreen) ![Status](https://img.shields.io/badge/Status-In%20Development-lightgrey)

Streaming Ethernet frame parser and metadata generator implemented in SystemVerilog.  
Designed for AXI4-Stream–based packet processing pipelines.

 </div>

---

## Overview

The design implements a modular Ethernet frame parsing pipeline capable of:

- Capturing Ethernet headers from a streaming interface
- Handling optional single VLAN (802.1Q) tags
- Classifying Layer-3 protocol type
- Emitting structured metadata alongside the data stream

The architecture is intentionally decomposed into small, testable blocks to allow
independent verification and controlled system integration.

---

## High-Level Architecture

```
AXI Ingress
    ↓
Frame Control FSM
    ↓
Byte Counter
    ↓
Header Shift Register
    ↓
Ethernet Header Parser
    ↓
VLAN Resolver
    ↓
Protocol Classifier
    ↓
Metadata Packager
    ↓
AXI Egress (data + metadata)
```

Each stage is clocked, streaming-safe, and designed to operate without stalling
under nominal AXI4-Stream conditions.

---

## Repository Structure

```
.
├── pkg/
│   └── eth_parser_pkg.sv        # Shared types, constants, metadata structs
├── rtl/
│   ├── axis/                    # AXI ingress / egress logic
│   ├── parser/                  # Ethernet parsing pipeline stages
│   ├── metadata/                # Metadata generation logic
│   └── ethernet_frame_parser.sv # Top-level integration
├── tb/
│   ├── unit/                    # Unit-level testbenches
│   ├── integration/             # Multi-block integration tests
│   └── ethernet_frame_parser_tb.sv
├── scripts/                     # Build and test orchestration scripts
├── build/                       # Generated simulation artifacts
└── Makefile
```

---

## Build & Test Flow

All compilation and simulation is driven through **shell scripts**, with the
Makefile acting only as a thin orchestration layer.

### Make Targets

#### `make unit`
Runs **all unit tests** for individual RTL blocks.

- Compiles one module at a time
- Fails immediately on the first error
- Intended for fast local verification during development

#### `make integration`
Runs **integration-level tests** covering multiple pipeline stages.

- Validates signal timing between blocks
- Excludes full AXI ingress/egress

#### `make full`
Runs the **full system test**, including:
- AXI ingress
- Complete parsing pipeline
- Metadata generation
- AXI egress

This target is the closest approximation to real system behavior.

#### `make all`
Runs:
```
make unit
make integration
make full
```

Stops on first failure.

#### `make clean`
Removes all generated build artifacts.

---

## Simulation Notes

- Simulator: **Icarus Verilog**
- Language standard: **SystemVerilog (-g2012)**
- All simulation outputs are generated under `build/`
- The Makefile does not embed RTL file lists; these are maintained in scripts to
  keep build logic explicit and debuggable.

---

## Current Status

- Unit tests: **Passing**
- Integration tests: **Passing**
- Full system test: **Under active refinement**

The design is functionally complete at the block level.  
Top-level timing and control alignment is still being iterated.
