/*
EduGraphics FPGA TOP file
NISHIHARU
Default option
-top work.PMOD_LCD_top_dsimtest -L dut +acc+b -waves wave.vcd
*/
`timescale 1ns / 1ns
module EduGraphics_GPU_FPGA_top_dsimtest ();

`define RTLSIM

reg clk_100MHz = 0;
reg clk_20MHz = 0;
reg rst_n;
reg sw_rstn = 1;
reg pcie_rstn = 0;
integer error_cnt = 0;

wire   tlp_clk;
assign tlp_clk = clk_100MHz;

reg tl_rx_sop = 0;
reg tl_rx_eop = 0;

reg [31:0] data_7 = 0;
reg [31:0] data_6 = 0;
reg [31:0] data_5 = 0;
reg [31:0] data_4 = 0;
reg [31:0] data_3 = 0;
reg [31:0] data_2 = 0;
reg [31:0] data_1 = 0;
reg [31:0] data_0 = 0;

EduGraphics_FPGA_top mEduGraphics_FPGA_top(
    .clk                (0),
    .rst_n              (rst_n), 
    .pcie_rstn          (pcie_rstn),
    .sw_rstn            (sw_rstn),
    .led                (),
    .LCD_RSTX           (),
    .LCD_CSX            (),
    .LCD_DC             (),
    .LCD_SDA            (),            // SDA : inout
    .LCD_SCK            (),
    .LCD_NC1            (), 
    .LCD_NC2            (), 
    .LCD_NC3            (),

    .tlp_clk            (tlp_clk),
    .gpu_clk            (clk_20MHz),
    .tl_rx_sop          (tl_rx_sop), 
    .tl_rx_eop          (tl_rx_eop),
    .data_7             (data_7),
    .data_6             (data_6),
    .data_5             (data_5),
    .data_4             (data_4),
    .data_3             (data_3),
    .data_2             (data_2),
    .data_1             (data_1),
    .data_0             (data_0),
    .tl_tx_wait         (0),
    .tl_tx_sop          (), 
    .tl_tx_eop          (),
    .tl_tx_data         (),
    .tl_tx_valid        (),
    .pcie_tx_data       ()
);

//##########################################################################################
// 100MHzの生成
initial begin
    forever begin
        #5;
        clk_100MHz = 1;
        #5;
        clk_100MHz = 0;
    end
end

// 20MHzの生成
initial begin
    forever begin
        #25;
        clk_20MHz = 1;
        #25;
        clk_20MHz = 0;
    end
end

// 任意のクロック数を待つtaskの定義
task wait_cycles(input integer num_cycles);
    integer i;
    begin
        for (i = 0; i < num_cycles; i = i + 1) begin
            @(posedge clk_100MHz); // クロックの立ち上がりを待つ
        end
    end
endtask

// PCIEもどきのタスク
// Write
task pcie_write(input [31:0] addr, input [31:0] data);
    integer tag;
    integer i;
    begin
        // 開始信号を設定
        tl_rx_sop = 1;
        tl_rx_eop = 1;

        // タグを生成（0から8の範囲）
        tag = 4;
        
        // データ信号を設定
        data_7 = (8'b010_00000 << 24) | 32'h0000;
        data_6 = (tag << 8) | 8'b0000_1111;
        data_5 = addr;
        data_4 = data;

        // 1クロック待機
        @(posedge tlp_clk);
        
        // 終了信号をリセット
        tl_rx_sop = 0;
        tl_rx_eop = 0;
        data_7 = 0;
        data_6 = 0;
        data_5 = 0;
        data_4 = 0;

        // 指定されたクロック数待機（ここでは10クロック）
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge tlp_clk);
        end
    end
endtask

// Read
task pcie_read(input [31:0] addr);
    integer tag;
    integer i;
    begin
        // 開始信号を設定
        tl_rx_sop = 1;
        tl_rx_eop = 1;

        // タグを生成（0から8の範囲）
        tag = 4;
        
        // データ信号を設定
        data_7 = (8'b000_00000 << 24) | 32'h0000;
        data_6 = (tag << 8) | 8'b0000_1111;
        data_5 = addr;
        data_4 = 0;

        // 1クロック待機
        @(posedge tlp_clk);
        
        // 終了信号をリセット
        tl_rx_sop = 0;
        tl_rx_eop = 0;
        data_7 = 0;
        data_6 = 0;
        data_5 = 0;
        data_4 = 0;

        // 指定されたクロック数待機（ここでは10クロック）
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge tlp_clk);
        end
    end
endtask

//##########################################################################################
// シミュレーションスタート
initial begin
    rst_n = 0;
    pcie_rstn = 0;
    #100
    rst_n = 1;
    #100
    pcie_rstn = 1;
    #100000
    pcie_rstn = 0;

    wait_cycles(1000);

    pcie_write(32'hF800, 32'h00000002);
    wait_cycles(100);

    pcie_write(32'hF800, 32'h00000001);
    wait_cycles(100);

    pcie_write(32'hF400, 32'h00000004);
    wait_cycles(100);

    pcie_write(32'h0014, 32'h03020203);
    wait_cycles(100);

    pcie_write(32'hF800, 32'h00000100);
    wait_cycles(100);

    pcie_write(32'hF800, 32'h00000000);
    wait_cycles(100);

    pcie_read(32'hF800);
    wait_cycles(100);

    // XXXクロック待つ
    wait_cycles(10000);

    $display("finish");
    $finish();
end

endmodule
