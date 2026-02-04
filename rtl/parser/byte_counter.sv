// ============================================================
// Module: byte_counter
// Purpose:
//  - Count bytes consumed per frame
//  - Assert header_done exactly once
// ============================================================
// ============================================================
// Module: byte_counter
// Purpose: Count header bytes and pulse header_done ONCE
// ============================================================

module byte_counter #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 14
)(
  input  logic clk,
  input  logic rst_n,

  input  logic beat_accept,
  input  logic frame_start,

  output logic header_done
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;

  int unsigned byte_count;
  logic         header_done_seen;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count       <= 0;
      header_done      <= 1'b0;
      header_done_seen <= 1'b0;
    end else begin
      header_done <= 1'b0; // DEFAULT: pulse only

      if (frame_start) begin
        byte_count       <= 0;
        header_done_seen <= 1'b0;
      end
      else if (beat_accept && !header_done_seen) begin
        if (byte_count + BYTES_PER_BEAT >= HEADER_BYTES) begin
          header_done      <= 1'b1;   // ONE-CYCLE PULSE
          header_done_seen <= 1'b1;   // LOCK IT OUT
        end
        byte_count <= byte_count + BYTES_PER_BEAT;
      end
    end
  end

endmodule
