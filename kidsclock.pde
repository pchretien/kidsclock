
#include <avr/interrupt.h>
#include <avr/io.h>

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT

#define RED_LED 8
#define RESET 2
#define GREEN_LED 11
#define BOARD_LED 13

#define NIGHT_TIME 36000 // 10*60*60
#define DAY_TIME 86400 // 24*60*60

int led13 = HIGH;
long counter = 0;
long stepStack = 0;
long seconds = 0;

// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  counter++;  
  if(!(counter%1000))
  {
    // enqueue step message
    stepStack++;
  }
};

void startup()
{
  stepStack = 0;
  seconds = 0;
    
  int led = 0;
  for(int i=0; i<5; i++)
  {
    digitalWrite(RED_LED, led);
    digitalWrite(GREEN_LED, led^1);
    led ^= 1;
    delay(500);
  }
  
  digitalWrite(RED_LED, HIGH);
  digitalWrite(GREEN_LED, LOW);
}

void setup()
{
  pinMode(RESET, INPUT);
  pinMode(RED_LED, OUTPUT);  
  pinMode(GREEN_LED, OUTPUT); 
  pinMode(BOARD_LED, OUTPUT); 
  
  //Timer2 Settings: Timer Prescaler /64, 
  TCCR2A |= (1<<CS22);    
  TCCR2A &= ~((1<<CS21) | (1<<CS20));     
  // Use normal mode
  TCCR2A &= ~((1<<WGM21) | (1<<WGM20));  
  // Use internal clock - external clock not used in Arduino
  ASSR |= (0<<AS2);
  //Timer2 Overflow Interrupt Enable
  TIMSK2 |= (1<<TOIE2) | (0<<OCIE2A);  
  RESET_TIMER2;               
  sei();
  
  startup();  
}

void loop()
{   
  int reset = digitalRead(RESET);
  if( reset == HIGH )
  {
    //startup();
  }
  
  if(stepStack)
  {
    // Toggle the LED
    led13 ^= 1;
    digitalWrite(13, led13); 
    
    seconds ++;    
    stepStack--; 
  }
  
  if( seconds > DAY_TIME )
  {
    seconds = 0;    
  }
  
  if( seconds > NIGHT_TIME )
  {
    digitalWrite(RED_LED, LOW);
    digitalWrite(GREEN_LED, HIGH);
  }
  else
  {
    digitalWrite(RED_LED, HIGH);
    digitalWrite(GREEN_LED, LOW);
  }
}

