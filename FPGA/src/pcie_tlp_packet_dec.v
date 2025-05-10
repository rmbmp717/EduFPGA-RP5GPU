/*
EduGraphics FPGA
NISHIHARU
*/
module pcie_tlp_packet_dec (
    input               clk,
    input               rstn,
    input wire [255:0]  tlp_header,          // TLPヘッダー（128ビット）
    input               rx_sop,
    input               rx_eop,
    output wire         is_read_request,     // リードリクエストであることを示すフラグ
    input  wire         pcie_read_ready,
    output wire         is_write_request,    // ライトリクエストであることを示すフラグ
    input  wire         pcie_write_ready,
    output reg[11:0]    byte_cnt,
    output reg[15:0]    write_addr,
    output reg[31:0]    write_data,
    output reg[15:0]    read_addr,
    output reg [3:0]    bit_enable,
    output reg [15:0]   RequesterID,
    output reg[7:0]     tag
);

// function
function is_write_request_func(input [31:0] tlp_data);
    begin
        is_write_request_func = ((tlp_data[31:29] == 3'b010 || tlp_data[31:29] == 3'b011) && (tlp_data[28:24] == 5'b00000)) ? 1'b1 : 1'b0;
    end
endfunction

function is_read_request_func(input [31:0] tlp_data);
    begin
        is_read_request_func = ((tlp_data[31:29] == 3'b000 || tlp_data[31:29] == 3'b001) && (tlp_data[28:24] == 5'b00000)) ? 1'b1 : 1'b0;
    end
endfunction

wire [31:0]    data_7;
wire [31:0]    data_6;
wire [31:0]    data_5;
wire [31:0]    data_4;
wire [31:0]    data_3;
wire [31:0]    data_2;
wire [31:0]    data_1;
wire [31:0]    data_0;

assign  data_7 = tlp_header[255:224];
assign  data_6 = tlp_header[223:192];
assign  data_5 = tlp_header[191:160];
assign  data_4 = tlp_header[159:128];
assign  data_3 = tlp_header[127:96];
assign  data_2 = tlp_header[95:64];
assign  data_1 = tlp_header[63:32];
assign  data_0 = tlp_header[31:0];

wire    write_request;
wire    read_request;

assign  write_request = (rx_sop & rx_eop) & is_write_request_func(data_7);
assign  read_request  = (rx_sop & rx_eop) & is_read_request_func(data_7);

reg     is_write_request_r;
reg     is_read_request_r;

reg [31:0]    data_7_r;
reg [31:0]    data_6_r;
reg [31:0]    data_5_r;
reg [31:0]    data_4_r;
reg [31:0]    data_3_r;
reg [31:0]    data_2_r;
reg [31:0]    data_1_r;
reg [31:0]    data_0_r;

reg [3:0]     state;	
localparam IDLE = 3'b000;
localparam WRITE_WAITING = 3'b001;
localparam READ_COMMAND  = 3'b010;
localparam READ_WAITING  = 3'b011;

// StateMachine
always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        state <= IDLE;
    end else begin
        case(state)

            IDLE: begin
                if(write_request) begin
                    state <= WRITE_WAITING;
                end else if(read_request) begin
                    state <= READ_COMMAND;
                end
            end

            WRITE_WAITING: begin
                if(pcie_write_ready) begin
                    state <= IDLE;
                end
            end

            READ_COMMAND: begin
                state <= READ_WAITING;
            end

            READ_WAITING: begin
                if(pcie_read_ready) begin
                    state <= IDLE;
                end
            end

        endcase
    end
end

always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        data_7_r <= 0;
        data_6_r <= 0;
        data_5_r <= 0;
        data_4_r <= 0;
        data_3_r <= 0;
        data_2_r <= 0;
        data_1_r <= 0;
        data_0_r <= 0;
    end else if(rx_sop & rx_eop) begin
        data_7_r <= data_7;
        data_6_r <= data_6;
        data_5_r <= data_5;
        data_4_r <= data_4;
        data_3_r <= data_3;
        data_2_r <= data_2;
        data_1_r <= data_1;
        data_0_r <= data_0;
    end
end

// Decorder
always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        is_write_request_r <= 1'b0;
        is_read_request_r  <= 1'b0;
        byte_cnt           <= 12'h0;
        write_addr         <= 16'd0;
        write_data         <= 32'd0;
        read_addr          <= 16'd0;
        bit_enable         <= 4'd0;
        tag                <= 8'd0;
        RequesterID        <= 16'd0;
    end else if(state == WRITE_WAITING) begin
        // write req
        is_write_request_r <= 1'b1;  
        // read req
        is_read_request_r  <= 1'b0; 
        
        // read addr data
        byte_cnt        <= data_7_r[11:0];
        write_addr      <= data_5_r[15:0];
        write_data      <= data_4_r[31:0];    // 32bit
        read_addr       <= data_5_r[15:0];
        bit_enable      <= data_6_r[3:0];
        tag             <= data_6_r[15:8];
        RequesterID     <= data_6_r[31:16];
    end else if(state == READ_COMMAND) begin
        // write req
        is_write_request_r <= 1'b0;  
        // read req
        is_read_request_r  <= 1'b1; 
        
        // read addr data
        byte_cnt        <= data_7_r[11:0];
        write_addr      <= data_5_r[15:0];
        write_data      <= data_4_r[31:0];    // 32bit
        read_addr       <= data_5_r[15:0];
        bit_enable      <= data_6_r[3:0];
        tag             <= data_6_r[15:8];
        RequesterID     <= data_6_r[31:16];
    end else if(state == READ_WAITING) begin
        // write req
        is_write_request_r <= 1'b0;  
        // read req
        is_read_request_r  <= 1'b0; 
        
    end else begin
        is_write_request_r      <= 1'b0;
        is_read_request_r       <= 1'b0;
        byte_cnt                <= 12'h0;
        write_addr              <= 16'd0;
        write_data              <= 32'd0;
        read_addr               <= 16'd0;
        bit_enable              <= 4'd0;
        tag                     <= 8'd0;
        RequesterID             <= 16'd0;
    end
end

assign is_write_request = is_write_request_r;
assign is_read_request  = is_read_request_r;

endmodule

