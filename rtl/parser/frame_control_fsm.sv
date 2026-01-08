// ============================================================
// Module: frame_control_fsm
// Purpose: Frame lifecycle control for Ethernet frame parser
// ============================================================

`timescale 1ns/1ps

module frame_control_fsm (
  input  logic clk,
  input  logic rst_n,

  // AXI handshake indicators
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
  // State definition
  // ----------------------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    IN_HEADER,
    IN_PAYLOAD,
    END_FRAME
  } state_t;

  state_t state, state_n;

  // ----------------------------------------------------------
  // State register
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= state_n;
  end

  // ----------------------------------------------------------
  // Next-state logic
  // ----------------------------------------------------------
  always_comb begin
    state_n = state;

    case (state)
      IDLE: begin
        if (beat_accept)
          state_n = IN_HEADER;
      end

      IN_HEADER: begin
        if (beat_accept && tlast)
          state_n = END_FRAME;
        else if (beat_accept && header_done)
          state_n = IN_PAYLOAD;
      end

      IN_PAYLOAD: begin
        if (beat_accept && tlast)
          state_n = END_FRAME;
      end

      END_FRAME: begin
        state_n = IDLE;
      end

      default: state_n = IDLE;
    endcase
  end

  // ----------------------------------------------------------
  // Output logic
  // ----------------------------------------------------------
  always_comb begin
    // Defaults
    frame_start = 1'b0;
    frame_end   = 1'b0;
    in_header   = 1'b0;
    in_payload  = 1'b0;

    case (state)
      IDLE: begin
        if (beat_accept)
          frame_start = 1'b1;
      end

      IN_HEADER: begin
        in_header = 1'b1;
      end

      IN_PAYLOAD: begin
        in_payload = 1'b1;
      end

      END_FRAME: begin
        frame_end = 1'b1;
      end
    endcase
  end

endmodule
