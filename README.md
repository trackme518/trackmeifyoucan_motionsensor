# Data in Motion - Wireless motion sensor with OSC that makes music - Trackmeifyoucan

## About
We have developed wireless motion sensors that send OSC events, including 3D rotation and acceleration, and detect throws and catches. You can recieve data directly in any DAW (think Ableton, Protools, Reaper…) to receive the events and map them to sound. This is NO CODE PLUG & PLAY project. However, we also provide extensive posibilities for people, who can and want to code using Touchdesigner, Processing, Python and more. 

We sell readymade hardware sensors with software examples, offering paid IT support and keyturn solutions at https://trackmeifyoucan.com. 

Sensors can be used as an innovative music controller for spatial audio, to sonify dance performance, jugggling, pole dance or anything else. Furthermore, we also have a standalone application in Java for MacOS, Windows, and Linux. You can sue the app to change sensor settings and verify it is working - you don't need it for reading the data elsewhere. 

### Use-cases
* sonify movement performance (think dance, juggling, pole dance)
* Intuitively control spatial audio in real-time
* Augment traditional musical instruments.
* Create interactive installations
* track performance (sensor inside tennis racket, football etc.)
* create digital a clone of the product in showroom and control it using the real world object with the sensor attached
* control theater moving head lights

## Why?
* Spatial audio control is cumbersome with existing interfaces -> we provide an easy-to-use haptic controller so sound engineers/musicians can easily change sound direction during concerts in real time —> qualitative improvement.
* Movement performers (dancers, circus, theater) want to have music during their performance. They are currently using playback music. We can provide sensors and software to create music based on their movement, enabling them to improvise and react to the audience in real-time without needing an extra person to control the music: new market / new possibilities —> qualitative improvement.
* Lighting control - the wireless sensor can trigger the next scene or control moving light heads on stage—qualitative improvement.
* All similar existing sensors offer only a single connection interface such as Bluetooth -> we offer Wi-Fi & Serial. Wi-Fi has a longer range and can integrate with existing network infrastructure such as routers and switches —> quantitative improvement.

## For who?
* Musicians
* Sound engineers
* Movement performers
* Theater
* Lighting

## How to use - Software

### NO CODE in any DAW (Ableton, Reaper, Logic,...)

#### Ableton

See [Ableton 11+](Ableton/Ableton11+/readme.md)

### Processing Java

### Python
TBD
### Touchdesigner
TBD
## Firmware

### How to flash firmware
1. Download firmware build XXXXX and unzip it
2. Download flash script
3. Move files from build folder into "build" folder inside the flash script
4. Run the .bat script, it will open command line
5. Type the name of the serial port that the board is connected to (for example "COM3"), press any key
6. Confirm the name of the serial port by pressing any key
7. Watch the upload progress, after it finished, reset or unplug the board - you are done.

### How to modify firmware
1. Install [Arduino](https://www.arduino.cc/en/software "Arduino") Arduino IDE 2.2.1
2. Add board definition: https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_dev_index.json
3. Install board definition for esp32-dev 2.0.14 (version matters!)
4. Install additional arduino libraries (MPU6050, OSC)
5. Compile and upload to board

## Instructions for how people can help.

XXXXX

## License
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). When using or distributing the code, give a credit in the form of "DataInMotion (https://trackmeifyoucan.com)". Please refer to the [licence](https://creativecommons.org/licenses/by-nc-sa/4.0/). Author is not liable for any damage caused by the software. Usage of the software is completely at your own risk. For commercial licensing please [contact](https://trackmeifyoucan.com/contact/) us.  
