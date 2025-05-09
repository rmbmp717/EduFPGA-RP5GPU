`timescale 1ns / 1ps
//`define RTLSIM_RAM_OFF
module spi_lcd_controller (
    input wire clk,                  // システムクロック (10MHz)
    input wire rst_n,                // アクティブローリセット
    input wire sw_rstn,              // スイッチリセット信号（例）
    // SPI出力
    output wire LCD_CSX,
    output wire LCD_DC,
    output wire LCD_SDA,
    output wire LCD_SCK,
    output wire SDA_Read,
    // リセット出力
    output wire LCD_RSTX,
    // カウンタ
    output reg [15:0] H_pos,          // 横位置カウンタ（0〜159）
    output reg [15:0] V_pos,          // 縦位置カウンタ（0〜79）
    output wire [3:0] cmd_num_out,
    output wire [7:0] frame_state_out
);

localparam H_pos_end = 80;
localparam V_pos_end = 160;

assign LCD_RSTX = rst_n; // リセット信号

// 初期化ステートマシンからの出力
wire [7:0] cmd_spi_cmd;
wire [7:0] cmd_spi_data1;
wire [7:0] cmd_spi_data2;
wire [7:0] cmd_spi_data3;
wire [7:0] cmd_spi_data4;
wire [3:0] cmd_spi_data_num;
wire spi_start_cmd;
reg frame_end;
wire spi_read_mode;
wire init_done;

// SPI送信用の信号
reg [7:0] data_spi_cmd;
reg spi_start_data;
reg [3:0] cmd_num;
wire spi_busy;
reg cmd_start;
reg spi_read;
reg init_mode;
wire [3:0] spi_mode;
wire [3:0] init_spi_mode;
assign cmd_num_out = cmd_num[3:0];

// sw_rstnの代わりの信号
parameter CLK_FREQ = 10000000;    // システムクロック周波数（例: 10MHz）
parameter SW_FREQ  =     1000;    // SW周波数
localparam CLK_DIV = CLK_FREQ / (2 * SW_FREQ);

// クロック分周カウンタ
reg [31:0] clk_div_counter = 0;
reg sw_on_timer;

// クロック分周ロジック
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        clk_div_counter <= 0;
        sw_on_timer <= 0;
    end else begin
        if (clk_div_counter < CLK_DIV-1) begin
            clk_div_counter <= clk_div_counter + 1;
            sw_on_timer <= 0;
        end else begin
            clk_div_counter <= 0;
            sw_on_timer <= 1;
        end
    end
end

// ピクセルデータ
reg [15:0] current_pixel;
wire [2:0] dout;

reg [4:0]  red;
reg [5:0]  blue;
reg [4:0]  green;

wire [4:0] red_out; 
wire [5:0] blue_out;
wire [4:0] green_out;

`ifndef RTLSIM_RAM_OFF
// VIDEO Memory
Gowin_RAM16S mGowin_RAM16S(
    .dout(dout),                    //output [2:0] dout
    .di(4'd0),                      //input [2:0] di
    .ad(80*V_pos+H_pos),            //input [13:0] ad
    .wre(1'b0),                     //input wre
    .clk(clk)                       //input clk
);
`endif


assign red_out      = (dout[2])? 5'h1F : 0;
assign blue_out     = (dout[0])? 6'h3F : 0;
assign green_out    = (dout[1])? 5'h1F : 0;

always @(*) begin  
    red     <= red_out;
    blue    <= blue_out;
    green   <= green_out;
end

/*
assign red_out      = H_pos[4:1];
assign green_out    = H_pos[4:1];
assign blue_out     = H_pos[4:1];
*/

