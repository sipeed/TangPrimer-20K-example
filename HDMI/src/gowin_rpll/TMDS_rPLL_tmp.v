//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.01
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18C
//Created Time: Fri Aug 26 18:44:47 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    TMDS_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
