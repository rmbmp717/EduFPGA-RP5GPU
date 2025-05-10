`timescale 1ns/1ps
//`define GPU_LESS

module EduFPGA_GPU_module  #(
    parameter MEM_DATA_WIDTH = 32,
    parameter MEM_ADDR_WIDTH = 16
    ) (
    input wire clock,
    input wire gpu_clock,
    input wire reset_n,
    // GPU
    output wire gpu_start,
    output wire gpu_done,
    // PCIE port
    input wire                       pcie_read_request,
    input wire [MEM_ADDR_WIDTH-1:0]  pcie_read_addr,
    output wire                      pcie_read_ready,
    input wire                       pcie_write_request,
    input wire [MEM_ADDR_WIDTH-1:0]  pcie_write_addr,
    input wire [MEM_DATA_WIDTH-1:0]  pcie_write_data, 
    output wire                      pcie_write_ready,
    output wire [MEM_DATA_WIDTH-1:0] pcie_read_data
);
    
    localparam GPU_ADDR_WIDTH               = 12;
    localparam GPU_DATA_MEM_DATA_BITS       = 16;
    localparam GPU_DATA_MEM_NUM_CHANNELS    = 4;
    localparam GPU_PROGRAM_MEM_ADDR_BITS    = 8;
    localparam GPU_PROGRAM_MEM_DATA_BITS    = 16;
    localparam GPU_PROGRAM_MEM_NUM_CHANNELS = 1;
    localparam GPU_NUM_CORES                = 2;

    localparam MEMORY_ADDR_WIDTH            = 16;
    localparam MEMORY_DATA_MEM_DATA_BITS    = 32;

    //##########################################################################################

    wire [7:0]                             thread_num;
    
    wire                                   program_mem_read_valid;
    wire [7:0]                             program_mem_read_address;     
    wire                                   program_mem_read_ready;   
    wire [MEMORY_DATA_MEM_DATA_BITS-1:0]   program_mem_read_data;
    
    wire [GPU_DATA_MEM_NUM_CHANNELS-1:0]                            mem_read_valid;
    wire [GPU_DATA_MEM_NUM_CHANNELS*GPU_ADDR_WIDTH-1:0]             data_mem_read_address;
    wire [GPU_DATA_MEM_NUM_CHANNELS-1:0]                            mem_read_ready;
    wire [GPU_DATA_MEM_NUM_CHANNELS*GPU_DATA_MEM_DATA_BITS-1:0]     data_mem_read_data;

    wire [GPU_DATA_MEM_DATA_BITS-1:0]    data_out3;
    wire [GPU_DATA_MEM_DATA_BITS-1:0]    data_out2;
    wire [GPU_DATA_MEM_DATA_BITS-1:0]    data_out1;
    wire [GPU_DATA_MEM_DATA_BITS-1:0]    data_out0;

    assign data_mem_read_data[(GPU_DATA_MEM_NUM_CHANNELS-0)*GPU_DATA_MEM_DATA_BITS-1:(GPU_DATA_MEM_NUM_CHANNELS-1)*GPU_DATA_MEM_DATA_BITS] = data_out3[GPU_DATA_MEM_DATA_BITS-1:0];
    assign data_mem_read_data[(GPU_DATA_MEM_NUM_CHANNELS-1)*GPU_DATA_MEM_DATA_BITS-1:(GPU_DATA_MEM_NUM_CHANNELS-2)*GPU_DATA_MEM_DATA_BITS] = data_out2[GPU_DATA_MEM_DATA_BITS-1:0];
    assign data_mem_read_data[(GPU_DATA_MEM_NUM_CHANNELS-2)*GPU_DATA_MEM_DATA_BITS-1:(GPU_DATA_MEM_NUM_CHANNELS-3)*GPU_DATA_MEM_DATA_BITS] = data_out1[GPU_DATA_MEM_DATA_BITS-1:0];
    assign data_mem_read_data[(GPU_DATA_MEM_NUM_CHANNELS-3)*GPU_DATA_MEM_DATA_BITS-1:(GPU_DATA_MEM_NUM_CHANNELS-4)*GPU_DATA_MEM_DATA_BITS] = data_out0[GPU_DATA_MEM_DATA_BITS-1:0];

    wire [GPU_DATA_MEM_NUM_CHANNELS*GPU_ADDR_WIDTH-1:0]         data_mem_write_address;
    wire [GPU_DATA_MEM_NUM_CHANNELS*GPU_DATA_MEM_DATA_BITS-1:0] data_mem_write_data;
    wire [GPU_DATA_MEM_NUM_CHANNELS-1:0]                        mem_write_valid;
    wire [GPU_DATA_MEM_NUM_CHANNELS-1:0]                        mem_write_ready;
    
    // read address
    wire [GPU_ADDR_WIDTH-1:0] gpu_raddr0;
    wire [GPU_ADDR_WIDTH-1:0] gpu_raddr1;
    wire [GPU_ADDR_WIDTH-1:0] gpu_raddr2;
    wire [GPU_ADDR_WIDTH-1:0] gpu_raddr3;
    assign  gpu_raddr0 = data_mem_read_address[GPU_ADDR_WIDTH-1:0];
    assign  gpu_raddr1 = data_mem_read_address[GPU_ADDR_WIDTH*2-1:GPU_ADDR_WIDTH];
    assign  gpu_raddr2 = data_mem_read_address[GPU_ADDR_WIDTH*3-1:GPU_ADDR_WIDTH*2];
    assign  gpu_raddr3 = data_mem_read_address[GPU_ADDR_WIDTH*4-1:GPU_ADDR_WIDTH*3];

    wire [MEMORY_ADDR_WIDTH-1:0] raddr0 = {{4'd0},{gpu_raddr0}};
    wire [MEMORY_ADDR_WIDTH-1:0] raddr1 = {{4'd0},{gpu_raddr1}};
    wire [MEMORY_ADDR_WIDTH-1:0] raddr2 = {{4'd0},{gpu_raddr2}};
    wire [MEMORY_ADDR_WIDTH-1:0] raddr3 = {{4'd0},{gpu_raddr3}};
    
    // write address
    wire [GPU_ADDR_WIDTH-1:0] gpu_waddr0;   
    wire [GPU_ADDR_WIDTH-1:0] gpu_waddr1;    
    wire [GPU_ADDR_WIDTH-1:0] gpu_waddr2;    
    wire [GPU_ADDR_WIDTH-1:0] gpu_waddr3;  
    assign  gpu_waddr0 = data_mem_write_address[GPU_ADDR_WIDTH-1:0];
    assign  gpu_waddr1 = data_mem_write_address[GPU_ADDR_WIDTH*2-1:GPU_ADDR_WIDTH];
    assign  gpu_waddr2 = data_mem_write_address[GPU_ADDR_WIDTH*3-1:GPU_ADDR_WIDTH*2];
    assign  gpu_waddr3 = data_mem_write_address[GPU_ADDR_WIDTH*4-1:GPU_ADDR_WIDTH*3];

    wire [MEMORY_ADDR_WIDTH-1:0] waddr0 = gpu_waddr0;   
    wire [MEMORY_ADDR_WIDTH-1:0] waddr1 = gpu_waddr1;   
    wire [MEMORY_ADDR_WIDTH-1:0] waddr2 = gpu_waddr2;   
    wire [MEMORY_ADDR_WIDTH-1:0] waddr3 = gpu_waddr3;   
     
    wire [GPU_DATA_MEM_DATA_BITS-1:0] gpu_data_in0;   
    wire [GPU_DATA_MEM_DATA_BITS-1:0] gpu_data_in1;  
    wire [GPU_DATA_MEM_DATA_BITS-1:0] gpu_data_in2;  
    wire [GPU_DATA_MEM_DATA_BITS-1:0] gpu_data_in3; 
    assign  gpu_data_in0 = data_mem_write_data[GPU_DATA_MEM_DATA_BITS-1:0];  
    assign  gpu_data_in1 = data_mem_write_data[GPU_DATA_MEM_DATA_BITS*2-1:GPU_DATA_MEM_DATA_BITS];   
    assign  gpu_data_in2 = data_mem_write_data[GPU_DATA_MEM_DATA_BITS*3-1:GPU_DATA_MEM_DATA_BITS*2];   
    assign  gpu_data_in3 = data_mem_write_data[GPU_DATA_MEM_DATA_BITS*4-1:GPU_DATA_MEM_DATA_BITS*3];  
     
    wire [MEMORY_DATA_MEM_DATA_BITS-1:0] data_in0 = gpu_data_in0[GPU_DATA_MEM_DATA_BITS-1:0];
    wire [MEMORY_DATA_MEM_DATA_BITS-1:0] data_in1 = gpu_data_in1[GPU_DATA_MEM_DATA_BITS-1:0];
    wire [MEMORY_DATA_MEM_DATA_BITS-1:0] data_in2 = gpu_data_in2[GPU_DATA_MEM_DATA_BITS-1:0];
    wire [MEMORY_DATA_MEM_DATA_BITS-1:0] data_in3 = gpu_data_in3[GPU_DATA_MEM_DATA_BITS-1:0];   

    //##########################################################################################
`ifdef GPU_LESS
`else
    // EduGrapchics GPU
    EduFPGA_GPU  #(
        .DATA_MEM_ADDR_BITS             (GPU_ADDR_WIDTH),
        .DATA_MEM_DATA_BITS             (GPU_DATA_MEM_DATA_BITS),
        .DATA_MEM_NUM_CHANNELS          (GPU_DATA_MEM_NUM_CHANNELS),
        .PROGRAM_MEM_ADDR_BITS          (GPU_PROGRAM_MEM_ADDR_BITS),
        .PROGRAM_MEM_DATA_BITS          (GPU_PROGRAM_MEM_DATA_BITS),
        .PROGRAM_MEM_NUM_CHANNELS       (GPU_PROGRAM_MEM_NUM_CHANNELS),
        .NUM_CORES                      (GPU_NUM_CORES),
        .THREADS_PER_BLOCK              (GPU_DATA_MEM_NUM_CHANNELS)
        ) mEduGraGPU(
        .clk                            (gpu_clock),
        .reset                          (~reset_n),
        .soft_reset                     (gpu_soft_reset),
        .start                          (gpu_start),
        .done                           (gpu_done),
        .device_control_write_enable    (1'b1),
        .device_control_data            (thread_num),
        // program mem
        .program_mem_read_valid         (program_mem_read_valid),
        .program_mem_read_address       (program_mem_read_address),
        .program_mem_read_ready         (program_mem_read_ready),
        .program_mem_read_data          (program_mem_read_data[15:0]),
        // data mem
        .data_mem_read_valid            (mem_read_valid),
        .data_mem_read_address          (data_mem_read_address),
        .data_mem_read_ready            (mem_read_ready),
        .data_mem_read_data             (data_mem_read_data),
        .data_mem_write_valid           (mem_write_valid),
        .data_mem_write_address         (data_mem_write_address),
        .data_mem_write_data            (data_mem_write_data),
        .data_mem_write_ready           (mem_write_ready)
    );
`endif       
    
    //##########################################################################################
    //EduGraGPU Memory
    // Memory
    EduFPGA_GPU_Memory #(
        .PROGRAM_DATA_NUM                   (64),
        .DAMAMEM_DATA_WIDTH                 (MEMORY_DATA_MEM_DATA_BITS),
        .DAMAMEM_ADDR_WIDTH                 (MEMORY_ADDR_WIDTH),
        .DAMAMEM_DATA_NUM                   (512)
        ) mEduGraGPU_Memory(
        .clk                                (gpu_clock),
        .rstn                               (reset_n),
        // for GPU control
        .gpu_start                          (gpu_start),
        .gpu_done                           (gpu_done),
        .gpu_soft_reset                     (gpu_soft_reset),
        .thread_num                         (thread_num),
        // from PCIE controler
        .pcie_read_req                      (pcie_read_request),
        .pcie_read_addr                     (pcie_read_addr),
        .pcie_read_ready                    (pcie_read_ready),
        .pcie_write_req                     (pcie_write_request),
        .pcie_write_addr                    (pcie_write_addr),
        .pcie_write_data                    (pcie_write_data),
        .pcie_write_ready                   (pcie_write_ready),
        .pcie_read_data                     (pcie_read_data),
        // program mem
        .program_mem_read_valid             (program_mem_read_valid),
        .program_mem_read_address           (program_mem_read_address),
        .program_mem_read_ready             (program_mem_read_ready),
        .program_mem_read_data              (program_mem_read_data),
        // data mem
        .mem_read_valid                     (mem_read_valid),       // 4 read enable signals
        .mem_write_valid                    (mem_write_valid),      // 4 write enable signals
        .raddr0                             (raddr0),               // 4 address inputs
        .raddr1                             (raddr1),               // 4 address inputs
        .raddr2                             (raddr2),               // 4 address inputs
        .raddr3                             (raddr3),               // 4 address inputs
        .waddr0                             (waddr0),               // 4 address inputs
        .waddr1                             (waddr1),               // 4 address inputs
        .waddr2                             (waddr2),               // 4 address inputs
        .waddr3                             (waddr3),               // 4 address inputs
        .data_in0                           (data_in0),              // 4 data inputs
        .data_in1                           (data_in1),              // 4 data inputs
        .data_in2                           (data_in2),              // 4 data inputs
        .data_in3                           (data_in3),              // 4 data inputs
        .mem_read_ready                     (mem_read_ready),       // 4 read ready outputs
        .mem_write_ready                    (mem_write_ready),      // 4 read ready outputs
        .data_out0                          (data_out0),            // 4 data outputs
        .data_out1                          (data_out1),            // 4 data outputs
        .data_out2                          (data_out2),            // 4 data outputs
        .data_out3                          (data_out3)             // 4 data outputs
    );


endmodule
