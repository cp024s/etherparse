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

  // Header completion
  input  logic header_done,

  // Control outputs
  output logic frame_start,
  output logic frame_end,
  output logic in_header,
  output logic in_payload
);

  typedef enum logic [1:0] {
    IDLE,
    HEADER,
    PAYLOAD
  } state_t;

  state_t state, state_n;

  // ------------------------------------------------------------
  // Combinational next-state logic
  // ------------------------------------------------------------
  always_comb begin
    state_n = state;

    case (state)
      IDLE: begin
        if (beat_accept)
          state_n = HEADER;
      end

      HEADER: begin
        if (beat_accept && header_done)
          state_n = PAYLOAD;
      end

      PAYLOAD: begin
        if (beat_accept && tlast)
          state_n = IDLE;
      end

      default: state_n = IDLE;
    endcase
  end

  // ------------------------------------------------------------
  // Sequential state register
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= state_n;
  end

  // ------------------------------------------------------------
  // Output logic (registered, deterministic)
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_start <= 1'b0;
      frame_end   <= 1'b0;
      in_header   <= 1'b0;
      in_payload  <= 1'b0;
    end
    else begin
      // defaults
      frame_start <= 1'b0;
      frame_end   <= 1'b0;

      case (state)
        IDLE: begin
          in_header  <= 1'b0;
          in_payload <= 1'b0;

          if (beat_accept)
            frame_start <= 1'b1;
        end

        HEADER: begin
          in_header  <= 1'b1;
          in_payload <= 1'b0;
        end

        PAYLOAD: begin
          in_header  <= 1'b0;
          in_payload <= 1'b1;

          if (beat_accept && tlast)
            frame_end <= 1'b1;
        end

        default: begin
          in_header  <= 1'b0;
          in_payload <= 1'b0;
        end
      endcase
    end
  end

`ifndef SYNTHESIS
  // ------------------------------------------------------------
  // Assertions (Verilator-safe, meaningful)
  // ------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst_n) begin
      // frame_start only allowed from IDLE
      if (frame_start)
        assert (state == IDLE)
          else $fatal("FSM: frame_start asserted outside IDLE");

      // frame_end only allowed in PAYLOAD with tlast
      if (frame_end)
        assert (state == PAYLOAD && tlast)
          else $fatal("FSM: frame_end without PAYLOAD+tlast");

      // in_header and in_payload must never overlap
      assert (!(in_header && in_payload))
        else $fatal("FSM: in_header and in_payload both high");
    end
  end
`endif

endmodule
