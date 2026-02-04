# <div align="center">AXI-Stream Ethernet Frame Parser & Metadata Extraction Subsystem</div>

<div align="center">

![HDL](https://img.shields.io/badge/HDL-SystemVerilog-blue) ![Interface](https://img.shields.io/badge/Interface-AXI4--Stream-informational) ![Protocols](https://img.shields.io/badge/Protocols-Ethernet%20II%20%7C%20VLAN%20%7C%20IPv4%20%7C%20ARP-success) ![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog%20%7C%20Vivado-orange) ![Automation](https://img.shields.io/badge/Automation-Makefile-green) ![Stage](https://img.shields.io/badge/Stage-Pre--Silicon-blueviolet) ![Status](https://img.shields.io/badge/Status-Stable-brightgreen)

</div>

---

## 📌 Project Overview

This repository implements a **cycle-accurate, streaming Ethernet frame parser subsystem** designed for **SoC-class RTL integration and pre-silicon verification**.

The subsystem ingests raw Ethernet frames over **AXI4-Stream**, performs **single-pass Layer-2 header parsing**, resolves VLAN encapsulation, classifies the payload protocol, and emits:

* a **payload AXI4-Stream**, forwarded without modification, and
* a **structured metadata side-channel** describing the decoded protocol context.

The design is explicitly **streaming-first**, **backpressure-safe**, and **synthesis-clean**, making it suitable for both **FPGA prototyping** and **ASIC-oriented RTL flows**.

This block is intended to serve as a **front-end parsing stage** for:

* hardware firewalls
* packet classification engines
* network accelerators
* programmable NIC pipelines
* verification reference designs


---

## 🧱 Architectural Intent

This design is built around a few **non-negotiable principles**:

* **Single-pass parsing**
  Headers are decoded as bytes arrive. Frames are never buffered end-to-end.

* **Strict AXI4-Stream compliance**
  `tvalid`, `tready`, and `tlast` semantics are preserved across all stages.

* **Decoupled control and datapath**
  FSMs do not contaminate datapath timing.

* **Deterministic metadata timing**
  Metadata is emitted **before or aligned with the first payload beat** — never after.

* **Synthesis predictability**
  No inferred RAMs, no latches, no ambiguous FSM behavior.

If any of these break, the design is wrong.

---

## 🏗 High-Level Architecture

```
AXI4-Stream In
    │
    ▼
AXIS Ingress
    │
    ▼
Skid Buffer (Backpressure Protection)
    │
    ▼
Frame Control FSM
    │
    ├── Byte Counter
    ├── Header Shift Register
    │
    ├── Ethernet Header Parser
    ├── VLAN Resolver
    ├── Protocol Classifier
    │
    ▼
Metadata Packager
    │
    ▼
AXIS Egress
    │
AXI4-Stream Out (Payload + TUSER Metadata)
```

Each stage is **independently verifiable** and can accept or propagate backpressure without data loss or protocol violation.

---

## 📐 Interface Specification

### AXI4-Stream Data Plane

**Input (Ingress)**

* `s_axis_tdata` `s_axis_tvalid` `s_axis_tready` `s_axis_tlast`

**Output (Egress)**

* `m_axis_tdata` `m_axis_tvalid` `m_axis_tready` `m_axis_tlast`

Payload data is forwarded **unaltered**.

---

### Metadata Sideband (TUSER)

Metadata is emitted as a **structured side-channel**, aligned with the payload stream.

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

**Interpretation rules**:

* `ethertype` reflects the **final resolved L3 protocol**
* `vlan_id` is valid only if `vlan_present == 1`
* Exactly one of `{is_ipv4, is_ipv6, is_arp, is_unknown}` is asserted

---

## 📚 Supported Protocols

|   Layer | Support                       |
| ------: | ----------------------------- |
|      L2 | Ethernet II                   |
|    L2.5 | IEEE 802.1Q VLAN (single tag) |
|      L3 | IPv4, IPv6, ARP               |
| Payload | Transparent forwarding        |

Unsupported or malformed frames are **classified as `is_unknown`** and still forwarded.

---

### ⚠ Design Assumption

> Upstream logic **must provide AXI-compliant streams**.
> Protocol violations are not corrected or masked by this subsystem.

---


## 🧠 RTL Implementation

### Design Methodology

The RTL is organized as a **stage-partitioned streaming pipeline**, where:

* **Control logic** (FSMs, counters) is isolated from datapath logic
* **All state transitions are cycle-explicit**
* **No combinational paths span multiple pipeline stages**
* **No module assumes continuous throughput**

This guarantees predictable timing closure and debuggability under backpressure.

---

### Core Modules and Responsibilities

| Module                  | Responsibility                                     |
| ----------------------- | -------------------------------------------------- |
| `axis_ingress`          | Normalizes AXI handshaking, captures ingress beats |
| `axis_skid_buffer`      | Absorbs downstream backpressure without data loss  |
| `frame_control_fsm`     | Tracks frame lifecycle: idle → header → payload    |
| `byte_counter`          | Tracks byte position across AXI words              |
| `header_shift_register` | Captures first N header bytes (byte-accurate)      |
| `eth_header_parser`     | Extracts destination/source MAC and EtherType      |
| `vlan_resolver`         | Detects VLAN tag and resolves final EtherType      |
| `protocol_classifier`   | Classifies IPv4 / IPv6 / ARP / Unknown             |
| `metadata_packager`     | Packs decoded fields into structured TUSER         |
| `axis_egress`           | Forwards payload with aligned metadata             |

There are **no monolithic modules**. Each block has a single reason to exist.

---

## 🔍 Detailed Module Descriptions

<details>
<summary><strong><code>ethernet_frame_parser.sv</code> (Top-Level)</strong></summary>

**Responsibility**

* Integrates all pipeline stages
* Owns AXI boundary semantics
* Aligns metadata with payload stream

**Key Guarantees**

* AXI4-Stream compliance at all boundaries
* Deterministic metadata timing
* Clean reset recovery mid-frame

**Why it exists**
This module is the **only place** where global timing, reset, and interface contracts are enforced.
No other module is allowed to “know” the whole pipeline.

</details>


<details>
<summary><strong><code>axis_ingress.sv</code></strong></summary>

**Responsibility**

* Normalizes incoming AXI4-Stream handshake
* Captures ingress beats safely under backpressure

**Key Guarantees**

* No data loss on upstream stalls
* Stable `tdata` under `tvalid && !tready`

**Why it exists**
AXI protocol handling is isolated here so parsing logic never deals with handshake corner cases.

</details>

<details>
<summary><strong><code>axis_skid_buffer.sv</code></strong></summary>

**Responsibility**

* Absorbs downstream backpressure
* Prevents combinational ready/valid paths

**Key Guarantees**

* One-beat buffering
* Timing-safe decoupling between stages

**Why it exists**
Without this block, timing closure collapses the moment downstream logic stalls.

</details>

<details>
<summary><strong><code>frame_control_fsm.sv</code></strong></summary>

**Responsibility**

* Tracks frame lifecycle: IDLE → HEADER → PAYLOAD
* Generates control signals for header capture and payload forwarding

**Key Guarantees**

* Header phase completes before payload phase
* Illegal state transitions are impossible

**Why it exists**
Control flow is explicit and auditable.
No hidden phase inference from counters or datapath signals.

</details>

<details>
<summary><strong><code>header_shift_register.sv</code></strong></summary>

**Responsibility**

* Captures the first N bytes of the Ethernet frame
* Provides byte-accurate access to header fields

**Key Guarantees**

* Deterministic byte ordering
* No dynamic indexing or variable part-selects

**Why it exists**
This enables synthesis-safe header parsing without buffering full frames.

</details>


<details>
<summary><strong><code>eth_header_parser.sv</code></strong></summary>

**Responsibility**

* Extracts destination MAC, source MAC, and initial EtherType

**Key Guarantees**

* Correct byte alignment across AXI word boundaries
* No dependency on payload phase

**Why it exists**
Separates raw header extraction from protocol interpretation.

</details>


<details>
<summary><strong><code>vlan_resolver.sv</code></strong></summary>

**Responsibility**

* Detects IEEE 802.1Q VLAN tagging
* Extracts VLAN ID and resolves final EtherType

**Key Guarantees**

* Correct header length computation
* Safe behavior for VLAN and non-VLAN frames

**Why it exists**
VLAN handling is isolated to prevent polluting base Ethernet logic.

</details>


<details>
<summary><strong><code>protocol_classifier.sv</code></strong></summary>

**Responsibility**

* Classifies payload protocol (IPv4 / IPv6 / ARP / Unknown)

**Key Guarantees**

* Exactly one classification bit asserted
* Unsupported protocols handled gracefully

**Why it exists**
Keeps protocol policy separate from parsing mechanics.

</details>


<details>
<summary><strong><code>metadata_packager.sv</code></strong></summary>

**Responsibility**

* Aggregates decoded fields into structured metadata
* Drives AXI TUSER sideband

**Key Guarantees**

* Metadata emitted exactly once per frame
* Metadata aligned with first payload beat

**Why it exists**
Centralizes all metadata timing and validity rules in one place.

</details>


<details>
<summary><strong><code>axis_egress.sv</code></strong></summary>

**Responsibility**

* Forwards payload stream downstream
* Preserves AXI semantics under backpressure

**Key Guarantees**

* No payload corruption
* Proper `tlast` propagation

**Why it exists**
Keeps output AXI handling symmetric with ingress logic.

</details>

---


### Frame Control FSM

The frame lifecycle is governed by a **strict FSM** with explicit phases:

| State     | Meaning                        |
| --------- | ------------------------------ |
| `IDLE`    | No active frame                |
| `HEADER`  | Header bytes being accumulated |
| `PAYLOAD` | Payload forwarding phase       |

FSM guarantees:

* Header capture completes **before metadata is asserted**
* `tlast` is propagated **only in PAYLOAD**
* Reset during HEADER or PAYLOAD returns safely to IDLE

FSM completeness and legality are enforced via assertions.

---

### Header Capture Strategy

* Header bytes are captured using a **shift-based register**
* Byte indexing is **counter-driven**, not data-dependent
* No dynamic slicing or variable part-selects
* Header depth is parameterized and synthesis-resolved

This avoids:

* Unpredictable synthesis behavior
* Timing instability
* Simulator vs synthesis mismatches

---

### Metadata Emission Rules

Metadata is emitted **exactly once per frame**, with the following guarantees:

* Valid only after header parsing is complete
* Aligned with the **first payload beat**
* Held stable until accepted downstream
* Never speculative or retracted


---

### Levels of Verification

| Level          | Purpose                               |
| -------------- | ------------------------------------- |
| Unit-level TBs | Validate individual modules           |
| Integration TB | End-to-end pipeline behavior          |
| Protocol tests | IPv4 / ARP / VLAN / malformed frames  |
| Stress tests   | Backpressure, stalls, reset mid-frame |

All tests are **cycle-accurate** and **self-checking**.

---

### Runtime Assertions

Simulation-only assertions enforce critical invariants:

* AXI handshake correctness (`tvalid` stability)
* Header completion before metadata valid
* Legal FSM transitions
* `tlast` alignment with frame boundaries
* No payload leakage during header phase

Assertions are **explicitly excluded from synthesis**.

This is intentional and non-negotiable.

---

### Simulator Support

Verified on:

* **Icarus Verilog** — fast functional validation
* **Vivado XSIM** — vendor-accurate elaboration and timing behavior

No simulator-specific constructs are used.

---

## 🗂 Repository Structure

```
rtl/
├── axis/
│   ├── axis_ingress.sv
│   ├── axis_skid_buffer.sv
│   └── axis_egress.sv
│
├── parser/
│   ├── frame_control_fsm.sv
│   ├── byte_counter.sv
│   ├── header_shift_register.sv
│   ├── eth_header_parser.sv
│   ├── vlan_resolver.sv
│   └── protocol_classifier.sv
│
├── metadata/
│   └── metadata_packager.sv
│
└── ethernet_frame_parser.sv   # Top-level integration

tb/
├── unit/                       # Per-module testbenches
├── integration/                # End-to-end AXI tests
└── assertions/                 # Runtime protocol checks

constraints/                    # Board-specific XDCs
scripts/                        # Vivado automation (TCL)
docs/                           # Architecture diagrams
build/                          # Generated artifacts only

Makefile                        # Unified entrypoint
```

### Repository Rules

* **All generated files go under `/build`**
* RTL is synthesis-safe by default
* Assertions are simulation-only
* No simulator artifacts committed

---

## 🧹 Lint, Elaboration & Static Checks

The RTL is continuously validated for **structural correctness and synthesis safety**.

### Checks Performed

| Check Category          | Status   |
| ----------------------- | -------- |
| Undriven nets           | Clean    |
| Width mismatches        | Clean    |
| Inferred latches        | None     |
| FSM completeness        | Verified |
| Combinational loops     | None     |
| AXI protocol violations | None     |

### Tooling

* **Icarus Verilog** (`-Wall`) for fast RTL checks
* **Vivado RTL elaboration** for synthesis-accurate validation

All remaining warnings (if any) are **intentional and documented** (e.g., protocol-dependent unused bits).

---

## 🧪 Simulation Evidence

### Supported Simulators

* **Icarus Verilog** — functional and integration testing
* **Vivado XSIM** — vendor-accurate elaboration and timing behavior

No simulator-specific constructs are used.

---

### Example Integration Run

```
=== Sending Ethernet Frame ===
[RX] data=1122334455667788 last=0
[RX] data=99aabbccddeeff00 last=0
[RX] data=0800450000000000 last=0
[RX] data=deadbeefdeadbeef last=0
[RX] data=cafebabecafebabe last=1
---- FRAME END ----
=== TEST PASSED ===
```

### Observed Metadata

```
[META]
dst_mac     = 11:22:33:44:55:66
src_mac     = 77:88:99:aa:bb:cc
ethertype   = 0x0800
vlan_present= 0
ipv4        = 1
```

**Confirms**:

* Correct MAC extraction
* Correct EtherType resolution
* Correct IPv4 classification
* Payload transparency preserved

If any of these fail, the test fails. No silent passes.

---

## ▶ Build & Run Instructions

### Prerequisites

* GNU Make
* Icarus Verilog
* Xilinx Vivado (2023+ recommended)

> [!NOTE]
> All simulations, scripts, and build flows in this repository have been **developed and tested on Windows environments**.
>
> While the design itself is OS-agnostic, behavior on **Linux or macOS hosts has not been formally validated**.  
> Minor path, shell, or toolchain differences may require user-side adjustments.

---

### ⚠️ Important: Enabling Runtime Assertions in Icarus
>[!NOTE]
>When running simulations using **Icarus Verilog**, the runtime assertion checks **must be explicitly enabled** in the integration testbench.

In the file: `tb/integration/axi_header_done_payload.sv`

Locate the following section at the **end of the file**:

```systemverilog
endmodule

// ============================================================
// Include runtime assertions LAST (global scope)
// ============================================================
//`include "tb/assertions/parser_runtime_checks.sv"
```

#### Required Action

To enable runtime protocol and sanity checks during Icarus simulation, **uncomment the include**:

```systemverilog
// ============================================================
// Include runtime assertions LAST (global scope)
// ============================================================
`include "tb/assertions/parser_runtime_checks.sv"
```

> **Why this is required**
>
> * Icarus Verilog requires assertion modules to be included at **global scope**
> * These assertions enforce AXI protocol correctness, FSM legality, and metadata timing
> * If the include remains commented:
>
>   * Simulation will still run
>   * **Critical protocol violations may go undetected**

> **Note**
>
> Assertions are **simulation-only** and are **not synthesized**.
> Vivado flows are unaffected by this include.

After enabling the include, run:

```bash
make sim
```
---

### Core Make Targets

```bash
make help
```

Lists all supported targets and overrides.

---

### Simulation (Icarus)

```bash
make sim
```

* Runs full integration testbench
* Generates waveforms under `/build`
* Assertion failures halt simulation

---

### RTL Lint / Elaboration

```bash
make lint
```

* RTL elaboration
* Parameter resolution
* Hierarchy validation

---

### Vivado Simulation

```bash
make vivado-sim
```

* Runs XSIM-based simulation
* Useful for vendor parity checks

---

### Vivado Synthesis Only

```bash
make vivado-synth
```

* RTL → netlist
* Reports utilization and timing estimates

---

### Vivado Implementation (Place & Route)

```bash
make vivado-impl
```

* Placement and routing
* Timing closure analysis

---

### Full Vivado Flow (up to Bitstream)

```bash
make vivado-all
```

> ⚠ Bitstream generation **requires valid board-level XDC constraints**.

---

## ⚙ Parameter Overrides

Parameters can be overridden at invocation time:

```bash
make sim DATA_WIDTH=128
```

```bash
make vivado-all PART=xc7a200tfbg484-1
```

### Supported Overrides

| Parameter    | Meaning                                 |
| ------------ | --------------------------------------- |
| `DATA_WIDTH` | AXI data width (default: 64)            |
| `USER_WIDTH` | Metadata sideband width                 |
| `PART`       | Target FPGA part                        |
| `BUILD_DIR`  | Output directory (default: `build/`)    |
| `SIM_TIME`   | Simulation runtime limit                |
| `MODE`       | Vivado operation mode (GUI/tcl/default) |

All generated artifacts are placed under `/build` to keep the repository clean.

---

## 🏗 FPGA Implementation Summary

### Target Class

* Xilinx 7-Series (Artix-7 / Kintex-7 class)

### Nominal Operating Point

* Clock: 125 MHz
* Throughput: **1 AXI word / cycle sustained**
* Latency: deterministic, header-dependent

---

### Resource Utilization (Post-Route, Typical)

| Resource | Usage                        |
| -------- | ---------------------------- |
| LUTs     | ~300–400                     |
| FFs      | ~300–350                     |
| BRAM     | 0                            |
| DSP      | 0                            |
| WNS      | +2 ns (constraint-dependent) |

The design is **logic-bound**, not memory-bound, and scales linearly with data width.

---

<div align="center">

**Streaming • Deterministic • Verification-Driven**

*AXI-Compliant Ethernet Frame Parser Subsystem*

</div>
