# TangPrimer-20K-example

---

- [TangPrimer-20K-example](#tangprimer-20k-example)
  - [Note](#note)
    - [Error code:RP2017](#error-coderp2017)
  - [Tang Primer 20K Dock pin constrain](#tang-primer-20k-dock-pin-constrain)
    - [Clk pin](#clk-pin)
    - [RGB LCD](#rgb-lcd)
    - [Camera](#camera)
    - [Lite-bottom\_test\_project](#lite-bottom_test_project)
    - [DDR-Test](#ddr-test)
    - [SPI\_lcd](#spi_lcd)
    - [RGB\_lcd](#rgb_lcd)
    - [Cam2lcd](#cam2lcd)
    - [Micarray](#micarray)
    - [rocket](#rocket)
    - [WS2812](#ws2812)

## Note

### Error code:RP2017

When you meet error code `PR2017`, just enable corresponding IO as regular IO.

![rp2017](./.assets/rp2017.png)

Click `Project` in top menu bar and choose `Configuration`, then enable the corresponding Dual Purpose Pin to deal with this error.

## Tang Primer 20K Dock pin constrain

### Clk pin

The clock pin on primer 20K is `H11`

### RGB LCD

| PORT     | IO     | Pin | PORT     | IO     | Pin |
| -------- | ------ | --- | -------- | ------ | --- |
| lcd_dclk | output | R9  | lcd_de   | output | E15 |
| lcd_hs   | output | A15 | lcd_vs   | output | D14 |
| lcd_r[0] | output | L9  | lcd_r[1] | output | N8  |
| lcd_r[2] | output | N9  | lcd_r[3] | output | N7  |
| lcd_r[4] | output | N6  | lcd_g[0] | output | D11 |
| lcd_g[1] | output | A11 | lcd_g[2] | output | B11 |
| lcd_g[3] | output | P7  | lcd_g[4] | output | R7  |
| lcd_g[5] | output | D10 | lcd_b[0] | output | B12 |
| lcd_b[1] | output | C12 | lcd_b[2] | output | B13 |
| lcd_b[3] | output | A14 | lcd_b[4] | output | B14 |

### Camera

| PORT       | IO     | Pin | PORT       | IO     | Pin |
| ---------- | ------ | --- | ---------- | ------ | --- |
| cmos_scl   | inout  | F14 | cmos_sda   | inout  | F16 |
| cmos_vsync | input  | G15 | cmos_href  | input  | G14 |
| cmos_pclk  | input  | F13 | cmos_xclk  | output | G12 |
| cmos_rst_n | output | L13 | cmos_pwdn  | output | C10 |
| cmos_db[0] | input  | T12 | cmos_db[1] | input  | T11 |
| cmos_db[2] | input  | P11 | cmos_db[3] | input  | R11 |
| cmos_db[4] | input  | M15 | cmos_db[5] | input  | M14 |
| cmos_db[6] | input  | J16 | cmos_db[7] | input  | J14 |

### [Lite-bottom_test_project](./Lite-bottom_test_project/test_board/README.md)

This is the test project which is used for testing Lite-bottom and core board(Factory test).
Including the DDR-Test project and another demo containing all other usable IO blink.

### [DDR-Test](./DDR-test/LicheeTang20K_DDR_Test/README.md)

Thanks [ZiyangYE](https://github.com/ZiyangYE) providing this example.
Using serial-communication with 115200 baudrates to shows result.

### SPI_lcd

This is an example driving 1.14 inch spi screen.

![spi_lcd](./.assets/spi_lcd.jpg)

### [RGB_lcd](./RGB_lcd/rgb_lcd.md)

Screen datasheet: [Click me](https://dl.sipeed.com/shareURL/TANG/Nano%209K/6_Chip_Manual/EN/LCD_Datasheet)

Cross colorbar on the screen.

| 480x272_4.3inch_lcd                         | 800x480_5inch_lcd                           |
| ------------------------------------------- | ------------------------------------------- |
| ![lcd_4_3_inch](./.assets/lcd_4_3_inch.jpg) | ![lcd_5_0_inch](./.assets/lcd_5_0_inch.jpg) |

Colorbar on screen

| rgb_lcd_4.3inch_colorbar                | rgb_lcd_5inch_colorbar                                  |
| --------------------------------------- | ------------------------------------------------------- |
| ![](./.assets/lcd_4.3inch_colorbar.jpg) | ![lcd_5inch_colorbar](./.assets/lcd_5inch_colorbar.jpg) |

### Cam2lcd

There are 4 projects, their name rules are as followings:

| Folder name        | Camera | Screen resolution | Frame storge mode |
| ------------------ | ------ | ----------------- | ----------------- |
| OV5640_LCD480_DDR3 | OV5640 | 480x272           | DDR3              |
| OV5640_LCD800_DDR3 | OV5640 | 800x480           | DDR3              |
| OV5640_LCD480_FIFO | OV5640 | 480x272           | FIFO              |
| OV5640_LCD800_FIFO | OV5640 | 800x480           | FIFO              |

These are only for testing, and if you want better results, you need program on yourself.

After burning the .fs bitstream into fpga, press `S0` button to reset fpga chip to get right display.

![cam2lcd](./.assets/cam2lcd.jpg)

### Micarray

There is demo for micarray board.

### [rocket](./rocket/README.md)

This runs a `rv32ic` rocket core with a UART peripheral attached. This example system outputs `A` via UART infinitely.

### WS2812

A demo for onboard ws2812 led.
