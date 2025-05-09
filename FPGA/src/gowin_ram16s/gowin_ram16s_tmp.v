//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9 (64-bit)
//Part Number: GW5AST-LV138PG484AC2/I1
//Device: GW5AST-138B
//Device Version: B
//Created Time: Mon Nov 11 00:57:35 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_RAM16S your_instance_name(
        .dout(dout_o), //output [2:0] dout
        .wre(wre_i), //input wre
        .ad(ad_i), //input [13:0] ad
        .di(di_i), //input [2:0] di
        .clk(clk_i) //input clk
    );

//--------Copy end-------------------
