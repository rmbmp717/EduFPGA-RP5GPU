/*
EduFPGA_GPU
NISHIHARU
*/
module pcie_tlp_packet_enc (
    input               clk,
    input               rstn,
    input               tl_tx_wait,
    input               read_req,
    input [15:0]        read_addr,
    input [3:0]         bit_enable,
    input [7:0]         tag,
    input [15:0]        RequesterID,
    output reg          mem_read_req,
    input               pcie_read_ready,
    output wire [15:0]  mem_read_addr,
    input  [31:0]       mem_read_data,
    output reg          tx_sop,
    output reg          tx_eop,
    output wire [255:0] tx_data,
    output reg [7:0]    tl_tx_valid
);

localparam READ_OUT_COUNT = 12;
localparam WAIT_ACK_COUNT = 5;
reg [READ_OUT_COUNT:0]  dly_reg_count = 0;

// read_req count
always @ (posedge clk) begin
    if(read_req) begin
        dly_reg_count <= {{dly_reg_count[(READ_OUT_COUNT-1):0]},{read_req}};
    end else begin
        dly_reg_count <= {{dly_reg_count[(READ_OUT_COUNT-1):0]},{1'b0}};
    end
end

wire    wait_ack_dly;
assign  wait_ack_dly = dly_reg_count[WAIT_ACK_COUNT];

wire    read_req_out;
assign  read_req_out  = dly_reg_count[READ_OUT_COUNT-1];

reg [15:0]        read_addr_r;  
reg [3:0]         bit_enable_r;
reg [7:0]         tag_r;  
reg [15:0]        RequesterID_r;
reg [31:0]        mem_read_data_r;

assign  mem_read_addr = read_addr_r;

// Memory req controler
always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        mem_read_req <= 0;
        mem_read_data_r <= 32'd0;
    end else begin
        if(dly_reg_count[1]) begin
            mem_read_req <= 1;
        end else if(pcie_read_ready) begin
            mem_read_req <= 0;
            mem_read_data_r     <= mem_read_data;
        end
    end
end

// PCIE Packet send
always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        read_addr_r     <= 16'd0;
        bit_enable_r    <= 4'd0;
        tag_r           <= 8'd0;
        RequesterID_r   <= 16'd0;
    end else begin
        if (read_req) begin
            read_addr_r         <= read_addr;
            bit_enable_r        <= bit_enable;
            tag_r               <= tag;
            RequesterID_r       <= RequesterID;
        end
    end
end

// Packet Data
reg [31:0]  dw0;
reg [31:0]  dw1;
reg [31:0]  dw2;
reg [31:0]  r_data;

always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin
        tx_sop      <= 1'b0;
        tx_eop      <= 1'b0;
        dw0         <= 32'd0;
        dw1         <= 32'd0;
        dw2         <= 32'd0;
        r_data      <= 32'd0;
        tl_tx_valid <= 8'd0;
    // if tl_tx_wait=1
    end else if (wait_ack_dly & tl_tx_wait) begin
        tx_sop      <= 1'b1;
        tx_eop      <= 1'b1;
        dw0         <= {{8'b01001010},{8'b00000000},{8'b00000000},{8'b0000_0001}};
        dw1         <= {{16'h1100},{8'b00000000},{8'h01}};
        dw2         <= {{RequesterID_r},{tag_r},{read_addr_r[7:0]}};
        r_data      <= {mem_read_data_r};
        tl_tx_valid <= 8'hF0;
    end else if (read_req_out) begin
        if(bit_enable_r==4'b0001) begin
            // 8 bit data
            tx_sop      <= 1'b1;
            tx_eop      <= 1'b1;
            dw0         <= {{3'b010},{5'b01010},{8'b0000_0000},{8'b0000_0000},{8'b0000_0001}};
            dw1         <= {{16'h1100},{8'h00},{8'h01}};
            dw2         <= {{RequesterID_r},{tag_r},{read_addr_r[7:0]}};
            r_data      <= {mem_read_data_r};
            tl_tx_valid <= 8'hF0;
        end else if(bit_enable_r==4'b1111) begin
            // 32 bit data
            tx_sop      <= 1'b1;
            tx_eop      <= 1'b1;
            dw0         <= {{3'b010},{5'b01010},{8'b0000_0000},{8'b0000_0000},{8'b0000_0001}};   
            dw1         <= {{16'h1100},{8'h00},{8'h04}};
            dw2         <= {{RequesterID_r},{tag_r},{read_addr_r[7:0]}};
            r_data      <= {mem_read_data_r};
            tl_tx_valid <= 8'hF0;
        end
    end else begin
        tx_sop      <= 1'b0;
        tx_eop      <= 1'b0;
        dw0         <= 32'd0;
        dw1         <= 32'd0;
        dw2         <= 32'd0;
        r_data      <= 32'd0;
        tl_tx_valid <= 8'd0;
    end
end

assign tx_data[255:128] = {dw0,dw1,dw2,r_data};
assign tx_data[127:0]   = 128'd0;

// Debug Signal
wire [31:0] dw3;
assign dw3 = mem_read_data_r;

endmodule