/**
  Generated Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This is the main file generated using PIC32MX MCUs

  Description:
    This header file provides implementations for driver APIs for all modules selected in the GUI.
    Generation Information :
        Product Revision  :  PIC32MX MCUs - pic32mx : v1.35
        Device            :  PIC32MX270F256B
        Driver Version    :  2.00
    The generated drivers are tested against the following:
        Compiler          :  XC32 1.42
        MPLAB             :  MPLAB X 3.55
*/

/*
    (c) 2016 Microchip Technology Inc. and its subsidiaries. You may use this
    software and any derivatives exclusively with Microchip products.

    THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
    EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
    WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
    PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION
    WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION.

    IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
    WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
    BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
    FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
    ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
    THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.

    MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE
    TERMS.
*/

#include <xc.h>

#include "mcc_generated_files/mcc.h"
#include "mcc_generated_files/pin_manager.h"

#include "ulisp_pic32.h"

#define GetSystemClock()       (FOSC)
  
 //*****************************************************************************
 // DelayMs creates a delay of given milliseconds using the Core Timer
 //
 void DelayMs(int delay)
 {
     int i;
     int j = 0;
     for(i=0; i<10000*delay; i++)
     {
         j = 2*i;         
     }
 }
 
/************SRAM opcodes: commands to the 23LC1024 memory chip ******************/
#define RDMR        5       // Read the Mode Register
#define WRMR        1       // Write to the Mode Register
#define READ        3       // Read command
#define WRITE       2       // Write command
#define RSTIO     0xFF      // Reset memory to SPI mode
#define ByteMode    0x00    // Byte mode (read/write one byte at a time)
#define Sequential  0x40    // Sequential mode (read/write blocks of memory)
 
#define ADDRESS 10 
#define DATA 170

extern void writeData(char * txt);

#include <stdlib.h>
#include <stdio.h>
 
 void TestSPI()
{
    SELECT_RAM_SetLow();
    
    // SetMode
    SPI2_Exchange8bit(WRMR);
    SPI2_Exchange8bit(ByteMode);
    
    SELECT_RAM_SetHigh();

    SELECT_RAM_SetLow();

    // WriteByte
    SPI2_Exchange8bit(WRITE);
    SPI2_Exchange8bit((uint8_t)(ADDRESS >> 16));
    SPI2_Exchange8bit((uint8_t)(ADDRESS >> 8));
    SPI2_Exchange8bit((uint8_t)(ADDRESS));
    SPI2_Exchange8bit(DATA);

    SELECT_RAM_SetHigh();
    
    SELECT_RAM_SetLow();

    // SetMode
    SPI2_Exchange8bit(WRMR);
    SPI2_Exchange8bit(ByteMode);

    SELECT_RAM_SetHigh();

    SELECT_RAM_SetLow();

    // ReadByte
    SPI2_Exchange8bit(READ);
    SPI2_Exchange8bit((uint8_t)(ADDRESS >> 16));
    SPI2_Exchange8bit((uint8_t)(ADDRESS >> 8));
    SPI2_Exchange8bit((uint8_t)(ADDRESS));
    uint8_t readData = SPI2_Exchange8bit(0x0);

    SELECT_RAM_SetHigh();
    
    char buf[32];
    sprintf(buf,"data=%d",(int)readData);
    writeData(buf);
    
    sprintf(buf,"status=%d",SPI2_StatusGet());
    writeData(buf);
    
    if(readData==DATA)
    {
        LED_SetHigh();
    }
}
 
/*
                         Main application
 */
int main(void)
{
    // initialize the device
    SYSTEM_Initialize();
    TMR1_Start();  // for millis())
    LED_SetHigh();
    ulisp_setup();
    
    writeData("hello world !");

// variable to hold the state of the current clock source
//OSC_SYS_TYPE oscCurrent;
// assign the current clock source to oscCurrent
//oscCurrent = PLIB_OSC_CurrentSysClockGet(OSC_ID_0)
        
    while (1)
    {
        // Add your application code
        //ulisp_loop();
        //LED_Toggle();
        SELECT_EXTENSION_Toggle();
        TestSPI();
        //DelayMs(1);
        //delay
    }

    return -1;
}
/**
 End of File
*/