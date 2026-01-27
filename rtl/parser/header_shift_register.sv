// ============================================================
// Module: header_shift_register
// Purpose: Capture first 18 bytes of Ethernet frame
//          LSB-first (AXI-compliant)
// ============================================================
`timescale 1ns/1ps

module header_shift_register #(
  parameter int DATA_WIDTH   = 64,
  parameter int HEADER_BYTES = 18
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  beat_accept,
  input  logic                  frame_start,
  input  logic [DATA_WIDTH-1:0] axis_tdata,

  output logic [HEADER_BYTES-1:0][7:0] header_bytes,
  output logic                         header_valid
);

  // ------------------------------------------------------------
  // Local parameters (STRONGLY TYPED)  
  // ------------------------------------------------------------
  localparam int BYTES_PER_BEAT = DATA_WIDTH / 8;
  localparam int COUNT_WIDTH    = $clog2(HEADER_BYTES + 1);

  localparam logic [COUNT_WIDTH-1:0] HEADER_BYTES_C =
    COUNT_WIDTH'(HEADER_BYTES);

  localparam logic [COUNT_WIDTH-1:0] BYTES_PER_BEAT_C =
    COUNT_WIDTH'(BYTES_PER_BEAT);

  // ------------------------------------------------------------
  // State
  // ------------------------------------------------------------
  logic [COUNT_WIDTH-1:0] byte_count;
  //logic [COUNT_WIDTH-1:0] next_count;

  // ------------------------------------------------------------
  // Sequential logic
  // ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    byte_count   <= '0;
    header_bytes <= '0;
    header_valid <= 1'b0;
  end
  else begin
    header_valid <= 1'b0;

    if (frame_start) begin
      byte_count   <= '0;
      header_bytes <= '0;
    end
    else if (beat_accept && byte_count < HEADER_BYTES_C) begin
      logic [COUNT_WIDTH-1:0] next_count;  // automatic variable
      next_count = byte_count;

      for (int i = 0; i < BYTES_PER_BEAT; i++) begin
        if (next_count < HEADER_BYTES_C) begin
          header_bytes[next_count]
            <= axis_tdata[i*8 +: 8];
          next_count = next_count + COUNT_WIDTH'(1);
        end
      end

      byte_count <= next_count;

      if (next_count == HEADER_BYTES_C)
        header_valid <= 1'b1;
    end
  end
end


endmodule
