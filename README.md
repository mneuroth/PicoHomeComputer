# Retro Home Computer
A do it yourself retro home computer project.

- [c't](https://www.heise.de/developer/artikel/ESP32-to-go-4452689.html)
- [Hardware Sparkfun](https://www.sparkfun.com/products/13907)
- [Board](https://github.com/lyusupov/ESP32-NODEMCU-ADAPTER)
- [Board](https://www.esp32.com/viewtopic.php?t=7004)
- [Espressif](https://github.com/espressif)
- [Hardware](https://www.az-delivery.de/products/esp32-developmentboard?_pos=12&_sid=02f41426d&_ss=r)
- [Firmware](https://github.com/nodemcu/nodemcu-firmware/tree/dev-esp32)
- [Official SDK](https://github.com/espressif/ESP-IDF)
- [Arduino for ESP32](https://github.com/espressif/arduino-esp32)
- [Tutorial](https://lastminuteengineers.com/esp32-arduino-ide-tutorial/)
- [Docu](https://docs.zerynth.com/latest/official/board.zerynth.nodemcu_esp32/docs/index.html)
- [Board dimensions](https://www.shenzhen2u.com/NodeMCU-32S)
- xxx [Tutorial](https://www.elektroniknet.de/design-elektronik/embedded/erweiterung-der-arduino-familie-esp32-wie-gut-ist-es-160294.html)
- [Hardware Overview](http://esp32.net/#Hardware)

- [Retro Home Computer Projekt](https://hive-project.de/projekt-info/basics)
- [Maximite](http://geoffg.net/MaximiteFeatures.html)
https://www.instructables.com/id/ESP32-Basic-PC-With-VGA-Output/
http://www.fabglib.org/index.html

https://sites.google.com/site/pcusbprojects/home/j-icsp-programmer-for-pic32-microcontroller-family
http://www.ze.em-net.ne.jp/~kenken/en/videogame.html
https://playground.boxtec.ch/doku.php/helvepic32/bspi2c/start
https://www.helvepic32.org/
https://www.helvepic32.org/assembly-instructions/
https://playground.boxtec.ch/doku.php/helvepic32/start

https://chipkit.net/wiki/index.php?title=Boards
https://chipkit.net/wiki/index.php?title=ChipKIT_Pi

SPI: Synchronous serial port. Pin 9 (SS), Pin 18 (MOSI), Pin 7 (SCK), Pin 10 (MISO). This uses SPI1 on the PIC32 Microcontroller. 
The second SPI is implemented as Pin 14 (SS), Pin 2 (MOSI), Pin 13 (MISO), and Pin 8 (SCK). 

RealTimeClock SPI --> DS1306
http://www.vwlowen.co.uk/arduino/ds1306/ds1306.htm

https://sites.google.com/site/pcusbprojects/7-tips-tricks-troubleshooting
http://geoffg.net/terminal.html
https://www.nutsvolts.com/magazine/article/January2017_Retro-PIC-Single-Board-Computer

UART/RS232:
https://deepbluembedded.com/uart-pic-microcontroller-tutorial/
https://www.aidanmocke.com/blog/2018/08/29/uart/

https://componiverse.com/app/search/esp32/fullText/rating

Pin Assignment PIC32:
- U2RX  --> U2RXR = 0010 --> RPB1 = PIN 5
- U2TX  --> RPB0R = 0010 --> RPB0 = PIN 4

- U1RX  --> U1RXR = 0010 --> RPA4 = PIN 12
- U1TX  --> RPB4R = 0001 --> RPB4 = PIN 11

- INT2  --> INT2R = 0100 --> RPB2 = PIN 6

6 Pins  noch frei für folgende Funktionen:
//- Aktivitäts-LED
//- Chip Select RAM
//- Chip Select SD Card
((- SD Card detect ?      --> nicht notwendig, gibt es an SD-Card Shield auch nicht !
//- Chip Select Ethernet
//- Ethernet Interrupt ?
- Chip Select Extension Bus ? / Touchsreen ?

TODOs:
- ggf. IO Ports an I2C Bus --> GPIO MCP23017 Port Expander
- ggf. ADC/DAC an I2C Bus
- ggf. IO Ports via Propeller ?
- Audio via Propeller ? --> siehe HIVE Projekt Schaltplan  -->  http://geoffg.net/Images/Maximite/SchematicLarge.png

Eckstein:
- https://eckstein-shop.de/ENC28J60-Ethernet-LAN-Netzwerk-Modul
- https://eckstein-shop.de/SD-Memory-Card-Module-Slot-SPI-Reader

--> http://geoffg.net/MaximiteFeatures.html
--> https://hive-project.de/projekt-info/basics

VGA: 
https://www.parallax.com/product/28076      VGA SIP Adapter Board
https://github.com/maccasoft/propeller-graphics-card/wiki
hive 

Audio:
https://www.conrad.de/de/p/tru-components-klinken-steckverbinder-3-5-mm-buchse-einbau-horizontal-polzahl-3-stereo-violett-1-st-1577797.html
https://www.conrad.de/de/p/cliff-fc68125-klinken-steckverbinder-3-5-mm-buchse-einbau-horizontal-polzahl-4-stereo-schwarz-1-st-736667.html
https://www.conrad.de/de/p/bkl-electronic-klinken-steckverbinder-3-5-mm-buchse-einbau-horizontal-polzahl-3-stereo-silber-1-st-733962.html

Audio Circuit:
- Hive
- Maximite
http://www.nerdkits.com/videos/halloween_huffman_audio/

Lcd
- https://eckstein-shop.de/Waveshare-4-inch-480x320-Resistive-Touch-TFT-LCD-Shield-Arduino-Display-ILI9486-SPI  ==> 29,99 Euro

ESP
http://esp32.net/#Hardware
https://www.elektroniknet.de/design-elektronik/embedded/erweiterung-der-arduino-familie-esp32-wie-gut-ist-es-160294.html
https://www.olimex.com/Products/IoT/ESP32/ESP32-DevKit-LiPo/open-source-hardware
https://github.com/Nicholas3388/LuaNode

PIC24/18 with USB ? --> Replace PIC32MX ?
https://www.waitingforfriday.com/?p=451

PS/2
https://de.wikipedia.org/wiki/PS/2-Schnittstelle

================

MC Interfaces:
- RS232 (World & Propeller==IO)
- SPI (RAM, SD-Card, LAN)
- Input: LAN-Interrupt
- I2C (RT-Clock)
- USB
- Activity-LED
- JTAG

Propeller (IO)
- VGA
- Keyboard
- Mouse
- Audio
- IOs ?

Extension Bus/Port (26 Pins = 2x13 == Raspberry Pi org)
- GND
- +3.3V
- +5V
- SPI MC (3-Leitungen)
- SPI_CS_MC (Chip Select)
- I2C Bus MC (2-Leitungen)  ==> 9 Leitungen

- Propeller IOs, inkl 

PIC Doku:
- https://www.microchip.com/mplab/mplab-code-configurator
- https://www.microchip.com/mplab/mplab-harmony
- https://www.microchip.com/mplab/compilers
- https://www.youtube.com/watch?v=E1_QYNaPClU  --> using MCC Plugin !

Probleme mit STL:
https://www.microchip.com/forums/m1110815.aspx

Propeller Programming:
- https://entwickler.de/online/iot/mikrocontroller-propeller-einfuehrung-579823985.html
- https://elmicro.com/de/propeller.html
- https://www.parallax.com/downloads/propeller-tool-software-windows-spin-assembly
- https://learn.parallax.com/tutorials/language/propeller-c/propeller-c-simple-devices/vga-text-display
- https://github.com/parallaxinc/BlocklyPropClient/blob/master/propeller-c-lib/Display/libvgatext/vgatext.h
- https://opencircuit.shop/Product/P8X32A-Propeller-QuickStart-Rev.B

ESP32 Programming
- https://docs.espressif.com/projects/esp-idf/en/latest/hw-reference/get-started-devkitc.html
- https://docs.espressif.com/projects/esp-idf/en/latest/get-started/index.html#step-1-install-prerequisites
- https://technicalustad.com/program-esp32-with-arduino-ide-with-c/
- https://github.com/espressif/arduino-esp32
- https://github.com/espressif/esp-idf
- https://lastminuteengineers.com/esp32-arduino-ide-tutorial/
- https://community.hiveeyes.org/t/getting-a-list-of-all-predefined-compiler-macros/1549

Blue-Pill-Board:
https://www.heise.de/developer/artikel/Keine-bittere-Pille-die-Blue-Pill-mit-ARM-Cortex-M3-4009580.html

Arm MCU:
https://www.mikrocontroller.net/topic/439180
https://www.waveshare.com/product/mcu-tools/stm32/core407i.htm
https://www.pjrc.com/teensy/
https://www.mikroe.com/mini/


#define _GLIBCXX_USE_C99

LED Blink mit ESP32 DevKit V1 Node MCU  --> buildin LED == GPIO2 == D2 Pin ?
https://circuits4you.com/2018/02/02/esp32-led-blink-example/

Interpreter for microcontroller:
- https://www.mikrocontroller.net/articles/AVR_BASIC
- https://micropython.org/
- https://github.com/micropython/micropython
- https://stonepile.fi/micropython-pic32/
- http://picoos.sourceforge.net/
- https://www.zerynth.com/blog/zerynth-is-an-official-microchip-third-party-development-tool/
- https://electronics.stackexchange.com/questions/3423/survey-of-high-level-language-interpreters-compilers-for-microcontrollers
- https://stackoverflow.com/questions/1082751/what-are-the-available-interactive-languages-that-run-in-tiny-memory
- http://www.eluaproject.net/
- https://github.com/yesco/esp-lisp
- https://github.com/paladin-t/my_basic

http://www.mycpu.eu/

fuel size:
Der Sketch verwendet 458765 Bytes (35%) des Programmspeicherplatzes. Das Maximum sind 1310720 Bytes.
Globale Variablen verwenden 22812 Bytes (6%) des dynamischen Speichers, 304868 Bytes für lokale Variablen verbleiben. Das Maximum sind 327680 Bytes.

Der Sketch verwendet 456509 Bytes (34%) des Programmspeicherplatzes. Das Maximum sind 1310720 Bytes.
Globale Variablen verwenden 22812 Bytes (6%) des dynamischen Speichers, 304868 Bytes für lokale Variablen verbleiben. Das Maximum sind 327680 Bytes.

Der Sketch verwendet 456609 Bytes (34%) des Programmspeicherplatzes. Das Maximum sind 1310720 Bytes.
Globale Variablen verwenden 22812 Bytes (6%) des dynamischen Speichers, 304868 Bytes für lokale Variablen verbleiben. Das Maximum sind 327680 Bytes.

----------------

fuel ohne Debugger:
Der Sketch verwendet 633141 Bytes (48%) des Programmspeicherplatzes. Das Maximum sind 1310720 Bytes.
Globale Variablen verwenden 22828 Bytes (6%) des dynamischen Speichers, 304852 Bytes für lokale Variablen verbleiben. Das Maximum sind 327680 Bytes.

fuel mit Debugger:
Der Sketch verwendet 658433 Bytes (50%) des Programmspeicherplatzes. Das Maximum sind 1310720 Bytes.
Globale Variablen verwenden 22828 Bytes (6%) des dynamischen Speichers, 304852 Bytes für lokale Variablen verbleiben. Das Maximum sind 327680 Bytes.

link problem pic32 mit std::exception
https://www.microchip.com/forums/m1110815.aspx

----
Projekte für ESP32 --> verwende Arduino IDE:
- C:\Users\micha\Documents\Arduino\ESP32_fuel_test
- C:\Users\micha\Documents\Arduino\FreeRTOS_minscript_test
