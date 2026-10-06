#include <reg51.h>

/* Pin definitions */
sbit INPUT = P1^0;
sbit LED   = P1^1;

/* 
   11.0592 MHz crystal
   Machine cycle = 11.0592 MHz / 12 = 921.6 kHz
   Timer tick = 1 / 921600 = 1.085 us

   For 10 ms:
   Counts = 10,000 us / 1.085 us
          = 9216 counts

   Timer reload = 65536 - 9216
                = 56320
                = 0xDC00
*/

/* Counts 10 ms interrupts */
unsigned int timer_count = 0;

/* 5 minutes = 300 seconds
   300 / 0.01 = 30000 interrupts
*/
#define FIVE_MINUTES 30000

void timer0_init(void)
{
    TMOD &= 0xF0;       // Clear Timer 0 bits
    TMOD |= 0x01;       // Timer 0, Mode 1 (16-bit)

    TH0 = 0xDC;
    TL0 = 0x00;

    ET0 = 1;            // Enable Timer 0 interrupt
    EA  = 1;            // Enable global interrupts

    TR0 = 1;            // Start Timer 0
}

/* Timer 0 interrupt every 10 ms */
void timer0_ISR(void) interrupt 1
{
    /* Reload timer for 10 ms */
    TH0 = 0xDC;
    TL0 = 0x00;

    if (INPUT == 1)
    {
        /*
         * HIGH signal detected.
         * Turn LED ON and reset inactivity timer.
         */
        LED = 1;
        timer_count = 0;
    }
    else
    {
        /*
         * Input is LOW.
         * Count how long there has been no HIGH signal.
         */
        if (timer_count < FIVE_MINUTES)
        {
            timer_count++;
        }

        /*
         * 5 minutes without HIGH signal
         */
        if (timer_count >= FIVE_MINUTES)
        {
            LED = 0;
        }
    }
}

void main(void)
{
    /* Initial states */
    LED = 0;
    timer_count = 0;

    timer0_init();

    while (1)
    {
        /*
         * Nothing required here.
         * Everything is handled by Timer 0 interrupt.
         */
    }
}