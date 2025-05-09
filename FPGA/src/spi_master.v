module spi_master (
    input wire clk,          // システムクロック
    input wire rst,          // リセット（アクティブハイ）
    input wire start,        // 送信開始信号
    input wire frame_end,
    input wire read_mode,
    input wire [2:0] spi_mode,
    input wire [7:0] cmd_spi_cmd,  // 送信データ
    input wire [7:0] cmd_spi_data1,
    input wire [7:0] cmd_spi_data2,
    input wire [7:0] cmd_spi_data3,
    input wire [7:0] cmd_spi_data4,
    input wire [3:0] cmd_spi_data_num,
    //input wire [11:0] pixel_data,
    input wire [15:0] pixel_data,
    output reg LCD_CSX,          // チップセレクト（アクティブロー）
    output reg LCD_DC,
    output reg LCD_SCK,          // SPIクロック
    output reg LCD_SDA,          // SPIデータライン（MOSI）
    output reg SDA_Read,
    output reg busy          // 送信中フラグ
);

// SPIクロック分周設定
parameter CLK_FREQ = 10000000;    // システムクロック周波数（例: 10MHz）
parameter SPI_FREQ =  2500000;    // SPIクロック周波数（例: 2MHz）
localparam CLK_DIV = CLK_FREQ / (2 * SPI_FREQ);

// クロック分周カウンタ
reg [31:0] clk_div_counter = 0;

// クロック分周ロジック
always @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_div_counter <= 0;
        LCD_SCK <= 0;
    end else begin
        if (clk_div_counter < CLK_DIV-1) begin
            clk_div_counter <= clk_div_counter + 1;
        end else begin
            clk_div_counter <= 0;
            LCD_SCK <= ~LCD_SCK;
        end
    end
end

// SCK_reg
reg    SCK_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        SCK_reg <= 0;
    end else begin
        SCK_reg <= LCD_SCK;
    end
end

// SCK_neg
wire   SCK_neg;
assign SCK_neg = SCK_reg & (!LCD_SCK);

// 初期化ステートマシンの状態
localparam INIT_IDLE                    = 0,
           WAIT_SCK                     = 1,
           SEND_CMD                     = 2,
           SEND_CMD_DATA_CSX_H          = 3,
           SEND_CMD_DATA_BITSET         = 4,
           SEND_CMD_DATA                = 5,
           SEND_PIXEL_DATA_START        = 6,
           SEND_PIXEL_DATA_LOOP         = 7,
           SEND_DATA_WAIT_SCK           = 8,
           SEND_PIXEL_DATA              = 9;

localparam CMD_WRITE                    = 0,
           CMD_WRITE_DATA               = 1,
           PIXEL_DATA_WRITE             = 2;

function [7:0] send_data_selector(
    input [3:0] cmd_data_num, 
    input [7:0] cmd_data1,
    input [7:0] cmd_data2,
    input [7:0] cmd_data3,
    input [7:0] cmd_data4
);
    case(cmd_data_num)
        4: send_data_selector = cmd_data1;
        3: send_data_selector = cmd_data2;
        2: send_data_selector = cmd_data3;
        1: send_data_selector = cmd_data4;
    endcase
endfunction


reg [3:0]  state_reg;

// シフトレジスタとビットカウンタ
reg [15:0] shift_reg;
reg [3:0]  bit_count;

// データカウンタ
reg [3:0]  spi_data_count;

