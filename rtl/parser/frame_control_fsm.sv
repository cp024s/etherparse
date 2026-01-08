// ============================================================
// Module: frame_control_fsm
// Purpose: Frame lifecycle control (deadlock-safe)
// ============================================================

`timescale 1ns/1ps

module frame_control_fsm (
  input  logic clk,
  input  logic rst_n,

  // AXI handshake
  input  logic beat_accept,
  input  logic tlast,

  // Header completion (from byte_counter)
  input  logic header_done,

  // Control outputs
  output logic frame_start,
  output logic frame_end,
  output logic in_header,
  output logic in_payload
);

  // ----------------------------------------------------------
  // State encoding
  // ----------------------------------------------------------
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_HEADER,
    ST_PAYLOAD
  } state_t;

  state_t state, state_n;

  // ----------------------------------------------------------
  // State register
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= ST_IDLE;
    else
      state <= state_n;
  end

  // ----------------------------------------------------------
  // Next-state logic (PURELY REACTIVE)
  // ----------------------------------------------------------
  always_comb begin
    state_n = state;

    case (state)
      ST_IDLE: begin
        if (beat_accept)
          state_n = ST_HEADER;
      end

      ST_HEADER: begin
        if (beat_accept && tlast)
          state_n = ST_IDLE;
        else if (beat_accept && header_done)
          state_n = ST_PAYLOAD;
      end

      ST_PAYLOAD: begin
        if (beat_accept && tlast)
          state_n = ST_IDLE;
      end

      default: state_n = ST_IDLE;
    endcase
  end

  // ----------------------------------------------------------
  // Output logic (Moore-style, NO gating)
  // ----------------------------------------------------------
  always_comb begin
    frame_start = 1'b0;
    frame_end   = 1'b0;
    in_header   = 1'b0;
    in_payload  = 1'b0;

    case (state)
      ST_IDLE: begin
        if (beat_accept)
          frame_start = 1'b1;
      end

      ST_HEADER: begin
        in_header = 1'b1;
      end

      ST_PAYLOAD: begin
        in_payload = 1'b1;
      end
    endcase

    // Frame end is event-based, not state-based
    if (beat_accept && tlast)
      frame_end = 1'b1;
  end

endmodule
