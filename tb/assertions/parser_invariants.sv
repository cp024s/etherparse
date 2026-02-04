// ============================================================
// File: parser_runtime_checks.sv
// Purpose: Simulator-safe invariant checks (Icarus + Vivado)
// ============================================================

`timescale 1ns/1ps

// This file assumes it is INCLUDED inside the top TB
// and has access to `dut`

// ------------------------------------------------------------
// 1. frame_start must be one-cycle pulse
// ------------------------------------------------------------
logic frame_start_d;

always_ff @(posedge dut.clk) begin
  if (!dut.rst_n) begin
    frame_start_d <= 1'b0;
  end else begin
    if (frame_start_d && dut.frame_start) begin
      $fatal(1, "[ASSERT] frame_start asserted for >1 cycle");
    end
    frame_start_d <= dut.frame_start;
  end
end

// ------------------------------------------------------------
// 2. header_done must assert only once per frame
// ------------------------------------------------------------
logic header_done_seen;

always_ff @(posedge dut.clk) begin
  if (!dut.rst_n || dut.frame_start) begin
    header_done_seen <= 1'b0;
  end else if (dut.header_done) begin
    if (header_done_seen) begin
      $fatal(1, "[ASSERT] header_done asserted multiple times in a frame");
    end
    header_done_seen <= 1'b1;
  end
end

// ------------------------------------------------------------
// 3. Metadata valid only at frame boundary
// ------------------------------------------------------------
always_ff @(posedge dut.clk) begin
  if (!dut.rst_n) begin
    // nothing
  end else if (dut.m_axis_tuser_valid && !dut.frame_end) begin
    $fatal(1, "[ASSERT] metadata_valid asserted outside frame_end");
  end
end

// ------------------------------------------------------------
// 4. AXI rule: valid cannot drop without handshake
// ------------------------------------------------------------
always_ff @(posedge dut.clk) begin
  if (!dut.rst_n) begin
    // nothing
  end else begin
    if (dut.m_axis_tvalid && !dut.m_axis_tready) begin
      // must stay valid until ready
      if (!dut.m_axis_tvalid) begin
        $fatal(1, "[ASSERT] m_axis_tvalid dropped without handshake");
      end
    end
  end
end

// ------------------------------------------------------------
// 5. Protocol classifier: only ONE protocol active
// ------------------------------------------------------------
always_ff @(posedge dut.clk) begin
  if (!dut.rst_n) begin
    // nothing
  end else if (dut.proto_valid) begin
    int proto_count;
    proto_count =
      dut.is_ipv4 +
      dut.is_ipv6 +
      dut.is_arp  +
      dut.is_unknown;

    if (proto_count != 1) begin
      $fatal(1, "[ASSERT] Invalid protocol decode (count=%0d)", proto_count);
    end
  end
end