// SPI mode
assign spi_mode = (init_mode==2'd0)? init_spi_mode : 4'd2;

// SPIマスターインスタンス
spi_master spi_inst (
    .clk                (clk),
    .rst                (~rst_n),
    .start              (spi_start_cmd | spi_start_data),
    .frame_end          (frame_end),
    .read_mode          (spi_read_mode),
    .spi_mode           (spi_mode),
    .cmd_spi_cmd        (cmd_spi_cmd),       // cmd
    .cmd_spi_data1      (cmd_spi_data1),     // data1
    .cmd_spi_data2      (cmd_spi_data2),     // data2
    .cmd_spi_data3      (cmd_spi_data3),     // data3
    .cmd_spi_data4      (cmd_spi_data4),     // data4
    .cmd_spi_data_num   (cmd_spi_data_num),
    //.pixel_data         (current_pixel),
    //.pixel_data         ({{4'h7},{4'h0},{4'h0}}),           // RBG の順
    //.pixel_data         ({{red},{green},{blue}}),
    .pixel_data         ({{red},{blue},{green}}),
    .LCD_CSX            (LCD_CSX),
    .LCD_DC             (LCD_DC),
    .LCD_SCK            (LCD_SCK),
    .LCD_SDA            (LCD_SDA),
    .SDA_Read           (SDA_Read),
    .busy               (spi_busy)
);

// コマンド送信ブロック
spi_lcd_init init_inst (
    .clk                (clk),
    .rst_n              (rst_n),
    .cmd_start          (cmd_start),
    .cmd_num            (cmd_num),
    .spi_read           (spi_read),
    .spi_busy           (spi_busy),
    .spi_mode           (init_spi_mode),
    .cmd_spi_cmd        (cmd_spi_cmd),
    .cmd_spi_data1      (cmd_spi_data1),
    .cmd_spi_data2      (cmd_spi_data2),
    .cmd_spi_data3      (cmd_spi_data3),
    .cmd_spi_data4      (cmd_spi_data4),
    .cmd_spi_data_num   (cmd_spi_data_num),
    .spi_start_cmd      (spi_start_cmd),
    .spi_read_mode      (spi_read_mode),
    .init_done          (init_done)
);

// フレームデータ送信ステートマシン
localparam DISP_IDLE                    = 0,
           CMD_SEND                     = 1,
           CMD_SEND_AFTER_WAIT          = 2,
           CMD_SEND2                    = 3,
           CMD_SEND_AFTER_WAIT2         = 4,
           CMD_SEND3                    = 5,
           CMD_SEND_AFTER_WAIT3         = 6,
           CMD_SEND4                    = 7,
           CMD_SEND_AFTER_WAIT4         = 8,
           CMD_SEND5                    = 9,
           CMD_SEND_AFTER_WAIT5         = 10,
           CMD_SEND6                    = 11,
           CMD_SEND_AFTER_WAIT6         = 12,
           CMD_SEND7                    = 13,
           CMD_SEND_AFTER_WAIT7         = 14,
           CMD_SEND8                    = 15,
           CMD_SEND_AFTER_WAIT8         = 16,
           CMD_TO_DATA_WAIT             = 17,
           MEMORY_WRITE_MODE            = 18,
           MEMORY_WRITE_AFTER_WAIT5     = 19,
           FRAME_SEND_PIXEL_SET         = 20,
           FRAME_SEND_PIXEL             = 21,
           FRAME_SEND_PIXEL_WAIT        = 22,
           FRAME_DONE                   = 23;

reg [7:0] frame_state; // ステート変数
assign frame_state_out = frame_state;

// ピクセルデータ生成
always @(*) begin
    case (V_pos / 60)
        0: current_pixel = 12'hF00; // 赤
        1: current_pixel = 12'h0F0; // 緑
        2: current_pixel = 12'h00F; // 青
        3: current_pixel = 12'hF00; // 黄
        4: current_pixel = 12'h0F0; // マゼンタ
        5: current_pixel = 12'h00F; // シアン
        6: current_pixel = 12'h000; // 白
        7: current_pixel = 12'hFFF; // 黒
        default: current_pixel = 12'h000; // デフォルトは黒
    endcase
end

// sw_rstnの立ち下がり検出用の信号
reg sw_rstn_reg;
wire sw_rstn_neg;

// sw_rstnの立ち下がり検出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sw_rstn_reg <= 1'b0;
    end else begin
        sw_rstn_reg <= sw_rstn;
    end
end

// SWの立ち下がり検出
wire Debug_sel = 0;
assign sw_rstn_neg = (Debug_sel==1)? (sw_rstn_reg & ~sw_rstn) : sw_on_timer;

// ピクセル送信ステートマシン
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_pos             <= 0;
        V_pos             <= 0;
        init_mode         <= 0;
        cmd_num           <= 0;
        cmd_start         <= 1'b0;
        frame_end         <= 1'b0;
        spi_read          <= 1'b0;
        spi_start_data    <= 1'b0;
        frame_state       <= DISP_IDLE;
        data_spi_cmd      <= 8'd0;
    end else begin
        case(frame_state)
            DISP_IDLE: begin
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND;
                    cmd_start    <= 1'b1;
                    frame_end <= 0;
                end
            end

            CMD_SEND: begin
                cmd_start <= 1'b0;
                cmd_num   <= 0;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT;
                end
            end

            CMD_SEND_AFTER_WAIT: begin
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND2;
                end
            end

            CMD_SEND2: begin
                cmd_start <= 1'b1;
                cmd_num   <= 1;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT2;
                end
            end

            CMD_SEND_AFTER_WAIT2: begin
                cmd_start <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND3;
                end
            end

            CMD_SEND3: begin
                cmd_start <= 1'b1;
                cmd_num   <= 2;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT3;
                end
            end

            CMD_SEND_AFTER_WAIT3: begin
                cmd_start <= 1'b0;
                if(sw_rstn_neg) begin
                    //frame_state <= CMD_SEND4;
                    frame_state <= CMD_SEND4;
                end
            end

            CMD_SEND4: begin
                cmd_start <= 1'b1;
                cmd_num   <= 3;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT4;
                end
            end

            CMD_SEND_AFTER_WAIT4: begin
                cmd_start <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND5;
                end
            end

            CMD_SEND5: begin
                cmd_start <= 1'b1;
                cmd_num   <= 4;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT5;
                end
            end

            CMD_SEND_AFTER_WAIT5: begin
                cmd_start <= 1'b0;
                spi_read  <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND6;
                end
            end

            CMD_SEND6: begin
                cmd_start <= 1'b1;
                cmd_num   <= 5;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT6;
                end
            end

            CMD_SEND_AFTER_WAIT6: begin
                cmd_start <= 1'b0;
                spi_read  <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND7;
                end
            end

            CMD_SEND7: begin
                cmd_start <= 1'b1;
                cmd_num   <= 6;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT7;
                end
            end

            CMD_SEND_AFTER_WAIT7: begin
                cmd_start <= 1'b0;
                spi_read  <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_SEND8;
                end
            end

            CMD_SEND8: begin
                cmd_start <= 1'b1;
                cmd_num   <= 7;
                if (init_done) begin
                    frame_state <= CMD_SEND_AFTER_WAIT8;
                end
            end

            CMD_SEND_AFTER_WAIT8: begin
                cmd_start <= 1'b0;
                spi_read  <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= CMD_TO_DATA_WAIT;
                end
            end

            CMD_TO_DATA_WAIT: begin
                frame_state <= MEMORY_WRITE_MODE;
            end

            MEMORY_WRITE_MODE: begin
                cmd_start <= 1'b1;
                cmd_num   <= 8;
                if (init_done) begin
                    frame_state <= MEMORY_WRITE_AFTER_WAIT5;
                end
            end

            MEMORY_WRITE_AFTER_WAIT5: begin
                cmd_start <= 1'b0;
                spi_read  <= 1'b0;
                if(sw_rstn_neg) begin
                    frame_state <= FRAME_SEND_PIXEL_SET;
                    init_mode <= 1;
                end
            end

            FRAME_SEND_PIXEL_SET: begin
                data_spi_cmd      <= current_pixel[11:0]; // データ
                spi_start_data    <= 1'b0;
                frame_state       <= FRAME_SEND_PIXEL;
            end

            FRAME_SEND_PIXEL: begin
                spi_start_data    <= 1'b0;
                if (!spi_busy) begin
                    spi_start_data   <= 1'b1;
                    frame_state      <= FRAME_SEND_PIXEL_SET;

                    // カウンタの更新
                    if (H_pos < H_pos_end) begin
                        H_pos <= H_pos + 1;
                    end else begin
                        H_pos <= 0;
                        if (V_pos < V_pos_end) begin
                            V_pos <= V_pos + 1;
                        end else begin
                            V_pos       <= 0;
                            frame_state <= FRAME_SEND_PIXEL_WAIT;
                        end
                    end

                    // frame_end
                    if(H_pos == H_pos_end-1 && V_pos == V_pos_end) begin
                        frame_end   <= 1'b1;
                    end
                end
            end

            FRAME_SEND_PIXEL_WAIT: begin
                spi_start_data    <= 1'b0;
                data_spi_cmd      <= 8'd0;  // データ
                if (!spi_busy) begin
                    //frame_state <= FRAME_DONE;
                    frame_state <= MEMORY_WRITE_MODE;
                    init_mode <= 1'b0;
                end
            end

            FRAME_DONE: begin
                // フレーム送信完了
                frame_state <= DISP_IDLE;
            end

            default: begin
                frame_state <= DISP_IDLE;
            end
        endcase
    end
end

endmodule