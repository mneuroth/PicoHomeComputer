# Setup and Operation of the PicoHomeComputer

Normal operation mode
---------------------

- Disable the programming mode of the boot loader for the MCU (IC1) connect Pin 3 and Pin 4 of pin bar K15 (see image for normal operation mode).
- Connect serial communication between IO Processor and MCU (IC1) by connecting Pin 1 and Pin 2 of pin bar K603 and K604 (see image for normal operation mode).
- Disable programming mode of the IO Processor (IC5) by connection Pin 1 and Pin 2 of pin bar K503.

Programming operation mode
--------------------------

- Enable the programming modus of the boot loader for the MCU (IC1) connect Pin 2 and Pin 4 of pin bar K15 (see image for programming operation mode).
- Connect USB on K5 to Host Computer to flash the MCU (IC1) with Arduino Studio

Images
------

<img src="Setup/ConfigurationForRunning.png" alt="Normal Operation" >

<img src="Setup/ConfigurationForProgramming.png" alt="Programming Operation" >
