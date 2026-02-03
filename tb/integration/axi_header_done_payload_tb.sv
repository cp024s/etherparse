`timescale 1ns/1ps
import eth_parser_pkg::*;

module axi_header_done_payload_tb;

  localparam int DATA_WIDTH = 64;

  logic clk;
  logic rst_n;

  logic [DATA_WIDTH-1:0] s_axis_tdata;
  logic                  s_axis_tvalid;
  logic                  s_axis_tready;
  logic                  s_axis_tlast;

  logic [DATA_WIDTH-1:0] m_axis_tdata;
  logic                  m_axis_tvalid;
  logic                  m_axis_tready;
  logic                  m_axis_tlast;

  eth_metadata_t         m_axis_tuser;
  logic                  m_axis_tuser_valid;

  // Clock
  always #5 clk = ~clk;

  ethernet_frame_parser dut (
    .clk,
    .rst_n,

    .s_axis_tdata,
    .s_axis_tvalid,
    .s_axis_tready,
    .s_axis_tlast,

    .m_axis_tdata,
    .m_axis_tvalid,
    .m_axis_tready,
    .m_axis_tlast,

    .m_axis_tuser,
    .m_axis_tuser_valid
  );

  // Drive
  task send_beat(input [63:0] data, input bit last);
    begin
      @(posedge clk);
      s_axis_tdata  <= data;
      s_axis_tvalid <= 1'b1;
      s_axis_tlast  <= last;
      while (!s_axis_tready) @(posedge clk);
      @(posedge clk);
      s_axis_tvalid <= 1'b0;
      s_axis_tlast  <= 1'b0;
    end
  endtask

  initial begin
    clk = 0;
    rst_n = 0;
    s_axis_tvalid = 0;
    m_axis_tready = 1;

    repeat (5) @(posedge clk);
    rst_n = 1;

    $display("=== Sending header + payload frame ===");

    send_beat(64'h1122334455667788, 0);
    send_beat(64'h99aabbccddeeff00, 0);
    send_beat(64'h0800450000000000, 0);
    send_beat(64'hdeadbeefdeadbeef, 0);
    send_beat(64'hcafebabecafebabe, 1);

    repeat (20) @(posedge clk);
    $display("=== TEST DONE ===");
    $finish;
  end

  // RX monitor
  always @(posedge clk) begin
    if (m_axis_tvalid && m_axis_tready) begin
      $display("[%0t] RX: data=%h last=%b", $time, m_axis_tdata, m_axis_tlast);
      if (m_axis_tlast)
        $display("---- RX FRAME END ----");
    end
  end

  // Metadata monitor
  always @(posedge clk) begin
    if (m_axis_tuser_valid) begin
      $display("[META] ethertype=%h vlan=%0d ipv4=%0b",
               m_axis_tuser.ethertype,
               m_axis_tuser.vlan_id,
               m_axis_tuser.is_ipv4);
    end
  end

  always @(posedge clk) begin
  if (m_axis_tuser_valid) begin
    $display(
      "[META] dst=%h src=%h ethertype=%h vlan=%0d ipv4=%0d",
      m_axis_tuser.dest_mac,
      m_axis_tuser.src_mac,
      m_axis_tuser.resolved_ethertype,
      m_axis_tuser.vlan_id,
      m_axis_tuser.is_ipv4
    );
  end
end


endmodule
