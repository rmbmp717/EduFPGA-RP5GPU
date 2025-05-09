`timescale 1ns / 1ps

module spi_lcd_init (
    input wire clk,
    input wire rst_n,
    input wire cmd_start,
    input wire [3:0] cmd_num,
    input wire spi_read,
    input wire spi_busy,
    output reg [2:0] spi_mode,
    output reg [7:0] cmd_spi_cmd,       // 初期化コマンド用の信号
    output reg [7:0] cmd_spi_data1,     // SPI DATA
    output reg [7:0] cmd_spi_data2,     // SPI DATA
    output reg [7:0] cmd_spi_data3,     // SPI DATA
    output reg [7:0] cmd_spi_data4,     // SPI DATA
    output reg [3:0] cmd_spi_data_num,  // SPI DATA NUM
    output reg spi_start_cmd,           // SPI送信開始
    output reg spi_read_mode,
    output reg init_done                // 初期化完了フラグ
);

// 初期化ステートマシンの状態
// ステート定義（typedef enumを避ける）
localparam INIT_IDLE               = 3'd0,
           INIT_DELAY              = 3'd1,
           SEND_CMD                = 3'd2,
           SEND_CMD_AFTER_WAIT     = 3'd3,
           INIT_DONE_STATE         = 3'd4,
           INIT_DONE_AFTER_WAIT    = 3'd5;

localparam CMD_WRITE                    = 0,
           CMD_WRITE_DATA               = 1,
           PIXEL_DATA_WRITE             = 2;

// 初期化ステートマシンの状態とカウンタ
reg [2:0] init_state;

localparam DELAYCNT = 100;      // 10us (10MHzクロック)
localparam AFTER_DELAYCNT = 100;   

reg [19:0] delay_counter = 0; // 100ms (10MHzクロックの場合 1_000_000カウント)

reg read_enable;

// 初期化ステートマシンの実装
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        init_state <= INIT_IDLE;
        read_enable <= 0;
        spi_mode <= CMD_WRITE;
        cmd_spi_cmd <= 0;
        cmd_spi_data1 <= 0;
        cmd_spi_data2 <= 0;
        cmd_spi_data3 <= 0;
        cmd_spi_data4 <= 0;
        cmd_spi_data_num <= 0;
        spi_read_mode <= 0;
        spi_start_cmd <= 0;
        init_done <= 0;
        delay_counter <= 0;
    end else begin
        case (init_state)
            INIT_IDLE: begin
                if (cmd_start) begin
                    init_state <= INIT_DELAY;
                    if(spi_read) begin
                        read_enable <= 1;
                    end else begin
                        read_enable <= 0;
                    end
                end
            end

            INIT_DELAY: begin
                if (delay_counter < DELAYCNT) begin 
                    delay_counter <= delay_counter + 1;
                end else begin
                    delay_counter <= 0;
                    init_state <= SEND_CMD;
                end
            end

            SEND_CMD: begin
                case(cmd_num)
                    0: begin
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h01; // Software reset
                    end
                    1: begin
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h11; // Sleep out
                    end
                    2: begin
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h29; // DISPONコマンド（0x29）
                    end
                    3: begin
                        // Optional command
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h29; // DISPONコマンド（0x29）
                    end
                    4: begin
                        spi_mode <= CMD_WRITE_DATA;
                        cmd_spi_cmd   <= 8'h3a; // Interface pixel format
                        cmd_spi_data1 <= 8'h05; // 16bit mode
                        cmd_spi_data_num <= 1;
                    end
                    5: begin
                        spi_mode <= CMD_WRITE_DATA;
                        cmd_spi_cmd   <= 8'h36; // RGB-RGR format
                        cmd_spi_data1 <= 8'hC0; // HV INV. RGB mode
                        cmd_spi_data_num <= 1;
                    end
                    6: begin
                        spi_mode <= CMD_WRITE_DATA;
                        cmd_spi_cmd   <= 8'h2A; // Colunm Address Set
                        cmd_spi_data1 <= 8'h0;
                        cmd_spi_data2 <= 8'd26;
                        cmd_spi_data3 <= 8'h0;
                        cmd_spi_data4 <= 8'd106;
                        cmd_spi_data_num <= 4;
                    end
                    7: begin
                        spi_mode <= CMD_WRITE_DATA;
                        cmd_spi_cmd   <= 8'h2B; // Row Address Set
                        cmd_spi_data1 <= 8'd0;
                        cmd_spi_data2 <= 8'd0;
                        cmd_spi_data3 <= 8'h0;
                        cmd_spi_data4 <= 8'd160;
                        cmd_spi_data_num <= 4;
                    end
                    8: begin
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h2C; // memory write
                        cmd_spi_data_num <= 0;
                    end
                    default: begin
                        spi_mode <= CMD_WRITE;
                        cmd_spi_cmd <= 8'h29; 
                    end
                endcase
                spi_start_cmd <= 1;          // Spi master module start
                if(read_enable) begin
                    spi_read_mode <= 1;
                end else begin
                    spi_read_mode <= 0;
                end
                init_state <= SEND_CMD_AFTER_WAIT;
            end

            SEND_CMD_AFTER_WAIT: begin
                spi_start_cmd <= 0;
                if (delay_counter < AFTER_DELAYCNT) begin 
                    delay_counter <= delay_counter + 1;
                end else begin
                    delay_counter <= 0;
                    init_state <= INIT_DONE_STATE;
                end
            end

            INIT_DONE_STATE: begin
                if (!spi_busy) begin
                    spi_start_cmd <= 0;
                    init_state <= INIT_DONE_AFTER_WAIT;
                end
            end

            INIT_DONE_AFTER_WAIT: begin
                if (delay_counter < AFTER_DELAYCNT) begin 
                    delay_counter <= delay_counter + 1;
                end else begin
                    delay_counter <= 0;
                    init_done <= 1; // 初期化完了フラグをセット
                    init_state <= INIT_IDLE;
                end
            end

            default: init_state <= INIT_IDLE;

        endcase
    end
end

endmodule
