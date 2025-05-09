//EduGraphics_GPU_FPGA

create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {clk}] -add

create_generated_clock -name pll_100 -source [get_ports {clk}] -master_clock sys_clk -divide_by 2 -multiply_by 4 [get_pins {u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name pll_200 -source [get_ports {clk}] -master_clock sys_clk -divide_by 1 -multiply_by 4 [get_pins {u_pll/PLL_inst/CLKOUT1}]

create_generated_clock -name tlp_clk -source [get_pins {u_pll/PLL_inst/CLKOUT1}] -master_clock pll_200 -divide_by 2 -multiply_by 1 [get_pins {uut_div2/CLKOUT}]
