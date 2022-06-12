/*
*  Copyright PeterForth 2022 
*  use freely according MIT license
*  redistribution only possible with
*  acknowledgment to the author 
*  more information of the project https://esp32.forth2020.org
*  tft libraries of Bodmer https://github.com/Bodmer/TFT_eSPI
*  download ESP32forth from Brad Nelson 
*  https://esp32forth.appspot.com/ESP32forth.html
*/

#define nn0 ((uint16_t *) tos)
#define nn1 (*(uint16_t **) &n1)

#include <SPI.h>
#include <TFT_eSPI.h> 
TFT_eSPI tft = TFT_eSPI();

void setuptouch(void) {
  uint16_t calData[5] = { 235, 3234, 504, 3066, 0 };
  tft.setTouch(calData);
}
void setuptftdemo(void) {
  uint16_t calData[5] = { 235, 3234, 504, 3066, 0 };
  tft.setTouch(calData);  
  
  tft.init();
  tft.fillScreen(TFT_BLACK);  
  
  tft.setCursor(20, 10, 4);
  
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  
  tft.println("White Text\n");
  tft.println("Next White Text");
  
  tft.setCursor(10, 100);
  tft.setTextFont(2);
  tft.setTextColor(TFT_RED, TFT_WHITE);
  tft.println("Red Text, White Background");
  
  tft.setCursor(10, 140, 4);
  tft.setTextColor(TFT_GREEN);
  tft.println("Green text");
  
  tft.setCursor(70, 180);
  tft.setTextColor(TFT_BLUE, TFT_YELLOW);
  tft.println("Blue text");
 
  tft.setCursor(50, 220);
  tft.setTextFont(4);
  tft.setTextColor(TFT_YELLOW);
  tft.println("2020-06-16");
 
  tft.setCursor(50, 260);
  tft.setTextFont(7);
  tft.setTextColor(TFT_PINK);
  tft.println("20:35");
}

#define USER_WORDS \
  Y(tftdemo, setuptftdemo(); DROP) \
  Y(tftinit, tft.init(); DROP) \  
  Y(tftcls, tft.fillScreen(TFT_BLACK);) \
  Y(tftcursor, tft.setCursor(n1, n0); DROPn(2)) \
  Y(tftcursorink, tft.setCursor(n2,n1, n0); DROPn(2)) \
  Y(tftTextFont, tft.setTextFont(n0); DROP) \
  Y(tftTextColor, tft.setTextColor(n1,n0); DROPn(2)) \
  Y(tftprintln, tft.println(c0); DROP) \
  Y(tftprint, tft.print(c0); DROP) \
  Y(tftNum, tft.print(n0); DROP) \
  Y(tftNumln, tft.println(n0); DROP) \
  Y(tftCircle, tft.drawCircle(n3,n2,n1,n0); DROPn(3)) \
    Y(tftPixel, tft.drawPixel(n2,n1,n0); DROPn(3)) \ 
    Y(tftLine, tft.drawLine(n4,n3,n2,n1,n0); DROPn(5)) \ 
    Y(tftfillRect, tft.fillRect(n4,n3,n2,n1,n0); DROPn(5)) \ 
     Y(tftfillRRect, tft.fillRoundRect(n5,n4,n3,n2,n1,n0); DROPn(6)) \ 
     Y(tftRect, tft.drawRect(n4,n3,n2,n1,n0); DROPn(5)) \ 
     Y(tftHLine, tft.drawFastHLine(n3,n2,n1,n0); DROPn(4)) \ 
     Y(tftVLine, tft.drawFastVLine(n3,n2,n1,n0); DROPn(4)) \ 
     Y(tftfillCircle, tft.fillCircle(n3,n2,n1,n0); DROPn(4)) \
     Y(tftRotation,  tft.setRotation(n0); DROP) \ 
     Y(tftfillscreen, tft.fillScreen(n0); DROP) \ 
       Y(tftEllipse,  tft.drawEllipse(n4,n3,n2,n1,n0); DROPn(5)) \ 
       Y(tftfillEllipse,  tft.fillEllipse(n4,n3,n2,n1,n0); DROPn(5)) \ 
       Y(tftTriangle, tft.drawTriangle(n6,n5,n4,n3,n2,n1,n0); DROPn(7)) \ 
       Y(tftfillTriangle, tft.fillTriangle(n6,n5,n4,n3,n2,n1,n0); DROPn(7)) \
       Y(tfttouch, tft.getTouch(nn1, nn0); DROPn(2)) \ 
       Y(tftinittouch, setuptouch; DROP)  

 
