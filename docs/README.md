# AXI-Stream Ethernet Frame Parser & Metadata Extraction Subsystem

---

## 1. Purpose

This repository contains a streaming Ethernet Layer-2 frame parser implemented in SystemVerilog, designed for integration into FPGA- and SoC-class data-plane pipelines.

The subsystem accepts Ethernet frames over an AXI4-Stream interface, performs deterministic header decoding, and emits structured metadata aligned with the payload stream.

The design is suitable for:

- Hardware firewall front-ends  
- Packet classification engines  
- Network acceleration pipelines  
- FPGA prototyping platforms  
- Pre-ASIC RTL integration  

---

## 2. Scope

The subsystem performs:

- Ethernet II header parsing  
- Optional IEEE 802.1Q single-tag VLAN resolution  
- L3 protocol classification (IPv4, IPv6, ARP, Unknown)  
- Transparent payload forwarding  

The subsystem does **not**:

- Validate CRC/FCS  
- Perform deep packet inspection  
- Modify payload contents  
- Correct malformed AXI protocol violations  

---

## 3. System Partitioning

The project is structured into three isolated layers to enforce separation of concerns.

| Layer | Responsibility | Location |
|--------|----------------|----------|
| Board Wrapper | Clocking, reset synchronization, FPGA I/O, ILA debug | `rtl/top_ax7203.sv` |
| Parser Core | AXI4-Stream frame parsing and metadata generation | `rtl/ethernet_frame_parser.sv` |
| Verification Layer | Unit and integration testbenches | `tb/` |

### 3.1 Design Separation Model

```
┌──────────────────────────────┐
│        FPGA Board Layer      │
│  Clocking / Reset / Debug    │
└──────────────┬───────────────┘
               │ AXI-Stream
               ▼
┌──────────────────────────────┐
│  Ethernet Parser Core        │
│  Pure Fabric Implementation  │
└──────────────┬───────────────┘
               │ AXI-Stream
               ▼
  Downstream Processing Logic
```


The parser core contains:

- No board-level primitives  
- No device-specific clocking  
- No vendor-specific IP dependencies  

This ensures portability across FPGA platforms and ASIC-oriented flows.

---

## 4. Architectural Constraints

The subsystem is implemented under the following non-negotiable constraints:

| Constraint | Description |
|------------|------------|
| Single-pass parsing | Headers decoded as bytes arrive; no full-frame buffering |
| AXI compliance | `tvalid`, `tready`, and `tlast` semantics preserved |
| Backpressure safety | No data loss under downstream stall |
| Deterministic metadata timing | Metadata aligned with first payload beat |
| Synthesis safety | No inferred latches, no ambiguous FSM behavior |


## 5. High-Level Architecture

The subsystem is implemented as a stage-partitioned streaming pipeline.  
Each stage has a single functional responsibility and preserves AXI-Stream semantics.

### 5.1 Dataflow Overview

```
AXI4-Stream In
      │
      ▼
+------------------+
| AXIS Ingress     |
+------------------+
      │
      ▼
+------------------+
| Skid Buffer      |
| (Backpressure)   |
+------------------+
      │
      ▼
+------------------+
| Frame Control    |
| + Byte Counter   |
+------------------+
      │
      ▼
+------------------+
| Header Capture   |
+------------------+
      │
      ▼
+------------------+
| L2 Parser        |
| VLAN Resolver    |
| Protocol Class   |
+------------------+
      │
      ▼
+------------------+
| Metadata Packager|
+------------------+
      │
      ▼
+------------------+
| AXIS Egress      |
+------------------+
      │
AXI4-Stream Out
```

### 5.2 Design Characteristics

| Attribute | Implementation Strategy |
|------------|-------------------------|
| Header storage | Shift-register based, fixed depth |
| Backpressure isolation | Single-beat skid buffer |
| Phase control | Explicit FSM (IDLE → HEADER → PAYLOAD) |
| Metadata emission | Single-cycle valid pulse per frame |
| Payload handling | Transparent forwarding |

The pipeline guarantees one AXI word per cycle throughput under sustained `tready`.

---

## 6. Interface Specification

### 6.1 AXI4-Stream Data Interface

The parser exposes a standard AXI4-Stream interface.

#### Ingress Interface

| Signal | Direction | Description |
|--------|----------|-------------|
| `s_axis_tdata` | Input | AXI payload data |
| `s_axis_tvalid` | Input | Data valid indicator |
| `s_axis_tready` | Output | Backpressure signal |
| `s_axis_tlast` | Input | End-of-frame indicator |

#### Egress Interface

| Signal | Direction | Description |
|--------|----------|-------------|
| `m_axis_tdata` | Output | Forwarded payload data |
| `m_axis_tvalid` | Output | Output valid |
| `m_axis_tready` | Input | Downstream backpressure |
| `m_axis_tlast` | Output | End-of-frame |

