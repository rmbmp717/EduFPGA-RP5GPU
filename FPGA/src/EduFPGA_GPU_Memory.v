/*
EduFPGA GPU
NISHIHARU
*/
module EduFPGA_GPU_Memory  #(
    parameter PROGRAM_DATA_NUM   = 64,
    parameter DAMAMEM_DATA_WIDTH = 32,
    parameter DAMAMEM_ADDR_WIDTH = 16,
    parameter DAMAMEM_DATA_NUM   = 512
)(
    input               clk,
    input               rstn,
    // for GPU control
    output wire         gpu_start,
    input               gpu_done,
    output              gpu_soft_reset,
    output [7:0]        thread_num,
    // from PCIE controler
    input               pcie_read_req,
    input [15:0]        pcie_read_addr,
    output wire         pcie_read_ready,
    input               pcie_write_req,
    input [15:0]        pcie_write_addr,
    input [31:0]        pcie_write_data,
    output wire         pcie_write_ready,
    output reg [31:0]   pcie_read_data,
    // from GPU. program mem
    input               program_mem_read_valid,
    input [7:0]         program_mem_read_address,
    output reg          program_mem_read_ready,
    output reg [31:0]   program_mem_read_data,
    // from GPU. data mem
    input wire [3:0]    mem_read_valid,  // 4 read enable signals
    input wire [3:0]    mem_write_valid,   // 4 write enable signals
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   raddr0,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   raddr1,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   raddr2,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   raddr3,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   waddr0,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   waddr1,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   waddr2,             // 4 address inputs
    input wire [DAMAMEM_ADDR_WIDTH-1:0]   waddr3,             // 4 address inputs
    input wire [DAMAMEM_DATA_WIDTH-1:0]   data_in0,           // 4 data inputs
    input wire [DAMAMEM_DATA_WIDTH-1:0]   data_in1,           // 4 data inputs
    input wire [DAMAMEM_DATA_WIDTH-1:0]   data_in2,           // 4 data inputs
    input wire [DAMAMEM_DATA_WIDTH-1:0]   data_in3,           // 4 data inputs
    output reg [3:0]    mem_read_ready,  // 4 read ready outputs
    output reg [3:0]    mem_write_ready,  // 4 read ready outputs
    output wire [DAMAMEM_DATA_WIDTH-1:0]  data_out0,  // 4 data outputs
    output wire [DAMAMEM_DATA_WIDTH-1:0]  data_out1,  // 4 data outputs
    output wire [DAMAMEM_DATA_WIDTH-1:0]  data_out2,  // 4 data outputs
    output wire [DAMAMEM_DATA_WIDTH-1:0]  data_out3  // 4 data outputs
);

// register addr
localparam REGISTSTER_ADDR = 16'hF800;
localparam THREAD_NUM_ADDR = 16'hF400;

//##########################################################################################

// Register memory
reg        register_mem_read_ready;
reg        register_mem_write_ready;
reg [31:0] reg_memory;
reg [31:0] thread_memory;

// Program R/W memory
reg program_mem_write_ready;
reg [31:0] pcie_program_read_data;
reg [31:0] program_memory[PROGRAM_DATA_NUM-1:0];

// ready signal
assign pcie_read_ready  = register_mem_read_ready | program_mem_read_ready | mem_read_ready[0];
assign pcie_write_ready = register_mem_write_ready | program_mem_write_ready | mem_write_ready[0];
    
reg        gpu_done_r, gpu_done_r1;
always @ (posedge clk) begin
    gpu_done_r  <= gpu_done;
    gpu_done_r1 <= gpu_done_r;
end

always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin 
        register_mem_read_ready  <= 1'b0;
        register_mem_write_ready <= 1'b0;
        reg_memory <= 32'd0;
        thread_memory <= 32'd0;
    end else begin
        if(pcie_write_req & pcie_write_addr==REGISTSTER_ADDR) begin
            reg_memory <= pcie_write_data;
            register_mem_write_ready <= 1'b1;
        end else if(pcie_write_req & pcie_write_addr==THREAD_NUM_ADDR) begin
            thread_memory <= pcie_write_data;
            register_mem_write_ready <= 1'b1;
        end else if(pcie_read_req & pcie_write_addr==REGISTSTER_ADDR) begin
            register_mem_read_ready <= 1'b1;
        end else if(gpu_done_r && ~gpu_done_r1)begin
            reg_memory[15] <= 1'b1;
        end else begin
            register_mem_read_ready  <= 1'b0;
            register_mem_write_ready <= 1'b0;
        end
    end
end

