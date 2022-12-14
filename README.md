# TangPrimer-20K-example

---

- [TangPrimer-20K-example](#tangprimer-20k-example)
  - [Note](#note)
    - [Error code:RP2017](#error-coderp2017)
  - [Reference](#reference)
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

## Reference

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
