;/********************************************************************************
;* main.asm: Demonstration av timerkretsar Timer 0 - Timer 2 i C. Tre lysdioder 
;*           anslutna till pin 8 - 10 (PORTB0 - PORTB2) togglas via var sin
;*           timerkrets. Varje timerkrets genererar ett avbrott var 16.384:e ms.
;*
;*           LED1 ansluten till pin 8 (PORTB0) togglas var 100:e ms via Timer 0.
;*           LED2 ansluten till pin 9 (PORTB1) togglas var 200:e ms via Timer 1.
;*           LED3 ansluten till pin 10 (PORTB2) togglas var 300:e ms via Timer 2.
;*
;*           Eftersom ett timeravbrott sker var 16.384:e ms r�knas antalet
;*           avbrott N som kr�vs f�r en viss f�rdr�jningstid T enligt nedan:
;*
;*                                    N = T / 16.384,
;*
;*           d�r resultatet avrundas till n�rmaste heltal.
;* 
;*           Vi har en klockfrekvens F_CPU p� 16 MHz. Vi anv�nder en prescaler
;*           p� 1024 f�r timerkretsarna, vilket medf�r att uppr�kningsfrekvensen
;*           f�r respektive timerkrets blir 16M / 1024 = 15 625 Hz. D�rmed sker
;*           inkrementering av respektive timer var 1 / 15 625 = 0.064:e ms.
;*           Eftersom varje timerkrets r�knar upp till 256 innan avbrott 
;*           passerar d�rmed 0.064 * 256 = 16.384 ms mellan varje avbrott.
;*
;*           - Assemblerdirektiv:
;*              .EQU (Equal) : Allm�na makrodefinitioner.
;*              .DEF (Define): Makrodefinitioner f�r CPU-register.
;*              .ORG (Origin): Anv�nds f�r att specificera en adress.
;*
;*           - Assemblerinstruktioner:
;*              RJMP (Relative Jump)         : Hoppar till angiven adress.
;*              RETI (Return From Interrupt): Hoppar tillbaka fr�n avbrottsrutin.
;*              LDI (Load Immediate)        : L�ser in v�rde till CPU-register.
;*              OUT (Store to I/O location) : Skriver till I/O-register.
;*              CLR (Clear Register)        : Nollst�ller CPU-register.
;*              SEI (Set Interrupt Flag)    : Ettst�ller interrupt-flaggan.
;*              STS (Store To Dataspace)    : Skriver till dataminnet.
;*              LDS (Load From Dataspace)   : L�ser fr�n dataminnet.
;*              INC (Increment)             : Inkrementerar v�rde i CPU-register.
;*              CPI (Compare Immediate)     : J�mf�r inneh�ll i CPU-register
;*                                            med ett v�rde.
;*              BRLO (Branch If Lower)      : Hoppar till angiven adress om
;*                                            resultatet fr�n f�reg�ende
;*                                            j�mf�relse blev negativt, vilket
;*                                            indikeras genom att N-flaggan
;*                                            (Negative) i statusregistret
;*                                            SREG �r lika med noll.
;********************************************************************************/

; Makrodefinitioner:
.EQU LED1 = PORTB0 ; Lysdiod 1 ansluten till pin 8 (PORTB0).
.EQU LED2 = PORTB1 ; Lysdiod 2 ansluten till pin 9 (PORTB1).
.EQU LED3 = PORTB2 ; Lysdiod 3 ansluten till pin 10 (PORTB2).

.EQU TIMER0_MAX_COUNT = 6  ; 6 timeravbrott f�r 100 ms f�rdr�jning.
.EQU TIMER1_MAX_COUNT = 12 ; 12 timeravbrott f�r 200 ms f�rdr�jning.
.EQU TIMER2_MAX_COUNT = 18 ; 18 timeravbrott f�r 300 ms f�rdr�jning.

.EQU RESET_vect        = 0x00 ; Reset-vektor, utg�r programmets startpunkt.
.EQU TIMER2_OVF_vect   = 0x12 ; Avbrottsvektor f�r Timer 2 i Normal Mode.
.EQU TIMER1_COMPA_vect = 0x16 ; Avbrottsvektor f�r Timer 1 i CTC Mode.
.EQU TIMER0_OVF_vect   = 0x20 ; Avbrottsvektor f�r Timer 0 i Normal Mode.

;/********************************************************************************
;* .DSEG (Data Segment): Dataminnet - H�r lagras statiska variabler, specifikt
;*                       i b�rjan av dataminnet.
;********************************************************************************/
.DSEG
.ORG SRAM_START 
   counter0: .byte 1 ; static uint8_t counter0 = 0;
   counter1: .byte 1 ; static uint8_t counter1 = 0;
   counter2: .byte 1 ; static uint8_t counter2 = 0;

;/********************************************************************************
;* .CSEG (Code Segment): Programminnet - H�r lagras programkod och konstanter.
;********************************************************************************/
.CSEG 

