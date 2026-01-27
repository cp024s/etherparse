`timescale 1ns/1ps

module byte_counter #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 18
)(
  input  logic clk,
  input  logic rst_n,

  // Control
  input  logic beat_accept,   // asserted when a data beat is consumed
  input  logic frame_start,   // single-cycle pulse at start of frame

  // Status
  output logic in_header,     // high while counting header bytes
  output logic header_done    // single-cycle pulse when header completes
);

  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;
  localparam int COUNT_WIDTH   = $clog2(HEADER_BYTES + BYTES_PER_BEAT);

  logic [COUNT_WIDTH-1:0] byte_count;
  logic [COUNT_WIDTH-1:0] next_count;

  // ----------------------------------------------------------
  // Combinational next-count logic
  // ----------------------------------------------------------
  always_comb begin
    next_count = byte_count;
    if (beat_accept && in_header)
      next_count = byte_count + COUNT_WIDTH'(BYTES_PER_BEAT);
  end

  // ----------------------------------------------------------
  // Sequential logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_count  <= '0;
      in_header   <= 1'b0;
      header_done <= 1'b0;
    end
    else begin
      header_done <= 1'b0; // default: pulse

      if (frame_start) begin
        byte_count <= '0;
        in_header  <= 1'b1;
      end
      else if (beat_accept && in_header) begin
        if (next_count >= COUNT_WIDTH'(HEADER_BYTES)) begin
          byte_count  <= byte_count;
          in_header   <= 1'b0;
          header_done <= 1'b1;
        end
        else begin
          byte_count <= next_count;
        end
      end
    end
  end

`ifndef SYNTHESIS
  // ----------------------------------------------------------
  // Minimal correctness assertions (Verilator-safe)
  // ----------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst_n) begin
      // header_done must never be asserted while in_header is high
      if (header_done)
        assert (!in_header)
          else $fatal("BYTE_COUNTER: header_done asserted while in_header");

      // header_done must only occur on beat_accept
      if (header_done)
        assert (beat_accept)
          else $fatal("BYTE_COUNTER: header_done without beat_accept");
    end
  end
`endif

endmodule
