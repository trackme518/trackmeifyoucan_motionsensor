#ifndef STATUSMANAGER_HPP
#define STATUSMANAGER_HPP

class StatusManager {
private:
  //define LED pins
  const int LED_ONBOARD = 15;
  const int LED_RED = 13;
  const int LED_GREEN = 8;
  const int LED_BLUE = 10;
  //define PWM properties for esp32
  const int freq = 5000;
  const int resolution = 8;

  long lastmillis = 0;
  int blinkOnInterval = 100;
  int blinkOffInterval = 1000;
  boolean blinkOn = true;

  boolean colorSet = false;

public:
  int mode = 0;
  int brightness = 10;
  int maxColorValue = 255;

  int rgb[3] = { 0, 0, 0 };

  int flashrgb[3] = { 0, 0, 0 };
  boolean flash = false;
  long flashTimer = 0;
  int flashDuration = 100;

  int green[3] = { 0, 255, 0 };
  int blue[3] = { 0, 0, 255 };
  int red[3] = { 255, 0, 0 };
  int yellow[3] = { 255, 255, 0 };
  int black[3] = { 0, 0, 0 };

  void begin() {
#if defined(ESP32)
    ledcSetup(0, freq, resolution);
    ledcSetup(1, freq, resolution);
    ledcSetup(2, freq, resolution);

    ledcAttachPin(LED_RED, 0);
    ledcAttachPin(LED_GREEN, 1);
    ledcAttachPin(LED_BLUE, 2);
#else
    pinMode(LED_RED, OUTPUT);
    pinMode(LED_GREEN, OUTPUT);
    pinMode(LED_BLUE, OUTPUT);
#endif

    setBrightness(10);  //lower brightness to 10%
  }

  void setBrightness(int bright) {
    brightness = bright;
    maxColorValue = round((255.0 / 100.0) * (float)brightness);  //10%=25.5 round = 26
  }

  void run() {

    if (flash) {
      if (millis() - flashTimer >= flashDuration) {
        flash = false;
        setColor(black);
        return;
      }
      setColor(flashrgb);
      return;
    }

    if (blinkOn) {
      //---
      if (!colorSet) {
        setColor(rgb);
        colorSet = true;
      }
      //---
      if (millis() - lastmillis >= blinkOnInterval) {  //Update every second
        lastmillis = millis();
        blinkOn = false;
        colorSet = false;
      }
    } else {
      if (!colorSet) {  //do not utilize pins when light is turned off
        colorSet = true;
        setColor(black);
      }
      //----
      if (millis() - lastmillis >= blinkOffInterval) {  //Update every second
        lastmillis = millis();
        blinkOn = true;
        colorSet = false;
      }
    }
    //--------
  }
  /*
  int map(int old_value, int old_min, int old_max, int new_min, int new_max) {
    int new_value = ((old_value - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min;
    return new_value;
  }
*/
  void
  copyA(int* src, int* dst, int len) {
    memcpy(dst, src, sizeof(src[0]) * len);
  }

  void setColor(int mycol[3]) {
    //analogWrite(LED_RED, R);
    //analogWrite(LED_GREEN, G);
    //analogWrite(LED_BLUE, B);
    ledcWrite(0, (mycol[0] * maxColorValue) / 255);  //avoid using floats to save memory and performance
    ledcWrite(1, (mycol[1] * maxColorValue) / 255);
    ledcWrite(2, (mycol[2] * maxColorValue) / 255);
  }

  void setIdle() {  // OK status
    copyA(green, rgb, 3);
  }

  void wifiConnecting() {  //wifi connecting
    copyA(yellow, rgb, 3);
  }

  void error() {  //something bad happened
    copyA(red, rgb, 3);
  }

  void throwDetected() {
    copyA(blue, flashrgb, 3);
    flashTimer = millis();
    flash = true;
  }
  // handle peak detection
  void peakDetected() {
  }
};

#endif