;/********************************************************************************
;* RESET_vect: Programmet startpunkt, som �ven hoppas till vid system�terst�llning.
;*             Programhopp sker till subrutinen main f�r att starta programmet.
;********************************************************************************/
.ORG RESET_vect
   RJMP main

;/********************************************************************************
;* TIMER2_OVF_vect: Avbrottsvektor f�r Timer 2 i Normal Mode, som hoppas till
;*                  var 16.384:e ms. Programhopp sker till motsvarande
;*                  avbrottsrutin ISR_TIMER2_OVF f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER2_OVF_vect
   RJMP ISR_TIMER2_OVF

;/********************************************************************************
;* TIMER1_COMPA_vect: Avbrottsvektor f�r Timer 1 i CTC Mode, som hoppas till
;*                    var 16.384:e ms. Programhopp sker till motsvarande
;*                    avbrottsrutin ISR_TIMER1_COMPA f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER1_COMPA_vect
   RJMP ISR_TIMER1_COMPA

;/********************************************************************************
;* TIMER0_OVF_vect: Avbrottsvektor f�r Timer 0 i Normal Mode, som hoppas till
;*                  var 16.384:e ms. Programhopp sker till motsvarande
;*                  avbrottsrutin ISR_TIMER0_OVF f�r att hantera avbrottet.
;********************************************************************************/
.ORG TIMER0_OVF_vect
   RJMP ISR_TIMER0_OVF

;/********************************************************************************
;* ISR_TIMER0_OVF: Avbrottsrutin f�r Timer 0 i Normal Mode, som �ger rum var 
;*                 16.384:e ms vid overflow (uppr�kning till 256, d� r�knaren 
;*                 blir �verfull). Ungef�r var 100:e ms (var 6:e avbrott) 
;*                 togglas lysdiod LED1.
;********************************************************************************/
ISR_TIMER0_OVF:
   LDS R24, counter0
   INC R24
   CPI R24, TIMER0_MAX_COUNT
   BRLO ISR_TIMER0_OVF_end
   OUT PINB, R16
   CLR R24
ISR_TIMER0_OVF_end:
   STS counter0, R24
   RETI
   
;/********************************************************************************
;* ISR_TIMER1_COMPA: Avbrottsrutin f�r Timer 1 i CTC Mode, som �ger rum var 
;*                   16.384:e ms vid vid uppr�kning till 256. Ungef�r var 
;*                   200:e ms (var 12:e avbrott) togglas lysdiod LED2.
;********************************************************************************/
ISR_TIMER1_COMPA:
   LDS R24, counter1
   INC R24
   CPI R24, TIMER1_MAX_COUNT
   BRLO ISR_TIMER1_COMPA_end
   OUT PINB, R17
   CLR R24
ISR_TIMER1_COMPA_end:
   STS counter1, R24
   RETI

;/********************************************************************************
;* ISR_TIMER2_OVF: Avbrottsrutin f�r Timer 2 i Normal Mode, som �ger rum var 
;*                 16.384:e ms vid overflow (uppr�kning till 256, d� r�knaren 
;*                 blir �verfull). Ungef�r var 300:e ms (var 18:e avbrott) 
;*                 togglas lysdiod LED3.
;********************************************************************************/
ISR_TIMER2_OVF:
   LDS R24, counter2
   INC R24
   CPI R24, TIMER2_MAX_COUNT
   BRLO ISR_TIMER2_OVF_end
   OUT PINB, R18
   CLR R24
ISR_TIMER2_OVF_end:
   STS counter2, R24
   RETI

;/********************************************************************************
;* main: Initierar systemet vid start. Programmet h�lls sedan ig�ng s� l�nge
;*       matningssp�nning tillf�rs.
;********************************************************************************/
main:

;/********************************************************************************
;* setup: S�tter lysdiodernas pinnar till utportar samt aktiverar timerkretsarna
;*        s� att avbrott sker var 16.384:e millisekund f�r respektive timer.
;********************************************************************************/
setup:
   LDI R16, (1 << LED1) | (1 << LED2) | (1 << LED3)
   OUT DDRB, R16
   LDI R16, (1 << LED1)
   LDI R17, (1 << LED2)
   LDI R18, (1 << LED3)
   LDI R24, (1 << CS02) | (1 << CS00)
   OUT TCCR0B, R24
   STS TIMSK0, R16
   LDI R24, (1 << WGM12) | (1 << CS12) | (1 << CS10)
   STS TCCR1B, R24
   LDI R24, high(256)
   STS OCR1AH, R24
   LDI R24, low(256)
   STS OCR1AL, R24
   LDI R24, (1 << OCIE1A)
   STS TIMSK1, R24
   LDI R24, (1 << CS22) | (1 << CS21) | (1 << CS20)
   STS TCCR2B, R24
   STS TIMSK2, R16
   SEI
   
/********************************************************************************
* main_loop: Kontinuerlig loop som h�ller ig�ng programmet.
********************************************************************************/
main_loop:   
   RJMP main_loop ; �terstartar kontinuerligt loopen.