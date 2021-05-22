# Setup and Operation of the PicoHomeComputer

Normal operation mode
---------------------

- Disable the programming mode of the boot loader for the MCU (IC1) by connecing Pin 3 and Pin 4 of pin bar K15 (Jumper may be removed after booting of the PicoHomeCompuer to enable support for ETHERNET_NOT_INTERRUPT line).
- Connect serial communication between IO Processor and MCU (IC1) by connecting Pin 1 and Pin 2 of pin bars K603 and K604.
- Disable programming mode of the IO Processor (IC5) by connecting Pin 1 and Pin 2 of pin bar K503.

<img src="ConfigurationForRunning.png" alt="Normal Operation" >

Programming operation mode
--------------------------

- Enable the programming modus of the boot loader for the MCU (IC1) by connecing Pin 2 and Pin 4 of pin bar K15.
- Connect USB on K5 to Host Computer to flash the MCU (IC1) with Arduino Studio

- Enable programming mode of the IO Processor (IC5) by connecting Pin 3 and Pin 2 of pin bar K503.
- Connect USB RS232 Adapter FTDI232 to serial port of IO PRocessor (IC5) on of Pin 2 of pin bar K603 (TX) and Pin 2 of pin bar K604 (RX) and Pin 2 (RESn) of pin bar K505 (DTR).
- Connect USB RS232 Adapter FTDI232 to Host Computer to flash the IO Processor (IC5) with Propeller IDE.

<img src="ConfigurationForProgramming.png" alt="Programming Operation" >
