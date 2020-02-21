## PicoHomeComputer Board

This directory contains the files to create the board of the PicoHomeComputer.

Releases
--------

Comment           | Version | Date
------------------|---------|------------------
Initial release   | 1.0     | 21.1.2020
Bugfixes          | 1.1     | work in progress

Pinout
------

Arduino Pin | PIC32 Pin   | direction | comment
------------|-------------|-----------|------------------
--          | 1 MCLR      | --        | --
0           | 2 RA0       | OUT       | LED
1           | 3 RA1       | OUT       | SELECT_EXT
2           | 4 RB0       | IN        | INT_ETHERNET
3           | 5 RB1       | IN        | U2RX
4           | 6 RB2       | OUT       | SELECT_ETHERNET
5           | 7 RB3       | OUT       | SELECT_RAM
--          | 8 _Vss_     | --        | --
--          | 9 RA2       | --        | OSC
--          | 10 RA3      | --        | OSC
6           | 11 RB4      | OUT       | U1TX
7           | 12 RA4      | IN        | U1RX
--          | 13 _Vdd_    | --        | --
8           | 14 RB5      | IN        | MISO
--          | 15 --       | --        | --
9           | 16 RB7      | IN        | SELECT_SD
10          | 17 RB8      | OUT       | SCL
11          | 18 RB9      | IN/OUT    | SDA
--          | 19 _Vss_    | --        | --
--          | 20 _Vddcap_ | --        | --
--          | 21 _USB_D-_ | --        | --
--          | 22 _USB_D+_ | --        | --
--          | 23 _Vdd_    | --        | --
12          | 24 RB13     | OUT       | MOSI
13          | 25 RB14     | OUT       | U2TX
14          | 26 RB15     | OUT       | SPI_CLK
--          | 27 _Vss_    | --        | --
--          | 28 _Vdd__   | --        | --

Images
------

<img src="RetroHomeComputer_V1.0_board.png" alt="Board V 1.0" >
