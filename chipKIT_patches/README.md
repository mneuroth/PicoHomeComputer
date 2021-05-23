## Patches for the PicoHomeComputer in the chipKIT environment

Setup of the development environment for the PicoHomeComputer:

  - Install the [ArduinoIDE](https://www.arduino.cc/en/Main/Software)
  - Install the chipKIT plugin, for further details see the original [chipKIT documentation](https://chipkit.net/wiki/index.php?title=ChipKIT_core). There are two options to install the chipKIT support:
    - Autoinstal inside the ArduinoIDE via URL to chipKIT server (update URL in preferences dialog of ArduinoIDE)
    - Manuall install by copying ZIP file
  - Patch the chipKIT to add support for the PicoHomeComputer

Patch for PicoHomeComputer
--------------------------  
  
To add the PicoHomeComputer to the supported boards of the [chipKIT environment](http://chipkit.net/) in the ArduinoIDE
some files have to be modified.

The chipKIT plugin for the ArduinoIDE is normaly located in this directory:

    C:\Users\{username}\AppData\Local\Arduino15\packages\chipKIT
    
To add the PicoHomeComputer to the supported boards add the content of [boards.txt.patch](boards.txt.patch)

    C:\Users\{username}\AppData\Local\Arduino15\packages\chipKIT\hardware\pic32\2.1.0\boards.txt
    
Copy the pinout information files ([Board_defs.h](variants/PicoHomeComputer/Board_Defs.h) and [Board_Data.c](variants/PicoHomeComputer/Board_Data.c)) 
for the [PicoHomeComputer variant](variants/PicoHomeComputer) to the variant directory

    C:\Users\{username}\AppData\Local\Arduino15\packages\chipKIT\hardware\pic32\2.1.0\variants\PicoHomeComputer
    
Bootloader for PicoHomeComputer
-------------------------------

The bootloader for the ArduinoIDE/chipKIT environment can be found in the [PicoHomeComputer-pic32-bootloader repository](https://github.com/mneuroth/PicoHomeComputer-pic32-bootloader).    

The bootloader must be installed to use the PicoHomeComputer with the ArduinoIDE. To enter into bootloader mode the 
PROGRAM_BUTTON (Arduino pin 2, PIC32 pin 4 (RB0)) must be pressed when resetting the PicoHomeComputer board.
The fast flashing LED indicates, that the boards mode was entered and the PIC32 waits for a program to be 
transfered via the USB connection (as serial COM port) from the ArduinoIDE.

To upload th bootloader to the PIC32 a flash programmer like [PICKit 3](https://www.microchip.com/DevelopmentTools/ProductDetails/PG164130#utm_source=MicroSolutions&utm_medium=Link&utm_term=FY17Q1&utm_content=DevTools&utm_campaign=Article) 
has to be used to flash the PIC32 with the initial bootloader firmware. The programmer must be connected to the JTAG connector on pin bar K12. 
For flashing the firmware the [MPLAB X Integrated Programming Environment (IPE)](https://www.microchip.com/en-us/development-tools-tools-and-software/embedded-software-center/mplab-integrated-programming-environment) can be used.
