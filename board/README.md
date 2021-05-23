## PicoHomeComputer Board

This directory contains the files to create the board of the PicoHomeComputer.

The schematic and board layout file is in the [TARGET 3001](https://ibfriedrich.com/en/index.html) format and 
can be viewed and edited with the [free version of the TARGET 3001 program](https://de.beta-layout.com/downloads/).

Pinout
------

Arduino Pin | PIC32 Pin    | direction | comment
------------|--------------|-----------|------------------
--          | 1 MCLR       | --        | --
0           | 2 RA0        | OUT       | LED
1           | 3 RA1        | OUT       | SELECT_EXT
2           | 4 RB0        | IN        | INT_ETHERNET (PROGRAM_BUTTON)
3           | 5 RB1        | IN        | U2RX
4           | 6 RB2        | OUT       | SELECT_ETHERNET
5           | 7 RB3        | OUT       | SELECT_RAM
--          | 8 _Vss_      | --        | --
--          | 9 RA2        | --        | OSC
--          | 10 RA3       | --        | OSC
6           | 11 RB4       | OUT       | U1TX
7           | 12 RA4       | IN        | U1RX
--          | 13 _Vdd_     | --        | --
8           | 14 RB5       | IN        | MISO
--          | 15 _USB_Vdd_ | --        | --
9           | 16 RB7       | IN        | SELECT_SD
10          | 17 RB8       | OUT       | SCL
11          | 18 RB9       | IN/OUT    | SDA
--          | 19 _Vss_     | --        | --
--          | 20 _Vddcap_  | --        | --
--          | 21 _USB_D-_  | --        | --
--          | 22 _USB_D+_  | --        | --
--          | 23 _Vdd_     | --        | --
12          | 24 RB13      | OUT       | MOSI
13          | 25 RB14      | OUT       | U2TX
14          | 26 RB15      | OUT       | SPI_CLK
--          | 27 _Vss_     | --        | --
--          | 28 _Vdd_     | --        | --

Releases
--------

Comment           | Version | Date
------------------|---------|------------------
Initial release   | 1.0     | 21.1.2020
Bugfixes          | 1.1     | work in progress


Problems with Version 1.0 and fixed in Version 1.1
--------------------------------------------------

Fixes:
- added capacitor C106 at pin 23 of IC1 (decoupling capacitor needed for flashing)
- value for R102 changed from 2.2kOhm to 1 kOhm
- updated some resistor values for VGA output

Open problems:
- hardware SPI bus of IC1 must be connected to Pins ??? (otherwiese only SoftSPI is working) -> modify layout
- VGA connector is plug but should be socket -> modify layout
- footprint for SD card slot doesen't fit -> modify layout or use other SD card slot
- maybe: more decoupling capacitors for power supply
- maybe: change to socket (instead of plug) for RS232 adapter, buildin null modem?

History of the PicoHomeComputer
-------------------------------

- Started with circuit: spring 2017
- Order of electronic parts: may 2017, december 2019
- Resumed project: november 2019
- Started github project: 26.11.2019
- Started with layout of board: december 2019
- Finished Version 1.0 of board and ordered prototype: 21.1.2020
- Started to arm the board with electronic parts: 7.2.2020
- Finished first iteration of board setup and firmware development: may 2020
- Started second iteration of firmware development, updated documentation: may 2021

Images
------

<img src="RetroHomeComputer_V1.0_board.png" alt="Board V 1.0" >