// ステートマシンの統合
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state_reg <= INIT_IDLE;
        LCD_CSX <= 1;
        LCD_DC  <= 1;
        LCD_SDA <= 1;
        SDA_Read <= 0;
        busy <= 0;
        shift_reg <= 0;
        bit_count <= 0;
        spi_data_count <= 0;
    end else begin
        case(state_reg)
            INIT_IDLE: begin
                LCD_CSX <= 1;
                LCD_DC  <= 1;
                LCD_SDA <= 1;
                if (start && !busy) begin
                    busy <= 1;
                    spi_data_count <= cmd_spi_data_num;
                    if(spi_mode==PIXEL_DATA_WRITE) begin
                        state_reg <= SEND_PIXEL_DATA_START;
                        bit_count <= 16; 
                        shift_reg <= pixel_data[15:0]; 
                    end else begin
                        state_reg <= WAIT_SCK;
                        bit_count <= 7; 
                        shift_reg <= cmd_spi_cmd[7:0]; 
                    end
                end
            end

            WAIT_SCK: begin
                if (SCK_neg) begin
                    state_reg <= SEND_CMD;
                    LCD_CSX <= 0; // CSXをアクティブ（低）に設定
                    LCD_SDA <= shift_reg[7]; // 最上位ビットを設定
                end
            end

            SEND_CMD: begin
                if (busy) begin
                    if (SCK_neg) begin
                        if (bit_count > 0) begin
                            bit_count <= bit_count - 1;
                            shift_reg <= shift_reg << 1;
                            LCD_SDA <= shift_reg[6];
                            if(bit_count==1 && (spi_mode==CMD_WRITE || spi_mode==CMD_WRITE_DATA)) begin
                                LCD_DC <= 0;
                            end else begin
                                LCD_DC <= 1;
                            end
                        end else begin
                            if(spi_mode==CMD_WRITE) begin
                                state_reg <= INIT_IDLE;
                                busy <= 0;
                                LCD_CSX <= 1'b1; 
                                LCD_SDA <= 1'b1;
                                LCD_DC  <= 1'b1;
                            end else if(spi_mode==CMD_WRITE_DATA) begin
                                state_reg <= SEND_CMD_DATA_CSX_H;
                                bit_count <= 7; 
                                LCD_CSX <= 1'b1; 
                                LCD_SDA <= 1'b1;
                                LCD_DC  <= 1'b1;
                                shift_reg <= cmd_spi_data1;
                            end else if(spi_mode==PIXEL_DATA_WRITE) begin
                                state_reg <= SEND_PIXEL_DATA;
                                busy <= 0;
                                LCD_CSX <= 1'b0; 
                                LCD_SDA <= 1'b1;
                            end
                        end
                    end
                end else begin
                    state_reg <= INIT_IDLE;
                end
            end

            SEND_CMD_DATA_CSX_H: begin
                if (SCK_neg) begin
                    state_reg <= SEND_CMD_DATA_BITSET;
                    LCD_CSX <= 0; // CSXをアクティブ（低）に設定
                    LCD_SDA <= shift_reg[7]; // 最上位ビットを設定
                end
            end

            SEND_CMD_DATA_BITSET: begin
                state_reg <= SEND_CMD_DATA;
                LCD_SDA <= shift_reg[7]; // 最上位ビットを設定
            end

            SEND_CMD_DATA: begin
                if (busy) begin
                    if (SCK_neg) begin
                        if (bit_count > 0) begin
                            bit_count <= bit_count - 1;
                            shift_reg <= shift_reg << 1;
                            LCD_SDA <= shift_reg[6];
                            /*
                            if(bit_count==1 && (spi_data_count==1) && (spi_mode==CMD_WRITE || spi_mode==CMD_WRITE_DATA)) begin
                                LCD_DC <= 0;
                            end else begin
                                LCD_DC <= 1;
                            end
                            */
                        end else begin
                            spi_data_count <= spi_data_count - 1;
                            if(spi_mode==CMD_WRITE_DATA) begin
                                if(spi_data_count==1) begin
                                    state_reg <= INIT_IDLE;
                                    busy <= 0;
                                    LCD_CSX <= 1'b1; 
                                    LCD_SDA <= 1'b1;
                                    LCD_DC  <= 1'b1;
                                end else begin
                                    state_reg <= SEND_CMD_DATA_BITSET;
                                    bit_count <= 7; 
                                    shift_reg <= send_data_selector(spi_data_count-1, cmd_spi_data1, cmd_spi_data2, cmd_spi_data3, cmd_spi_data4);
                                    busy <= 1;
                                    LCD_DC  <= 1'b1;
                                end
                            end
                        end
                    end
                end
            end

            SEND_PIXEL_DATA_START: begin
                state_reg <= SEND_PIXEL_DATA_LOOP;
                busy <= 1;
            end

            SEND_PIXEL_DATA_LOOP: begin
                if(frame_end) begin
                    state_reg <= INIT_IDLE;
                    busy <= 0;
                end else begin
                    state_reg <= SEND_DATA_WAIT_SCK;
                    busy <= 1;
                end
            end

            SEND_DATA_WAIT_SCK: begin
                if (SCK_neg) begin
                    state_reg <= SEND_PIXEL_DATA;
                    LCD_CSX <= 0; // CSXをアクティブ（低）に設定
                    bit_count <= bit_count - 1;
                    LCD_SDA <= shift_reg[15]; // 最上位ビットを設定
                end
            end

            SEND_PIXEL_DATA:  begin
                if (busy) begin
                    if (SCK_neg) begin
                        if (bit_count > 0) begin
                            bit_count <= bit_count - 1;
                            shift_reg <= shift_reg << 1;
                            LCD_SDA <= shift_reg[14];
                            LCD_DC <= 1;
                        end else begin
                            state_reg <= SEND_PIXEL_DATA_LOOP;
                            shift_reg <= pixel_data[15:0]; 
                            bit_count <= 15; 
                            busy <= 0;
                        end
                    end
                end
            end

            default: state_reg <= INIT_IDLE;

        endcase
    end
end

endmodule
