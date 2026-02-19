// ============================================================
// Module: frame_control_fsm
// Purpose:
//  - Define frame lifecycle
//  - HEADER → PAYLOAD transition controlled ONLY by header_done
// ============================================================

`timescale 1ns/1ps

module frame_control_fsm (
  input  logic clk,
  input  logic rst_n,

  input  logic beat_accept,
  input  logic tlast,
  input  logic header_done,

  output logic frame_start,
  output logic frame_end,
  output logic in_header,
  output logic in_payload
);

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_HEADER,
    ST_PAYLOAD
  } state_t;

  state_t state, next_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= ST_IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    next_state  = state;
    frame_start = 1'b0;
    frame_end   = 1'b0;

    case (state)
      ST_IDLE: begin
        if (beat_accept) begin
          frame_start = 1'b1;
          next_state  = ST_HEADER;
        end
      end

      ST_HEADER: begin
        if (beat_accept && header_done)
          next_state = ST_PAYLOAD;
      end

      ST_PAYLOAD: begin
        if (beat_accept && tlast) begin
          frame_end  = 1'b1;
          next_state = ST_IDLE;
        end
      end
    endcase
  end

  assign in_header  = (state == ST_HEADER);
  assign in_payload = (state == ST_PAYLOAD);

endmodule
