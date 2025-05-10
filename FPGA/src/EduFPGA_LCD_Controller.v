`timescale 1ns / 1ps

module EduFPGA_LCD_Controller (
    input wire clk_10MHz,            // システムクロック (10MHz)
    input wire rst_n,                // アクティブローリセット
    input wire sw_rstn,              // スイッチリセット信号（例）
    // SPI出力
    output wire LCD_CSX,
    output wire LCD_DC,
    output wire LCD_SDA_out,
    output wire LCD_SCK,
    output wire SDA_Read,
    // リセット出力
    output wire LCD_RSTX,
    // カウンタ
    output reg [15:0] H_pos,          // 横位置カウンタ（0〜159）
    output reg [15:0] V_pos,          // 縦位置カウンタ（0〜79）
    output wire [7:0] frame_state_out
);

    //##########################################################################################
    // LCD controller
    // LCD : 160x80 pixel

    spi_lcd_controller lcd_controller (
        .clk            (clk_10MHz),
        .rst_n          (rst_n),
        .sw_rstn        (sw_rstn),
        .LCD_CSX        (LCD_CSX),
        .LCD_DC         (LCD_DC),
        .LCD_SDA        (LCD_SDA_out),
        .LCD_SCK        (LCD_SCK),
        .SDA_Read       (LCD_SDA_Read),
        .LCD_RSTX       (LCD_RSTX),
        .H_pos          (H_pos),
        .V_pos          (V_pos),
        .cmd_num_out    (cmd_num_out),
        .frame_state_out(frame_state_out)
    );

endmodule
