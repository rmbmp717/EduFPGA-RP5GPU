/*
 * NISHIHARU
 *
 * pcie_tlp_packet_enc
 * 
 * This module encodes TLP packets for PCIe read operations.
 */

module pcie_tlp_packet_enc (
    input               clk,
    input               rstn,

    // Control signals
    input               tl_tx_wait,
    input               read_req,
    input  [15:0]       read_addr,
    input  [3:0]        bit_enable,
    input  [7:0]        tag,
    input  [15:0]       RequesterID,
    output reg          mem_read_req,
    input               pcie_read_ready,

    // Memory interface
    output wire [15:0]  mem_read_addr,
    input  [31:0]       mem_read_data,

    // PCIe TX interface
    output reg          tx_sop,
    output reg          tx_eop,
    output wire [255:0] tx_data,
    output reg [7:0]    tl_tx_valid
);
