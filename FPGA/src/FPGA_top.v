/*
EduGraphics FPGA TOP file
NISHIHARU
*/
//`define RTLSIM
//`define DUMPFILE
`define LCD_LESS

module EduGraphics_FPGA_top (
    input wire          clk,
    input wire          rst_n, 
    input wire          pcie_rstn,
    input wire          sw_rstn,
    output wire [7:0]   led,
    output wire         LCD_RSTX,
    output wire         LCD_CSX,
    output wire         LCD_DC,
    inout  wire         LCD_SDA,            // SDA : inout
    output wire         LCD_SCK,
    output wire         LCD_NC1, 
    output wire         LCD_NC2, 
    output wire         LCD_NC3
    `ifdef RTLSIM
    ,input wire          tlp_clk,
    input wire          gpu_clk,
    input wire          tl_rx_sop, 
    input wire          tl_rx_eop,
    input wire [31:0]   data_7,
    input wire [31:0]   data_6,
    input wire [31:0]   data_5,
    input wire [31:0]   data_4,
    input wire [31:0]   data_3,
    input wire [31:0]   data_2,
    input wire [31:0]   data_1,
    input wire [31:0]   data_0,
    input wire          tl_tx_wait,
    output wire         tl_tx_sop, 
    output wire         tl_tx_eop,
    output wire [255:0] tl_tx_data,
    output wire [7:0]   tl_tx_valid,
    output wire [31:0]  pcie_tx_data 
    `endif
);
