//Copyright (C)2014-2026 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12.02_SP1 (64-bit)
//IP Version: 1.0
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Wed Apr  8 20:06:39 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    mem_pll your_instance_name(
        .clkout(clkout), //output clkout
        .lock(lock), //output lock
        .clkoutd3(clkoutd3), //output clkoutd3
        .reset(reset), //input reset
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------
