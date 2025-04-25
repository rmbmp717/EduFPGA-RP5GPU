/*
 * NISHIHARU
 *
 * pcie_tlp_packet_dec
 *
 * This module decodes TLP headers for PCIe read/write requests.
 */

module pcie_tlp_packet_dec (
    input               clk,
    input               rstn,
    // 256-bit TLP header input
    input wire [255:0]  tlp_header,
    // Start/End Of Packet signals
    input               rx_sop,
    input               rx_eop,
    // Read/Write request outputs
    output wire         is_read_request,
    input  wire         pcie_read_ready,
    output wire         is_write_request,
    input  wire         pcie_write_ready,
    // Decoded fields
    output reg [11:0]   byte_cnt,
    output reg [15:0]   write_addr,
    output reg [31:0]   write_data,
    output reg [15:0]   read_addr,
    output reg [3:0]    bit_enable,
    output reg [15:0]   RequesterID,
    output reg [7:0]    tag
);
