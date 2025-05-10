/*
EduFPGA_GPU
NISHIHARU
*/
module EduFPGA_GPU #(
	parameter DATA_MEM_ADDR_BITS        = 12,
	parameter DATA_MEM_DATA_BITS        = 16,
	parameter DATA_MEM_NUM_CHANNELS     = 4,
	parameter PROGRAM_MEM_ADDR_BITS     = 8,
	parameter PROGRAM_MEM_DATA_BITS     = 16,
	parameter PROGRAM_MEM_NUM_CHANNELS  = 1,
	parameter NUM_CORES                 = 2,
	parameter THREADS_PER_BLOCK         = 4
    )(
	clk,
	reset,
    soft_reset,
	start,
	done,
	device_control_write_enable,
	device_control_data,
    // program mem
	program_mem_read_valid,
	program_mem_read_address,
	program_mem_read_ready,
	program_mem_read_data,
    // data mem
	data_mem_read_valid,
	data_mem_read_address,
	data_mem_read_ready,
	data_mem_read_data,
	data_mem_write_valid,
	data_mem_write_address,
	data_mem_write_data,
	data_mem_write_ready
);
	input wire clk;
	input wire reset;
    input wire soft_reset;
	input wire start;
	output wire done;
	input wire device_control_write_enable;
	input wire [7:0] device_control_data;
	output wire [PROGRAM_MEM_NUM_CHANNELS - 1:0] program_mem_read_valid;
	output wire [(PROGRAM_MEM_NUM_CHANNELS * PROGRAM_MEM_ADDR_BITS) - 1:0] program_mem_read_address;
	input wire [PROGRAM_MEM_NUM_CHANNELS - 1:0] program_mem_read_ready;
	input wire [(PROGRAM_MEM_NUM_CHANNELS * PROGRAM_MEM_DATA_BITS) - 1:0] program_mem_read_data;
	output wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_read_valid;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_ADDR_BITS) - 1:0] data_mem_read_address;
	input wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_read_ready;
	input wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_DATA_BITS) - 1:0] data_mem_read_data;
	output wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_write_valid;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_ADDR_BITS) - 1:0] data_mem_write_address;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_DATA_BITS) - 1:0] data_mem_write_data;
	input wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_write_ready;

// sub module

gpu #(
	.DATA_MEM_ADDR_BITS         (DATA_MEM_ADDR_BITS),
	.DATA_MEM_DATA_BITS         (DATA_MEM_DATA_BITS),
	.DATA_MEM_NUM_CHANNELS      (DATA_MEM_NUM_CHANNELS),
	.PROGRAM_MEM_ADDR_BITS      (PROGRAM_MEM_ADDR_BITS),
	.PROGRAM_MEM_DATA_BITS      (PROGRAM_MEM_DATA_BITS),
	.PROGRAM_MEM_NUM_CHANNELS   (PROGRAM_MEM_NUM_CHANNELS),
	.NUM_CORES                  (NUM_CORES),
	.THREADS_PER_BLOCK          (THREADS_PER_BLOCK)
    ) mgpu (
    .clk                            (clk),
    .reset                          (reset | soft_reset),
    .start                          (start),
    .done                           (done),
    .device_control_write_enable    (device_control_write_enable),
    .device_control_data            (device_control_data),
    // program mem
    .program_mem_read_valid         (program_mem_read_valid),
    .program_mem_read_address       (program_mem_read_address),
    .program_mem_read_ready         (program_mem_read_ready),
    .program_mem_read_data          (program_mem_read_data),
    // data mem
    .data_mem_read_valid            (data_mem_read_valid),
    .data_mem_read_address          (data_mem_read_address),
    .data_mem_read_ready            (data_mem_read_ready),
    .data_mem_read_data             (data_mem_read_data),
    .data_mem_write_valid           (data_mem_write_valid),
    .data_mem_write_address         (data_mem_write_address),
    .data_mem_write_data            (data_mem_write_data),
    .data_mem_write_ready           (data_mem_write_ready)
);

endmodule
