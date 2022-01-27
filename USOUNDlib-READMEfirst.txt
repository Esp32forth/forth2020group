 
Before using the ultrasound library
you need to add to  esp32forth.ino

the PULSEIN word

which is defined as follows :

Y(pulsein, n0 = pulseIn(n0, HIGH))  \


( I defined it after analogin
  Y(analogRead, n0 = analogRead(n0)) \  )

we are still on development so, give us feedback
of your success. 

Pinout and connection :  
I had no problem using the HC-SRC04 module
with vcc of the module to VIN (5V) of the ESP32
gnd   to  gnd  of the esp32
trig connected to pin GPIO19 of esp32
echo connected to pin GPIO18 of esp32


