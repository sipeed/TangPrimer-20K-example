# Overview

A RISC-V based SoC written in SystemVerilog, running on 
the Tang Premier 20K. Supports the RV32IMC instruction set with a 
five-stage pipeline. Interrupts are supported.

Peripherals include I2C, GPIO, UART, TIMER, and SPI. Uses DDR memory. FreeRTOS has been ported.



# Running Method

1. Prepare a Micro SD card, format it as FAT32, and put BOOT.bin into it.
2. Insert the SD card into the development board and power it on. Use Gowin Programmer to burn melon-riscv.fs into the FPGA.
3. Connect to the serial terminal using software such as MobaXterm. Input `help` to view help; input `sdload` to load the program (FreeRTOS) from the SD card.

Running Effect:

![Screenshot](https://github.com/watermeko/picx-images-hosting/raw/master/all/blog/%E5%9B%BE%E7%89%87.b9jkxakdj.webp)

# Source Code and More Information

[MelonSoc](https://github.com/watermeko/MelonSoc)