wire    program_enable  = reg_memory[0];
wire    data_enable     = reg_memory[1];
assign  gpu_start       = reg_memory[7];
assign  gpu_soft_reset  = reg_memory[8];
assign  thread_num      = thread_memory[7:0];

// pcie data out selector
always @ (*) begin
    if(pcie_read_addr==REGISTSTER_ADDR) begin
        pcie_read_data = reg_memory;
    end else if(program_enable) begin
        pcie_read_data = pcie_program_read_data;
    end else if(data_enable) begin
        pcie_read_data = data_out0;
    end else begin
        pcie_read_data = 32'd0;
    end
end

always @ (posedge clk or negedge rstn) begin
    if(~rstn) begin 
        pcie_program_read_data <= 32'd0;
        program_mem_read_ready <= 1'b0;
        program_mem_read_data  <= 32'd0;
        program_mem_write_ready <= 1'b0;
    end else begin
        if(pcie_read_req & program_enable) begin
            program_mem_read_ready <= 1'b1;
            pcie_program_read_data <= program_memory[pcie_read_addr[7:2]];
        end else if(program_mem_read_valid) begin
            program_mem_read_ready <= 1'b1;
            program_mem_read_data  <= program_memory[{{8'd0},{program_mem_read_address}}];
        end else if(pcie_write_req & program_enable & (pcie_write_addr != REGISTSTER_ADDR)) begin
            program_memory[pcie_write_addr[7:2]] <= pcie_write_data;
            program_mem_write_ready <= 1'b1;
        end else begin
            program_mem_read_ready <= 1'b0;
            program_mem_read_data  <= 32'd0;
            program_mem_write_ready <= 1'b0;
        end
    end
end
    
// Data R/W memory
wire [3:0]  mem_write_valid_w;
wire [3:0]  mem_read_valid_r;
wire [15:0] waddr_w0;
wire [15:0] waddr_w1;
wire [15:0] waddr_w2;
wire [15:0] waddr_w3;
wire [31:0] data_in_w0;
wire [31:0] data_in_w1;
wire [31:0] data_in_w2;
wire [31:0] data_in_w3;
wire [15:0] raddr0_r;

assign mem_write_valid_w = (data_enable)?  {{3'b000},{pcie_write_req}} : mem_write_valid;
assign mem_read_valid_r  = (data_enable)?  {{3'b000},{pcie_read_req}} : mem_read_valid;
assign waddr_w0          = (data_enable)?   pcie_write_addr[15:2] : waddr0;
assign waddr_w1          = (data_enable)?   16'd0 : waddr1;
assign waddr_w2          = (data_enable)?   16'd0 : waddr2;
assign waddr_w3          = (data_enable)?   16'd0 : waddr3;
assign data_in_w0        = (data_enable)?   pcie_write_data : data_in0;
assign data_in_w1        = (data_enable)?   32'd0 : data_in1;
assign data_in_w2        = (data_enable)?   32'd0 : data_in2;
assign data_in_w3        = (data_enable)?   32'd0 : data_in3;
assign raddr0_r          = (data_enable)?   pcie_read_addr[15:2] : raddr0;

quad_port_ram  #(
    .DATA_WIDTH(DAMAMEM_DATA_WIDTH),
    .ADDR_WIDTH(DAMAMEM_ADDR_WIDTH),
    .DATA_NUM  (DAMAMEM_DATA_NUM)
) inst_quad_port_ram(
    .clock                  (clk),
    .reset_n                (rstn),
    .mem_read_valid         (mem_read_valid_r),     // 4 read enable signals
    .mem_write_valid        (mem_write_valid_w),    // 4 write enable signals
    .raddr0                 (raddr0_r),  // 4 address inputs
    .raddr1                 (raddr1),    // 4 address inputs
    .raddr2                 (raddr2),    // 4 address inputs
    .raddr3                 (raddr3),    // 4 address inputs
    .waddr0                 (waddr_w0),  // 4 address inputs
    .waddr1                 (waddr_w1),  // 4 address inputs
    .waddr2                 (waddr_w2),  // 4 address inputs
    .waddr3                 (waddr_w3),  // 4 address inputs
    .data_in0               (data_in_w0),  // 4 data inputs
    .data_in1               (data_in_w1),  // 4 data inputs
    .data_in2               (data_in_w2),  // 4 data inputs
    .data_in3               (data_in_w3),  // 4 data inputs
    .mem_read_ready         (mem_read_ready),  // 4 read ready outputs
    .mem_write_ready        (mem_write_ready),  // 4 read ready outputs
    .data_out0              (data_out0),  // 4 data outputs
    .data_out1              (data_out1),  // 4 data outputs
    .data_out2              (data_out2),  // 4 data outputs
    .data_out3              (data_out3)   // 4 data outputs
);

endmodule

//##########################################################################################

module quad_port_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter DATA_NUM   = 512
) (
    input wire clock,
    input wire reset_n,
    input wire [3:0] mem_read_valid,     // 4 read enable signals
    input wire [3:0] mem_write_valid,    // 4 write enable signals
    input wire [ADDR_WIDTH-1:0] raddr0,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] raddr1,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] raddr2,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] raddr3,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] waddr0,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] waddr1,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] waddr2,  // 4 address inputs
    input wire [ADDR_WIDTH-1:0] waddr3,  // 4 address inputs
    input wire [DATA_WIDTH-1:0] data_in0,  // 4 data inputs
    input wire [DATA_WIDTH-1:0] data_in1,  // 4 data inputs
    input wire [DATA_WIDTH-1:0] data_in2,  // 4 data inputs
    input wire [DATA_WIDTH-1:0] data_in3,  // 4 data inputs
    output reg [3:0] mem_read_ready,  // 4 read ready outputs
    output reg [3:0] mem_write_ready,  // 4 read ready outputs
    output wire [DATA_WIDTH-1:0] data_out0,  // 4 data outputs
    output wire [DATA_WIDTH-1:0] data_out1,  // 4 data outputs
    output wire [DATA_WIDTH-1:0] data_out2,  // 4 data outputs
    output wire [DATA_WIDTH-1:0] data_out3  // 4 data outputs
);

