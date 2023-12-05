#ifndef STATUSMANAGER_HPP
#define STATUSMANAGER_HPP

#include <RGBLed.h>

#define LED_ONBOARD 15
#define LED_RED 13
#define LED_BLUE 10
#define LED_GREEN 8
#define LED_BRIGHTNESS 50

class StatusManager
{
private:
    static RGBLed led;

    StatusManager() = delete;
    ~StatusManager() = delete;

public:
    static void setIdle()
    {
        led.off();
    }

    static void wifiConnecting()
    {
        led.setColor(RGBLed::YELLOW);
        led.flash(RGBLed::YELLOW, 250, 100);
    }

    static void throwDetected()
    {
        led.setColor(RGBLed::BLUE);
    }
    // handle peak detection
    static void peakDetected()
    {
        led.setColor(RGBLed::RED);
    }
};

RGBLed StatusManager::led(LED_RED, LED_GREEN, LED_BLUE, RGBLed::COMMON_CATHODE);

#endif