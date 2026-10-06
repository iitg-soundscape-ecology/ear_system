;========================================================
; AT89C2051
; Author        : Siddhanta Borah
; Crystal       : 11.0592 MHz
;
; P1.0          : Input
; P3.7          : Active-LOW Output / Trigger
;
;========================================================
;
; OPERATION
;
; 1. POWER ON
;
;    If P1.0 = HIGH:
;        P3.7 = LOW
;        -> TRIGGER
;
;    If P1.0 = LOW:
;        P3.7 = HIGH
;        -> NO TRIGGER
;
;
; 2. NO-TRIGGER STATE
;    P3.7 = HIGH
;
;    If P1.0 remains HIGH continuously for 5 minutes:
;
;        P3.7 -> LOW
;        -> TRIGGER
;
;    If P1.0 becomes LOW before 5 minutes:
;
;        Reset 5-minute HIGH counter
;
;
; 3. TRIGGER STATE
;    P3.7 = LOW
;
;    Observe P1.0 for 2 minutes.
;
;    Count LOW duration during this window.
;
;    If P1.0 is LOW for >= 60 seconds:
;
;        P3.7 -> HIGH
;        -> NO TRIGGER
;
;    If LOW duration < 60 seconds:
;
;        P3.7 remains LOW
;        -> TRIGGER remains active
;
;        Start another 2-minute window.
;
;
;========================================================
;
; TIMER 0:
;    Interrupt every 10 ms
;
; 5 minutes:
;    300 sec / 0.01 sec = 30000 counts = 7530H
;
; 2 minutes:
;    120 sec / 0.01 sec = 12000 counts = 2EE0H
;
; 60 seconds:
;    60 sec / 0.01 sec = 6000 counts = 1770H
;
;========================================================


            ORG     0000H
            LJMP    MAIN


;========================================================
; TIMER 0 INTERRUPT VECTOR
;========================================================

            ORG     000BH
            LJMP    TIMER0_ISR


;========================================================
; RAM VARIABLES
;========================================================

TOTAL_L     DATA    30H
TOTAL_H     DATA    31H

LOW_L       DATA    32H
LOW_H       DATA    33H

HIGH_L      DATA    34H
HIGH_H      DATA    35H


;========================================================
; MAIN PROGRAM
;========================================================

MAIN:

            ;--------------------------------------------
            ; Configure ports
            ;--------------------------------------------

            MOV     P1, #0FFH
            ; P1.0 used as input

            MOV     P3, #0FFH
            ; P3.7 initially HIGH
            ; HIGH = NO TRIGGER


            ;--------------------------------------------
            ; Check input at POWER ON
            ;--------------------------------------------

            JB      P1.0, POWER_ON_HIGH


            ;--------------------------------------------
            ; P1.0 = LOW at power ON
            ;
            ; Output HIGH
            ; NO TRIGGER
            ;--------------------------------------------

            SETB    P3.7

            SJMP    INIT_COUNTERS


POWER_ON_HIGH:

            ;--------------------------------------------
            ; P1.0 = HIGH at power ON
            ;
            ; Output LOW
            ; TRIGGER
            ;--------------------------------------------

            CLR     P3.7


;========================================================
; INITIALIZE COUNTERS
;========================================================

INIT_COUNTERS:

            MOV     TOTAL_L, #00H
            MOV     TOTAL_H, #00H

            MOV     LOW_L, #00H
            MOV     LOW_H, #00H

            MOV     HIGH_L, #00H
            MOV     HIGH_H, #00H


;========================================================
; TIMER 0 SETUP
;========================================================

            MOV     TMOD, #01H
            ; Timer 0, Mode 1, 16-bit


            MOV     TH0, #0DCH
            MOV     TL0, #00H
            ; 10 ms interrupt
            ; 11.0592 MHz crystal


            SETB    ET0
            ; Enable Timer 0 interrupt

            SETB    EA
            ; Global interrupt enable

            SETB    TR0
            ; Start Timer 0


;========================================================
; MAIN LOOP
;========================================================

MAIN_LOOP:

            SJMP    MAIN_LOOP


;========================================================
; TIMER 0 INTERRUPT
;========================================================

TIMER0_ISR:

            PUSH    ACC
            PUSH    PSW


            ;--------------------------------------------
            ; Reload Timer 0
            ;--------------------------------------------

            MOV     TH0, #0DCH
            MOV     TL0, #00H


;========================================================
; DETERMINE CURRENT OUTPUT STATE
;========================================================

            JB      P3.7, OUTPUT_IS_HIGH

            SJMP    OUTPUT_IS_LOW


;========================================================
;========================================================
; OUTPUT HIGH STATE
; NO TRIGGER
;========================================================
;========================================================

OUTPUT_IS_HIGH:

            ;--------------------------------------------
            ; Output HIGH = NO TRIGGER
            ;
            ; Need continuous HIGH input for 5 minutes
            ; to activate trigger.
            ;--------------------------------------------

            JB      P1.0, INPUT_HIGH_WHILE_OUTPUT_HIGH


;--------------------------------------------------------
; P1.0 LOW
;
; HIGH input has been interrupted.
; Reset 5-minute HIGH counter.
;--------------------------------------------------------