### 6.2 AXI Contract

The following guarantees are enforced:

- `tdata` remains stable when `tvalid=1` and `tready=0`
- `tlast` propagates only during payload phase
- No combinational path exists from `tready` to `tvalid`
- No payload beat is dropped or duplicated

The subsystem assumes upstream compliance.  
Protocol violations are not corrected internally.

---

## 7. Metadata Sideband (TUSER)

Metadata is emitted as a structured side-channel aligned with the payload stream.

```systemverilog
typedef struct packed {
  logic [47:0] dest_mac;
  logic [47:0] src_mac;
  logic [15:0] ethertype;
  logic [11:0] vlan_id;
  logic        vlan_present;
  logic        is_ipv4;
  logic        is_ipv6;
  logic        is_arp;
  logic        is_unknown;
  logic [4:0]  l2_header_len;
} eth_metadata_t;
```

### 7.1 Metadata Emission Contract

| Property        | Guarantee                                                        |
| --------------- | ---------------------------------------------------------------- |
| Emission timing | Aligned with first payload beat                                  |
| Valid pulse     | Exactly one assertion per frame                                  |
| Stability       | Held until downstream acceptance                                 |
| Exclusivity     | Exactly one of `{is_ipv4, is_ipv6, is_arp, is_unknown}` asserted |

### 7.2 Interpretation Rules

* `ethertype` reflects resolved L3 protocol (post-VLAN)
* `vlan_id` is valid only when `vlan_present=1`
* `l2_header_len` reflects effective L2 header length (14 or 18 bytes)

Metadata is deterministic and never speculative.

---

## 8. Supported Protocols

The parser operates strictly at Layer-2 with limited Layer-3 classification.

### 8.1 Protocol Coverage

| Layer | Protocol | Status |
|--------|----------|--------|
| L2 | Ethernet II | Supported |
| L2.5 | IEEE 802.1Q (Single Tag) | Supported |
| L3 | IPv4 | Classified |
| L3 | IPv6 | Classified |
| L3 | ARP | Classified |
| L3 | Other | Classified as `is_unknown` |

Unsupported or unrecognized EtherTypes are forwarded without modification and classified as unknown.

---

## 9. Operational Characteristics

### 9.1 Throughput

| Parameter | Value |
|------------|--------|
| Sustained throughput | 1 AXI word per cycle |
| Data width | Parameterizable (default: 64 bits) |
| Backpressure handling | Fully supported |

The pipeline does not require full-frame buffering and does not stall under normal sustained traffic when `m_axis_tready` is asserted.

---

### 9.2 Latency Characteristics

Latency is deterministic and dependent on header phase completion.

| Phase | Behavior |
|--------|----------|
| Header phase | Metadata fields accumulated |
| Payload phase | Metadata emitted with first payload beat |

There is no speculative metadata emission.

Metadata is guaranteed to be valid no later than the first payload beat.

---

### 9.3 Reset Behavior

| Condition | Result |
|------------|--------|
| Reset during IDLE | Remains IDLE |
| Reset during HEADER | Returns to IDLE safely |
| Reset during PAYLOAD | Returns to IDLE safely |
| Mid-frame reset | No undefined states |

Reset does not cause latch inference or metastability in control paths.

---

## 10. Design Assumptions

The subsystem assumes:

1. Upstream AXI4-Stream compliance  
2. Proper assertion of `tlast` at frame boundaries  
3. No malformed header shorter than 14 bytes  

The subsystem does not:

- Correct malformed frames  
- Validate FCS/CRC  
- Reconstruct missing `tlast` signals  

Protocol violations propagate transparently.

---

## 11. Current Limitations

The current implementation intentionally excludes the following features:

| Feature | Status |
|----------|--------|
| Stacked VLAN (Q-in-Q) | Not supported |
| Jumbo frame optimization | Not explicitly tuned |
| CRC/FCS verification | Not implemented |
| L3 header parsing | Not implemented |
| Payload inspection | Not implemented |
| MAC/PHY integration | External to parser core |

These exclusions are deliberate to maintain deterministic timing and structural simplicity.

---

## 12. Scalability Considerations

The parser is parameterized by:

- `DATA_WIDTH`
- `USER_WIDTH`

Resource utilization scales approximately linearly with data width.

The design contains:

- No BRAM dependencies
- No DSP dependencies
- Pure LUT/FF implementation

Good.
Now we formalize engineering process and flow discipline.

This segment converts your repository into something that looks like an internal platform component, not a hobby project.

---

## 13. Repository Structure

The repository enforces strict separation between source, verification, constraints, and generated artifacts.

```

rtl/
├── axis/
├── parser/
├── metadata/
└── ethernet_frame_parser.sv

tb/
├── unit/
├── integration/
└── assertions/

constraints/
scripts/
docs/
build/
Makefile
```