reg [DATA_WIDTH-1:0] data_reg [3:0];

assign data_out0 = data_reg[0];
assign data_out1 = data_reg[1];
assign data_out2 = data_reg[2];
assign data_out3 = data_reg[3];

// メモリ配列の定義
//reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
reg [DATA_WIDTH-1:0] ram [DATA_NUM:0];

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        mem_read_ready <= 4'b0;
        mem_write_ready <= 4'b0;
        data_reg[0] <= 0;  // 読み出し
        data_reg[1] <= 0; 
        data_reg[2] <= 0; 
        data_reg[3] <= 0; 
    end else begin
        // 優先度付きアクセス処理
        if (mem_write_valid[0]) begin
            mem_write_ready[0] <= 1'b1;
            mem_write_ready[1] <= 1'b0;
            mem_write_ready[2] <= 1'b0;
            mem_write_ready[3] <= 1'b0;
            ram[waddr0] <= data_in0;  // ポート0が最優先
        end else if (mem_write_valid[1]) begin
            mem_write_ready[0] <= 1'b0;
            mem_write_ready[1] <= 1'b1;
            mem_write_ready[2] <= 1'b0;
            mem_write_ready[3] <= 1'b0;
            ram[waddr1] <= data_in1;  // ポート1が次に優先
        end else if (mem_write_valid[2]) begin
            mem_write_ready[0] <= 1'b0;
            mem_write_ready[1] <= 1'b0;
            mem_write_ready[2] <= 1'b1;
            mem_write_ready[3] <= 1'b0;
            ram[waddr2] <= data_in2;  // ポート2が次に優先
        end else if (mem_write_valid[3]) begin
            mem_write_ready[0] <= 1'b0;
            mem_write_ready[1] <= 1'b0;
            mem_write_ready[2] <= 1'b0;
            mem_write_ready[3] <= 1'b1;
            ram[waddr3] <= data_in3;  // ポート3が最も低い優先度
        end else begin
            mem_write_ready[0] <= 1'b0;
            mem_write_ready[1] <= 1'b0;
            mem_write_ready[2] <= 1'b0;
            mem_write_ready[3] <= 1'b0;
        end

        // 読み出し処理を並列化
        if (mem_read_valid[0]) begin
            mem_read_ready[0] <= 1'b1;
            data_reg[0] <= ram[raddr0];
        end else begin
            mem_read_ready[0] <= 1'b0;
            data_reg[0] <= 0;
        end
        
        if (mem_read_valid[1]) begin
            mem_read_ready[1] <= 1'b1;
            data_reg[1] <= ram[raddr1];
        end else begin
            mem_read_ready[1] <= 1'b0;
            data_reg[1] <= 0;
        end
        
        if (mem_read_valid[2]) begin
            mem_read_ready[2] <= 1'b1;
            data_reg[2] <= ram[raddr2];
        end else begin
            mem_read_ready[2] <= 1'b0;
            data_reg[2] <= 0;
        end
        
        if (mem_read_valid[3]) begin
            mem_read_ready[3] <= 1'b1;
            data_reg[3] <= ram[raddr3];
        end else begin
            mem_read_ready[3] <= 1'b0;
            data_reg[3] <= 0;
        end
    end
end

endmodule
