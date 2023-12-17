# Data in Motion - Wireless motion sensor with OSC that makes music - Trackmeifyoucan

## About
We have developed wireless motion sensors that send OSC events, including 3D rotation and acceleration, and detect throws and catches. You can recieve data directly in any DAW (think Ableton, Protools, Reaper…) to receive the events and map them to sound. This is NO CODE PLUG & PLAY project. However, we also provide extensive posibilities for people, who can and want to code using Touchdesigner, Processing, Python and more. Project started as a university research at Czech Technical University in Prague (Prague,CZ) and we collaborate with [The Tangible Music Lab](https://tamlab.kunstuni-linz.at/) (Linz, AT), [Sync-ID group](https://www.htw-dresden.de/hochschule/fakultaeten/info-math/forschung/tactile-vision/sync-id) (Dresden,DE) and [UMIACS](https://www.umiacs.umd.edu/), Maryland University (College Park, Maryland, USA). 

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

1. Power ON the sensor
2. Wait for WiFi to start - connect to "3motion", password "datainmotion"
3. Make sure that sensor is sending data to your PC - you have two options:
    - Use our controlApp
        - Inside the controlApp click connect
        - Enable OSC proxy ( you are using OSC plugins inside DAW / Python / Processing ) OR enable MIDI proxy (choose MIDI device that you can recieve inside DAW)
    - set your PC IP to static.
        - sensors send data to X.X.X.230 IP by default. Where X can is range of your WiFi network. If you are not using dedeicated router you should set your PC IP to 11.11.11.230 (can be changed). 

### NO CODE in any DAW (Ableton, Reaper, Logic,...)

#### Ableton
Ableton does not natively supports OSC (Open Sound Control protocol). You have two options:
1. Use our plugins to recieve OSC messages in Ableton (you will need Ableton version 11+)
2. Use our controlApp to convert OSC messages to MIDI and than recieve MIDI inside Ableton (works for any version) Please note that when using MIDI you will loose some resolution.

##### Plugins to recieve OSC
* OSCmapper
    * Use this to map any named OSC attribute to any Ableton effect parameter, for example you can map "/motion/idofsensor/ypr/y" to track volume, track pan or parameter of the delay effect....
* oscToMidiNote
    * Use to send MIDI note on OSC message recieved. Typically you use this for event "/catch"
* noteTimeOut
    * lorem ipsum
* mapperRow
    * lorem ipsum

Drag & drop the downloaded plugin to Ableton MIDI track - you will see the plugin appears at the bottom. With "OSCmapper" set the OSC message name you want to recieve (ie "/motion/sensorOSCname/ypr/y" change "sensorOSCname" to your sensor ID). Then set minimum and maximum values, in case of YPR minimum would be 0 and maximum 360. Click "list" button near the track and effect dropdown menu. Choose which track you want to control (ie "Track 1"), choose what effect on that track you want to control (ie "volume mixer"). You should see values changing as you move the sensor.

##### Download
[Download all plugins](https://github.com/trackme518/trackmeifyoucan_motionsensor/raw/main/Ableton/Ableton11+/MaxOSCMIDIEffects/MaxOSCMIDIEffects.zip)

![Screenshot of OSCmapper plugin inside Ableton](/Ableton/Ableton11+/images/oscmapperscreenshot.jpg)


#### Ardour
[Ardour](https://ardour.org/) is a third party, cross-platform open source DAW (we are not affiliated) with native OSC support. It has all the features you want from DAW, including VST support. You can build it for free or download the build for your platform for 1 usd. 

TBD

#### Reaper
TBD

### Processing Java
1. ![Download Processing](https://processing.org/download).
2. ![Download libraries (OSCp5, toxicLibs, udp)](/Processing/processingLibraries.zip). 
3. Unzip libraries and copy the contents into your Processing Libraries folder (on Windows that would typically be `C:\Users\yourname\Documents\Processing\libraries`)
4. Open and run examples (double click .pde file and click play icon inside Processing PDE)

* simpleSingleSensorWiFi
    * Basic example for one sensor and how to recieve data over WiFi
* simpleSingleSensorSerial
    * Basic example for one sensor and how to recieve data over Serial (USB). You need to provide the Serial name (something like "COM3" on Windows)
* singleSensorSerialAutomatic
    * single sensor connected over serial that can automatically pair with the right serial port - using object oriented class 
* moduleManagerAPI
    * complex example on how to manage multiple sensors and recieve data over WiFi OR USB Serial. It also illustrates how you can automate the connect requests even if do not know the serial name or IP of the sensor. Includes all OSC commands inside Module class.

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

## Contribute and help
* you found a bug - create an issue here 
* you made a project using provided examples - we encourgae you to share it - you can send us photos and or video to [contact](https://trackmeifyoucan.com/contact/) with "project showcase" in subject. We will share it on the website, creating a gallery of cool projects. You can also share your code here - create a pull request or send us zipped file over email / wetransfer.
* you developed new feature / created API for new software - create a pull request or send us the code over [email](https://trackmeifyoucan.com/contact/), we will include it in this repository and add a readme for it. 

## License
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). When using or distributing the code, give a credit in the form of "DataInMotion (https://trackmeifyoucan.com)". Please refer to the [licence](https://creativecommons.org/licenses/by-nc-sa/4.0/). Author is not liable for any damage caused by the software. Usage of the software is completely at your own risk. For commercial licensing please [contact](https://trackmeifyoucan.com/contact/) us.  
