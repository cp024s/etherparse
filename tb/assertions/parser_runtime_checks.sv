// ============================================================
// Module: parser_runtime_checks
// Purpose:
//   Runtime (non-SVA) invariants for Ethernet parser
//   Icarus-safe, Vivado-safe
// ============================================================

`timescale 1ns/1ps

module parser_runtime_checks #(
  parameter int DATA_WIDTH = 8
)(
  input logic clk,
  input logic rst_n,

  // AXI stream monitoring
  input logic                 s_tvalid,
  input logic                 s_tready,
  input logic                 s_tlast,

  // Parser internals
  input logic                 frame_start,
  input logic                 frame_end,
  input logic                 header_done,

  // Metadata
  input logic                 meta_valid
);

  // ==========================================================
  // Internal trackers
  // ==========================================================
  logic in_frame;
  logic seen_header_done;

  // ==========================================================
  // Frame lifecycle tracking
  // ==========================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_frame         <= 1'b0;
      seen_header_done <= 1'b0;
    end else begin
      // Frame start
      if (frame_start) begin
        if (in_frame) begin
          $fatal(1, "[CHK] frame_start while already in frame");
        end
        in_frame         <= 1'b1;
        seen_header_done <= 1'b0;
      end

      // Header completion
      if (header_done) begin
        if (!in_frame) begin
          $fatal(1, "[CHK] header_done asserted outside frame");
        end
        if (seen_header_done) begin
          $fatal(1, "[CHK] header_done asserted more than once per frame");
        end
        seen_header_done <= 1'b1;
      end

      // Frame end
      if (frame_end) begin
        if (!in_frame) begin
          $fatal(1, "[CHK] frame_end without frame_start");
        end
        in_frame <= 1'b0;
      end
    end
  end

  // ==========================================================
  // AXI protocol sanity
  // ==========================================================
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (s_tvalid && !s_tready && s_tlast) begin
        $fatal(1, "[CHK] tlast asserted while backpressured");
      end
    end
  end

  // ==========================================================
  // Metadata timing rules
  // ==========================================================
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (meta_valid && !seen_header_done) begin
        $fatal(1, "[CHK] metadata_valid before header_done");
      end

      if (meta_valid && !in_frame) begin
        $fatal(1, "[CHK] metadata_valid outside frame");
      end
    end
  end

endmodule