### 13.1 Directory Responsibilities

| Directory | Purpose |
|------------|---------|
| `rtl/` | Synthesizable SystemVerilog source |
| `tb/` | Simulation-only verification components |
| `constraints/` | FPGA XDC constraints |
| `scripts/` | Vivado TCL automation |
| `docs/` | Architecture diagrams |
| `build/` | Generated artifacts only |

---

### 13.2 Repository Discipline

The following rules are enforced:

- All generated artifacts reside under `/build`
- No simulation outputs are committed
- No Vivado-generated files are committed
- RTL is synthesis-safe by default
- Assertions are simulation-only

The repository is intended to remain deterministic and reproducible.

---

## 14. Build & Automation Model

The project uses a unified Makefile-driven flow supporting:

- Icarus simulation
- Vivado synthesis
- Vivado implementation
- Bitstream generation
- Hardware bring-up

All flows are driven through:

```
Makefile
scripts/vivado_flow.tcl
```

---

### 14.1 Core Make Targets

| Target | Description |
|--------|------------|
| `make help` | Lists available targets |
| `make sim` | Runs Icarus integration test |
| `make vivado-sim` | Runs XSIM simulation |
| `make vivado-synth` | Runs synthesis only |
| `make vivado-impl` | Runs place & route |
| `make vivado-bit` | Generates bitstream |
| `make vivado-all` | Full Vivado flow |

---

### 14.2 Vivado Flow Architecture

The Vivado flow:

1. Creates project in `/build/vivado`
2. Adds RTL sources explicitly (no wildcards)
3. Adds constraints
4. Synthesizes parser core
5. Runs implementation
6. Optionally generates bitstream
7. Exports debug probe file (when enabled)

The flow is intentionally:

- Explicit (no implicit file discovery)
- Deterministic
- CI-friendly

---

### 14.3 Manual Compile Order Enforcement

The TCL flow forces:

```tcl
set_property source_mgmt_mode None [current_project]
```

This prevents automatic hierarchy updates from overriding the specified top module.

---

## 15. FPGA Bring-Up & Debug

The design has been validated on:

* ALINX AX7203 (Artix-7 `xc7a200tfbg484-1`)

### 15.1 Clocking Strategy

* Differential 200 MHz system clock
* IBUFDS for fabric clock input
* Synchronous reset synchronization
* No fabric clock generation inside parser core

Clock primitives are confined strictly to board wrapper layer.

---

### 15.2 On-Chip Debug (ILA)

Integrated ILA allows real-time capture of:

* AXI handshake signals
* Parser output valid
* Metadata valid
* Payload data

Debug probes are preserved using:

```tcl
set_property MARK_DEBUG true [get_nets ...]
```

Debug probe export:

```tcl
write_debug_probes build/vivado/debug.ltx
```

Hardware validation confirms:

* AXI handshake correctness
* Payload integrity
* Deterministic metadata alignment

---

## 16. Hardware Validation Status

The subsystem has been:

* Synthesized successfully
* Implemented successfully
* Bitstream generated
* Loaded onto hardware
* Verified using ILA

Validation confirms:

* Correct AXI streaming behavior
* Proper backpressure handling
* Correct metadata timing under live hardware execution

The parser does not:

- Contain Ethernet MAC functionality
- Interface directly with PHY
- Manage MDIO
- Perform FCS validation

These responsibilities are external to the parser core.

---

### 18.2 Portability

The core parser:

- Uses synthesizable SystemVerilog only
- Contains no vendor-specific primitives
- Has no dependency on FPGA IP

Board wrapper contains FPGA-specific primitives and is replaceable.

---

### 18.3 ASIC Considerations

The parser core is structurally compatible with ASIC flows under:

- Standard synchronous clock
- Reset synchronization handled externally
- AXI-Stream interface compliance

No FPGA-only constructs are present in core logic.

---

## 19. Roadmap

Future enhancements may include:

### 19.1 Protocol Extensions

- IPv4 header parsing
- TCP/UDP port extraction
- Stacked VLAN (Q-in-Q)
- MPLS classification

### 19.2 Data-Plane Extensions

- Rule-matching engine
- Hardware firewall logic
- Flow table lookup
- Statistics counters

### 19.3 Interface Extensions

- Tri-Mode Ethernet MAC integration
- RGMII/SGMII PHY integration
- PCIe/XDMA streaming input

---

## 20. Compliance & Determinism Statement

This subsystem guarantees:

- Deterministic metadata emission
- AXI4-Stream protocol correctness
- No data corruption under backpressure
- Clean reset recovery

The subsystem does not guarantee:

- Packet integrity validation
- Protection against malformed AXI traffic
- Compliance enforcement on upstream violations

All guarantees are limited strictly to defined interface contracts.

---
