/*
EduFPGA_GPU FPGA Top Module
---------------------------------------------
This is the top-level module for the EduGPU FPGA system,
which integrates the following components:
- PCIe interface and TLP packet decoder/encoder
- EduGPU graphics processing module
- LCD controller for display output
- System clock and reset management

Designed by NISHIHARU for educational and experimental purposes.
*/

//`define RTLSIM
//`define DUMPFILE
//`define LCD_LESS

module EduFPGA_top (
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

`ifdef RTLSIM
wire [255:0]    tl_rx_data;
assign  tl_rx_data   = {data_7, data_6, data_5, data_4, data_3, data_2, data_1, data_0};
assign  pcie_tx_data = tl_tx_data[159:128];
`endif

`ifdef DUMPFILE    
initial begin
    $dumpfile("waveform.vcd");  // VCDファイルの名前を指定
    $dumpvars(1, EduGraphics_FPGA_top);  // ダンプする階層を指定
    $dumpvars(1, EduGraphics_FPGA_top.mpcie_tlp_packet_dec);  // ダンプする階層を指定
    $dumpvars(1, EduGraphics_FPGA_top.mpcie_tlp_packet_enc);  // ダンプする階層を指定
    $dumpvars(1, EduGraphics_FPGA_top.mEduGPU_module);  // ダンプする階層を指定
    $dumpvars(0, EduGraphics_FPGA_top.mEduGPU_module.mEduGraGPU.mgpu);  // ダンプする階層を指定
    $dumpvars(1, EduGraphics_FPGA_top.mEduGPU_module.mEduGraGPU_Memory);  // ダンプする階層を指定
end
`endif

wire [7:0]  frame_state;


// Reset generate
localparam PCIE_DLY = 8;    //25~500ms
localparam SYS_RST_DLY = 10;
reg [26:0]  pcie_st_cnt = 0;
reg [SYS_RST_DLY:0] sys_rst_cnt = 0;

wire w_rst_n = rst_n & pcie_rstn;
wire pcie_start;
wire tlp_rst = !pcie_start;

// PCIE Start Delay 
always @ (posedge tlp_clk or negedge w_rst_n)
    if (!w_rst_n)                       
        sys_rst_cnt <= 0;
    else if (!sys_rst_cnt[SYS_RST_DLY]) 
        sys_rst_cnt <= sys_rst_cnt + 2'd1;

wire rstn = sys_rst_cnt[SYS_RST_DLY];

//
always @ (posedge tlp_clk or negedge rstn)
    if (!rstn)              
        pcie_st_cnt <= 0;
    else if (!pcie_start)   
        pcie_st_cnt <= pcie_st_cnt+2'd1;

assign pcie_start = pcie_st_cnt[PCIE_DLY]?1'b1:1'b0;

`ifndef RTLSIM
//leds
// 0 -> light 
assign  led[0]  = ~(sw_rstn & rst_n & pcie_rstn);
assign  led[1]  = ~tlp_rst;
assign  led[2]  = free_led_cnt[LED_RST_DLY];
assign  led[3]  = tl_rx_sop | tl_rx_eop;
assign  led[4]  = ~pcie_linkup;
assign  led[5]  = ~ltssm_status[2];
assign  led[6]  = ~ltssm_status[1];
assign  led[7]  = ~ltssm_status[0];

//assign  led[6:0]     = ~frame_state[6:0];
//assign  led[7] = sw_rstn;
//assign  led     = 8'b0101_0101;

localparam LED_RST_DLY = 24;
reg     [LED_RST_DLY:0] free_led_cnt = 0;

always @ (posedge tlp_clk) begin
    free_led_cnt <= free_led_cnt + 2'd1;
end

// CLOCK input
Gowin_PLL u_pll(
.clkout0   ( pll_100m_clk   ),  // 100MHz
.clkout1   ( pll_200m_clk   ),  // 200MHz
.clkout2   ( gpu_clk        ),  // 20MHz
.clkout3   ( clk_10MHz      ),  // 10MHz
.clkin     ( clk            )   // 50MHz
);

wire sys_clk;
assign sys_clk = pll_200m_clk;

CLKDIV #(
    .DIV_MODE("2")
    )uut_div2 (
    div_clk, 
    'b0, 
    sys_clk, 
    'b1
);

assign tlp_clk = div_clk;

// PCIe IPコアのインスタンス化
//debug
wire [31:0]    data_7;
wire [31:0]    data_6;
wire [31:0]    data_5;
wire [31:0]    data_4;
wire [31:0]    data_3;
wire [31:0]    data_2;
wire [31:0]    data_1;
wire [31:0]    data_0;

assign  data_7 = tl_rx_data[255:224];
assign  data_6 = tl_rx_data[223:192];
assign  data_5 = tl_rx_data[191:160];
assign  data_4 = tl_rx_data[159:128];
assign  data_3 = tl_rx_data[127:96];
assign  data_2 = tl_rx_data[95:64];
assign  data_1 = tl_rx_data[63:32];
assign  data_0 = tl_rx_data[31:0];

wire            tl_rx_sop, tl_rx_eop;
wire [255:0]    tl_rx_data;
wire [7:0]      tl_rx_valid;
wire [5:0]      tl_bardec;
wire [7:0]      nc_rx_err;
wire            tl_tx_wait;
wire [4:0]      ltssm_status;
wire [31:0]     tl_tx_p_credits;
wire [31:0]     tl_tx_np_credits;
wire [31:0]     tl_tx_cpl_credits;
wire [12:0]     tl_cfg_busdev;
wire            pcie_linkup;

wire            tl_tx_sop;
wire            tl_tx_eop;
wire [255:0]    tl_tx_data;
wire [7:0]      tl_tx_valid;

//##########################################################################################
// PCIE IP
SerDes_Top mSerDes_Top (
    // RXポート
    .PCIE_Controller_Top_pcie_tl_rx_sop_o       (tl_rx_sop  ), 
    .PCIE_Controller_Top_pcie_tl_rx_eop_o       (tl_rx_eop  ), 
    .PCIE_Controller_Top_pcie_tl_rx_data_o      (tl_rx_data ), 
    .PCIE_Controller_Top_pcie_tl_rx_valid_o     (tl_rx_valid), 
    .PCIE_Controller_Top_pcie_tl_rx_bardec_o    (tl_bardec  ), 
    .PCIE_Controller_Top_pcie_tl_rx_err_o       (nc_rx_err  ), 
    //
    .PCIE_Controller_Top_pcie_tl_tx_wait_o      (tl_tx_wait     ), 
    .PCIE_Controller_Top_pcie_ltssm_o           (ltssm_status   ), 
    .PCIE_Controller_Top_pcie_tl_tx_creditsp_o  (tl_tx_p_credits), 
    .PCIE_Controller_Top_pcie_tl_tx_creditsnp_o (tl_tx_np_credits), 
    .PCIE_Controller_Top_pcie_tl_tx_creditscpl_o(tl_tx_cpl_credits), 
    .PCIE_Controller_Top_pcie_tl_cfg_busdev_o   (tl_cfg_busdev  ), 
    .PCIE_Controller_Top_pcie_linkup_o          (pcie_linkup    ), 
    // 入力ポート
    .PCIE_Controller_Top_pcie_rstn_i            (pcie_rstn      ),
    .PCIE_Controller_Top_pcie_tl_clk_i          (tlp_clk        ), 
    .PCIE_Controller_Top_pcie_tl_rx_wait_i      (1'b0), 
    .PCIE_Controller_Top_pcie_tl_rx_masknp_i    (1'b0),
    // TXポート
    .PCIE_Controller_Top_pcie_tl_tx_sop_i       (tl_tx_sop      ), 
    .PCIE_Controller_Top_pcie_tl_tx_eop_i       (tl_tx_eop      ), 
    .PCIE_Controller_Top_pcie_tl_tx_data_i      (tl_tx_data     ), 
    .PCIE_Controller_Top_pcie_tl_tx_valid_i     (tl_tx_valid    )
);
`else
`endif
//##########################################################################################
// PCIE Packet Controler
wire            is_read_request, is_write_request;
wire [11:0]     byte_cnt;
wire [15:0]     write_addr;
wire [31:0]     write_data;
wire [31:0]     read_addr;
wire [7:0]      tag;
wire [3:0]      bit_enable;
wire [15:0]     RequesterID;

wire            mem_read_req;
wire [15:0]     mem_read_addr;
wire [31:0]     mem_read_data;

pcie_tlp_packet_dec mpcie_tlp_packet_dec(
    .clk                    (tlp_clk),
    .rstn                   (rst_n),
    .tlp_header             (tl_rx_data),            // TLPヘッダー（128ビット）
    .rx_sop                 (tl_rx_sop),
    .rx_eop                 (tl_rx_eop),
    .is_read_request        (is_read_request),     // リードリクエストであることを示すフラグ
    .pcie_read_ready        (pcie_read_ready),
    .is_write_request       (is_write_request),    // ライトリクエストであることを示すフラグ
    .pcie_write_ready       (pcie_write_ready),
    .byte_cnt               (byte_cnt),
    .write_addr             (write_addr),
    .write_data             (write_data),
    .read_addr              (read_addr[15:0]),
    .bit_enable             (bit_enable),
    .RequesterID            (RequesterID),
    .tag                    (tag)
);

pcie_tlp_packet_enc mpcie_tlp_packet_enc(
    .clk                    (tlp_clk),
    .rstn                   (rst_n),
    .tl_tx_wait             (tl_tx_wait),
    .read_req               (is_read_request),
    .read_addr              (read_addr[15:0]),
    .bit_enable             (bit_enable),
    .tag                    (tag),
    .RequesterID            (RequesterID),
    // for Memory
    .mem_read_req           (mem_read_req),
    .pcie_read_ready        (pcie_read_ready),
    .mem_read_addr          (mem_read_addr),
    .mem_read_data          (mem_read_data),
    // for PCIE controler
    .tx_sop                 (tl_tx_sop),
    .tx_eop                 (tl_tx_eop),
    .tx_data                (tl_tx_data),
    .tl_tx_valid            (tl_tx_valid)        
);


//##########################################################################################
// EduGrapchics GPU
EduFPGA_GPU_module  #(
    .MEM_DATA_WIDTH(32),
    .MEM_ADDR_WIDTH(16)
    ) mEduGPU_module(
    .clock                          (tlp_clk),
    .gpu_clock                      (gpu_clk),
    .reset_n                        (rst_n),
    // GPU
    .gpu_start                      (gpu_start),
    .gpu_done                       (gpu_done),
    // PCIE port
    .pcie_read_request              (mem_read_req),
    .pcie_read_addr                 (mem_read_addr),
    .pcie_read_ready                (pcie_read_ready),
    .pcie_write_request             (is_write_request),
    .pcie_write_addr                (write_addr),
    .pcie_write_data                (write_data), 
    .pcie_write_ready               (pcie_write_ready),
    .pcie_read_data                 (mem_read_data)
);

//##########################################################################################
// LCD Controler
`ifdef LCD_LESS
`else

wire LCD_SDA_Read;
wire LCD_SDA_out;
assign LCD_SDA = (~LCD_SDA_Read)? LCD_SDA_out : 1'bz;

wire [15:0] H_pos, V_pos;

EduFPGA_LCD_Controller mLCD_Controller(
    .clk_10MHz                      (clk_10MHz),            // システムクロック (10MHz)
    .rst_n                          (rst_n),                // アクティブローリセット
    .sw_rstn                        (sw_rstn),              // スイッチリセット信号（例）
    .LCD_CSX                        (LCD_CSX),
    .LCD_DC                         (LCD_DC),
    .LCD_SDA_out                    (LCD_SDA_out),
    .LCD_SCK                        (LCD_SCK),
    .SDA_Read                       (LCD_SDA_Read),
    .LCD_RSTX                       (LCD_RSTX),
    .H_pos                          (H_pos),               // 横位置カウンタ（0〜159）
    .V_pos                          (V_pos),               // 縦位置カウンタ（0〜79）
    .frame_state_out                (frame_state)
);
`endif

// 不使用ピンの設定
assign LCD_NC1 = 0;
assign LCD_NC2 = 0;
assign LCD_NC3 = 0;

endmodule
