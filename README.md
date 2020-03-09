# PicoHomeComputer

The PicoHomeComputer project is intended to make it possible to build a simple but fully functional (home) computer completely by yourself.
The project is also intended as teaching project to show what hard- and software is needed to build a computer from the scratch.

This means you can use the board, buy the needed electronic parts and then mount and solder the electronic parts on the board.
After that you can install the software/firmware and connect periphery like keyboard, mouse and monitor to the board and
run and use the computer. It should have all the functionality of a home computer from the 80ies and even a litle bit more, 
for example you can connect the computer via LAN to the internet.

The PicoHomeComputer has the following technical specifications:
----------------------------------------------------------------

- Processor: PIC32 microcontroller (MIPS based, PIC32MX270B256), optional: ESP32 (from espressif) 
  - CPU clock speed: 48 MHz
  - RAM: 64 kByte
  - ROM: 256 kByte
- (S)RAM: 1 MBit = 128 kByte via SPI Bus (23LC1024)
- SD card interface via SPI Bus
- LAN interface via SPI Bus (ENC28J60)
- Real Time Clock via I2C Bus (DS1307)
- IO Processor (Propeller from Parallax)
  - VGA output
  - Keyboard
  - Mouse
  - Audio 

Conections for periphery:
-------------------------

- VGA monitor interface
- PS/2 for keyboard
- PS/2 for mouse
- Audio interface
- USB 2.0 interface
- SD card interface  
- 10 MBit LAN interface
- 2x RS232 interface
- Extension slot with I2C Bus and SPI Bus
- Powersupply interface (for a 7-12 Volt power supply) 

Components:
-----------

- [Board](https://github.com/mneuroth/PicoHomeComputer/tree/master/board)
- Software
  - [chipKIT](https://chipkit.net/), this is the PIC32 platform support for the [Arduiono IDE](https://www.arduino.cc/en/Main/Software)
  - [chipKIT patches for the PicoHomeComputer](https://github.com/mneuroth/PicoHomeComputer/tree/master/chipKIT_patches)
  - [uLisp](http://www.ulisp.com/), a lisp implementation for microcontrollers
  - [uLisp for chipKIT](https://github.com/mneuroth/ulisp-pic32-chipKIT), the uLisp for the PIC32 microcontroller
  - [Bootloader for the PicoHomeComputer](https://github.com/mneuroth/PicoHomeComputer-pic32-bootloader)
  - [Library for ENC28J60 for chipKIT/PicoHomeComputer](https://github.com/mneuroth/PicoHomeComputer-EtherCard)
- [Datasheets](https://github.com/mneuroth/PicoHomeComputer/tree/master/chipKIT_patches/datasheets)
- Documentation

Interpreters for microcontrollers:
----------------------------------

- http://www.ulisp.com/
- https://micropython.org/
- https://www.mikrocontroller.net/articles/AVR_BASIC
- https://github.com/micropython/micropython
- https://stonepile.fi/micropython-pic32/
- http://picoos.sourceforge.net/
- https://www.zerynth.com/blog/zerynth-is-an-official-microchip-third-party-development-tool/
- https://electronics.stackexchange.com/questions/3423/survey-of-high-level-language-interpreters-compilers-for-microcontrollers
- https://stackoverflow.com/questions/1082751/what-are-the-available-interactive-languages-that-run-in-tiny-memory
- http://www.eluaproject.net/
- https://github.com/yesco/esp-lisp
- https://github.com/paladin-t/my_basic
 
  
Other intresting computer projects:
-----------------------------------  

- [Maximite](http://geoffg.net/maximite.html)
- [HIVE-Project](https://hive-project.de/)

Other intresting microcontroller platforms (ARM):
-------------------------------------------------

- https://www.pjrc.com/teensy/
- https://www.mikroe.com/mini/- https://www.mikrocontroller.net/topic/439180
- https://www.waveshare.com/product/mcu-tools/stm32/core407i.htm
