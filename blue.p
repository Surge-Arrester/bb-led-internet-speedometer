// Radioshack RGB LED driver
// Originally by Tyler Worman, tsworman at novaslp.net
//   and Jon Karve, jkarve at gmail.com
// Restructured by Wynter Woods, wynter at makermedia.com
// May 9th 2014
// 

// Make sure this is run on each boot:
// export PINS=/sys/kernel/debug/pinctrl/44e10800.pinmux/pins
// export SLOTS=/sys/devices/bone_capemgr.*/slots
// echo BB-BONE-PRU > $SLOTS

#define OUT_PIN             r30.t14        // pin P8_12
#define NUMBER_OF_SEGMENTS  3              // number of light segments to illuminate

// this include needs to come after the above definitions so as not to cause assembler errors
#include "tm1803.p"

.origin 0
.entrypoint START


/*
 *  INIT
 */
.macro INIT
    LBCO r0, C4, 4, 4                   // Load Bytes Constant Offset (?)
    CLR  r0, r0, 4                      // Clear bit 4 in reg 0
    SBCO r0, C4, 4, 4                   // Store Bytes Constant Offset
.endm

/*
 *  SHUTDOWN
 */
.macro SHUTDOWN
    CLR OUT_PIN                         // clear output pin to LOW
    MOV R31.b0, PRU0_ARM_INTERRUPT+16   // Send notification to Host for program completion
    HALT
.endm

/*
 *  START
 *  begin the LED driver here
 */
START:
    INIT
    MOV r1, NUMBER_OF_SEGMENTS          // set register 1 to the number of segments to illuminate
    SEND_RESET
    
SENDRED:
    // SEND 24 bits equalling 111111110000000000000000 to turn on a red LED
    // Loop this 10 times to turn on 10 of them.
    // Instructions are based on time between raise and fall.
    // 0 is .7us high followed by 1.8us low.
    // 1 is 1.8us high followed by .7us low. 
    // Translation to assembler instruction counts.
    // .7us = 700 ns / 5ns = 140 cycles
    // 1.8us = 1800 ns / 5ns = 360 cycles


    SUB r1, r1, 1 // subtract 1 from register 1

    SEND_BYTE 0x00
    SEND_BYTE 0xFF
    SEND_BYTE 0x00

    SEGMENT_END

    QBNE SENDRED, r1,0                  // if (register 1 is not equal to 0) then goto to SENDRED

    SHUTDOWN