INPUT_LOW_WHILE_OUTPUT_HIGH:

            MOV     HIGH_L, #00H
            MOV     HIGH_H, #00H

            SJMP    EXIT_ISR


;--------------------------------------------------------
; P1.0 HIGH
;
; Count continuous HIGH duration.
;--------------------------------------------------------

INPUT_HIGH_WHILE_OUTPUT_HIGH:

            INC     HIGH_L

            MOV     A, HIGH_L
            JNZ     CHECK_5_MIN

            INC     HIGH_H


;--------------------------------------------------------
; Check whether HIGH duration = 5 minutes
;
; 30000 = 7530H
;--------------------------------------------------------

CHECK_5_MIN:

            MOV     A, HIGH_H
            CJNE    A, #075H, EXIT_ISR

            MOV     A, HIGH_L
            CJNE    A, #030H, EXIT_ISR


            ;--------------------------------------------
            ; P1.0 has been HIGH continuously for 5 min
            ;
            ; Activate trigger
            ;--------------------------------------------

            CLR     P3.7


            ;--------------------------------------------
            ; Clear recovery counters
            ;--------------------------------------------

            MOV     TOTAL_L, #00H
            MOV     TOTAL_H, #00H

            MOV     LOW_L, #00H
            MOV     LOW_H, #00H

            MOV     HIGH_L, #00H
            MOV     HIGH_H, #00H

            SJMP    EXIT_ISR


;========================================================
;========================================================
; OUTPUT LOW STATE
; TRIGGER ACTIVE
;========================================================
;========================================================

OUTPUT_IS_LOW:

            ;--------------------------------------------
            ; Output LOW = TRIGGER ACTIVE
            ;
            ; Start / continue 2-minute observation
            ; window.
            ;--------------------------------------------

            INC     TOTAL_L

            MOV     A, TOTAL_L
            JNZ     CHECK_INPUT_LOW_STATE

            INC     TOTAL_H


;--------------------------------------------------------
; Check input
;--------------------------------------------------------

CHECK_INPUT_LOW_STATE:

            JB      P1.0, RECOVERY_INPUT_HIGH


            ;--------------------------------------------
            ; P1.0 LOW
            ;
            ; Count LOW duration for recovery.
            ;--------------------------------------------

            INC     LOW_L

            MOV     A, LOW_L
            JNZ     CHECK_2_MINUTES

            INC     LOW_H

            SJMP    CHECK_2_MINUTES


;========================================================
; P1.0 HIGH DURING RECOVERY WINDOW
;========================================================

RECOVERY_INPUT_HIGH:

            ;--------------------------------------------
            ; HIGH input interrupts continuous LOW time.
            ;
            ; Reset continuous LOW counter.
            ;--------------------------------------------

            MOV     LOW_L, #00H
            MOV     LOW_H, #00H

            SJMP    CHECK_2_MINUTES


;========================================================
; CHECK 2-MINUTE WINDOW
;
; 12000 = 2EE0H
;========================================================

CHECK_2_MINUTES:

            MOV     A, TOTAL_H
            CJNE    A, #02EH, EXIT_ISR

            MOV     A, TOTAL_L
            CJNE    A, #0E0H, EXIT_ISR


;========================================================
; 2 MINUTES COMPLETED
;
; Check whether continuous LOW duration >= 60 seconds
;
; 6000 = 1770H
;========================================================

            ;--------------------------------------------
            ; Compare LOW_H with 17H
            ;--------------------------------------------

            MOV     A, LOW_H
            CJNE    A, #017H, COMPARE_LOW_H


            ; LOW_H = 17H
            ; Compare LOW_L with 70H

            MOV     A, LOW_L
            CJNE    A, #070H, COMPARE_LOW_L


            ;--------------------------------------------
            ; Exactly 1770H = 6000
            ; LOW duration = 60 seconds
            ;--------------------------------------------

            SETB    P3.7
            ; Stop trigger

            SJMP    RESET_RECOVERY


;========================================================
; COMPARE LOW BYTE
;========================================================

COMPARE_LOW_L:

            ; If LOW_L < 70H:
            ; LOW duration < 60 seconds

            JC      LOW_LESS_THAN_60


            ; LOW_L > 70H
            ; LOW duration > 60 seconds

            SETB    P3.7
            ; Stop trigger

            SJMP    RESET_RECOVERY


;========================================================
; COMPARE LOW HIGH BYTE
;========================================================

COMPARE_LOW_H:

            ; If LOW_H < 17H:
            ; LOW duration < 60 seconds

            JC      LOW_LESS_THAN_60


            ; LOW_H > 17H
            ; LOW duration > 60 seconds

            SETB    P3.7
            ; Stop trigger

            SJMP    RESET_RECOVERY


;========================================================
; LOW TIME < 60 SECONDS
;
; Keep trigger active
;========================================================

LOW_LESS_THAN_60:

            CLR     P3.7
            ; Trigger remains active


;========================================================
; RESET 2-MINUTE RECOVERY WINDOW
;========================================================

RESET_RECOVERY:

            MOV     TOTAL_L, #00H
            MOV     TOTAL_H, #00H

            MOV     LOW_L, #00H
            MOV     LOW_H, #00H


;========================================================
; EXIT INTERRUPT
;========================================================

EXIT_ISR:

            POP     PSW
            POP     ACC

            RETI


            END