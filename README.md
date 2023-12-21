# Data in Motion - Wireless motion sensor with OSC that makes music - Trackmeifyoucan

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->
   * [About](#about)
      + [Use-cases](#use-cases)
   * [Why?](#why)
   * [For who?](#for-who)
   * [How to use - Software](#how-to-use-software)
      + [NO CODE in any DAW (Ableton, Reaper, Logic,...)](#no-code-in-any-daw-ableton-reaper-logic)
         - [MIDI](#midi)
         - [OSC](#osc)
         - [Recieve OSC](#recieve-osc)
         - [Send OSC / commands API](#send-osc-commands-api)
         - [OSC presets](#osc-presets)
         - [Ableton](#ableton)
            * [Plugins to recieve OSC](#plugins-to-recieve-osc)
            * [Download](#download)
         - [Ardour](#ardour)
         - [Reaper](#reaper)
      + [Processing Java](#processing-java)
      + [Python](#python)
      + [Touchdesigner](#touchdesigner)
   * [How to use - Hardware](#how-to-use-hardware)
      + [Connect sensor to your PC (standalone, router, AP)](#connect-sensor-to-your-pc-standalone-router-ap)
   * [Firmware](#firmware)
      + [How to flash firmware](#how-to-flash-firmware)
   * [Contribute and help](#contribute-and-help)
   * [Collaborators](#collaborators)
   * [License](#license)
<!-- TOC end -->

<!--- https://derlin.github.io/bitdowntoc/ -->
<!--- https://markdownbeautifier.com -->

<!-- TOC --><a name="about"></a>
## About
We have developed wireless motion sensors that send OSC events, including 3D rotation and acceleration, and detect throws and catches. You can recieve data directly in any DAW (think Ableton, Protools, Reaper…) to receive the events and map them to sound. This is NO CODE PLUG & PLAY project. However, we also provide extensive posibilities for people, who can and want to code using Touchdesigner, Processing, Python and more. Project started as a university research at Czech Technical University in Prague (Prague,CZ) and we collaborate with [The Tangible Music Lab](https://tamlab.kunstuni-linz.at/) (Linz, AT), [Sync-ID group](https://www.htw-dresden.de/hochschule/fakultaeten/info-math/forschung/tactile-vision/sync-id) (Dresden,DE) and [UMIACS](https://www.umiacs.umd.edu/), Maryland University (College Park, Maryland, USA). 

We sell readymade hardware sensors with software examples, offering paid IT support and keyturn solutions at https://trackmeifyoucan.com. 

Sensors can be used as an innovative music controller for spatial audio, to sonify dance performance, jugggling, pole dance or anything else. Furthermore, we also have a standalone application in Java for MacOS, Windows, and Linux. You can use the app to change sensor settings and to verify it is working - you don't need it for reading the data elsewhere. However, the [controlApp](https://github.com/trackme518/trackmeifyoucan_motionsensor/releases) offers additional functionality such as recording the OSC messages and replaying them later, can act as MIDI or OSC proxy and provides easy to use GUI.

<!-- TOC --><a name="use-cases"></a>
### Use-cases
* sonify movement performance (think dance, juggling, pole dance)
* Intuitively control spatial audio in real-time
* Augment traditional musical instruments.
* Create interactive installations
* track performance (sensor inside tennis racket, football etc.)
* create digital a clone of the product in showroom and control it using the real world object with the sensor attached
* control theater moving head lights

<!-- TOC --><a name="why"></a>
## Why?
* Spatial audio control is cumbersome with existing interfaces -> we provide an easy-to-use haptic controller so sound engineers/musicians can easily change sound direction during concerts in real time —> qualitative improvement.
* Movement performers (dancers, circus, theater) want to have music during their performance. They are currently using playback music. We can provide sensors and software to create music based on their movement, enabling them to improvise and react to the audience in real-time without needing an extra person to control the music: new market / new possibilities —> qualitative improvement.
* Lighting control - the wireless sensor can trigger the next scene or control moving light heads on stage—qualitative improvement.
* All similar existing sensors offer only a single connection interface such as Bluetooth -> we offer Wi-Fi & Serial. Wi-Fi has a longer range and can integrate with existing network infrastructure such as routers and switches —> quantitative improvement.

<!-- TOC --><a name="for-who"></a>
## For who?
* Musicians
* Sound engineers
* Movement performers
* Theater
* Lighting

<!-- TOC --><a name="how-to-use-software"></a>
## How to use - Software

1. Power ON the sensor
2. Wait for WiFi to start - connect to "3motion", password "datainmotion"
3. Make sure that sensor is sending data to your PC - you have two options:
    - Use our controlApp
        - Download latest release of stand-alone [controlApp](https://github.com/trackme518/trackmeifyoucan_motionsensor/releases) - you don't need to install it, just unzip it and run it.
        - Inside the controlApp click connect
        - Enable OSC proxy ( you are using OSC plugins inside DAW / Python / Processing, by default it will send to port 8888 ) OR enable MIDI proxy (choose MIDI device that you can recieve inside DAW)
    - set your PC IP to static.
        - sensors send data to X.X.X.230 IP by default. Where X can is range of your WiFi network. If you are not using dedeicated router you should set your PC IP to 11.11.11.230 (can be changed). 

<!-- TOC --><a name="no-code-in-any-daw-ableton-reaper-logic"></a>
### NO CODE in any DAW (Ableton, Reaper, Logic,...)
<!-- TOC --><a name="midi"></a>
We use three main approaches to creating audio based on movement:
* play audio sample at discrete event / threshold reached (throw / catch events triggering notes or audio files but you can also threshold rotation etc.)
* modulate synthetiser / instrument continously based on selected parameter (acceleration in x axis mapped to lfo etc)
* modulate premade song with volume envelope, panning or various effects (reverb, delay, wet/dry)

If you are looking for ways to play audio samples based on OSC / MIDI you can use [Ninjas2 sampler](https://github.com/clearly-broken-software/ninjas2/releases) (Windows/MacOS/Linux) or [samplv1](https://samplv1.sourceforge.io/) (Linux) - of course there might be a native sampler inside your DAW already (Simpler for Ableton) and there is plenty of commercial options. You can also check out more advanced [tx16wx](https://www.tx16wx.com/download/) (Windows/MacOS). VST plugins either come with an installer (it will copy the plugin to folder) or you need to place it inside your plugins folder manually ([Windows paths](https://helpcenter.steinberg.de/hc/en-us/articles/115000177084-VST-plug-in-locations-on-Windows)). 

#### MIDI
In case your DAW can not recieve OSC or you want simpler workflow you can use our controlApp to convert OSC messages to MIDI. On Windows you will need some sort of virtual MIDI device. In the controlApp click "MIDI" - click "MIDI device" and choose MIDI device you want to send the events to, than clik to toggle to enable "MIDI proxy".  

![Screenshot of MIDI settings inside controlApp](/documentation/MIDI_screenshot.png)

* noteOn - always note C (60), velocity 93, each sensor has its own channel (starting at 0)
* noteOff - always note C (60), velocity 93, each sensor has its own channel (starting at 0)
* CC 16 - yaw
* CC 17 - pitch
* CC 18 - roll
* CC 19 - airtime (how long it was flying before you catch it)
* CC 75 - acceleration X axis
* CC 76 - acceleration Y axis
* CC 77 - acceleration Z axis

CC stands for ControlChange - special general purpose MIDI event ([list](https://anotherproducer.com/online-tools-for-musicians/midi-cc-list/)). All MIDI values are beteween 0-127 range (Yaw, Pitch, Roll are remapped from 0-360, acceleration from -32767 to 32768, time in the air from 0 to defined maximum). You can use [Hexler Protokol](https://hexler.net/protokol) or [Midi View](https://hautetechnique.com/midi/midiview/) to monitor and debug the MIDI data.  

You can create your own MIDI instrument using fs2 SoundFont format. We recommend [Polyphone](https://www.polyphone-soundfonts.com/about-polyphone) to create instrument from individual sound samples. Of course you can just download existing instrument as well. ANother useful readymade plugin is the [LSP sampler](https://lsp-plug.in/?page=manuals&section=multisampler_x12) or see the [list of avaliable VST samplers](https://midination.com/vst/free-vst-plugins/free-sampler-vst-plugins/).

<!-- TOC --><a name="osc"></a>
#### OSC
All OSC messages are in format `/prefix/oscid/parameter`, for example:  `/motion/63607/ypr`. See the table below for all OSC messages that are sent from sensor to PC. You can recieve these messages in any software of your choice - see examples for Processing, Python, DAW... We encourage you to use our premade [controlApp](https://github.com/trackme518/trackmeifyoucan_motionsensor/releases) that can also record and replay the OSC data you have captured. You can use [Hexler Protokol](https://hexler.net/protokol) to monitor and debug OSC data as well. Furthermore, we have developed standalone [OSCreplay](https://github.com/trackme518/OSCreplay) software if you like to record your experiments into .CSV table (this functionality is included in controlApp as well but OSCreplay is instended for more universal for any OSC devices / traffic).  

<!-- TOC --><a name="recieve-osc"></a>
#### Recieve OSC

| pattern                 | typetag | min    | max      | description                                  |
| ----------------------- | ------- | ------ | -------- | -------------------------------------------- |
| /motion/63607/quat      | ffff    | 0      | 1        | rotation in Quaternion                       |
| /motion/63607/ypr/      | fff     | 0      | 360      | rotation in degrees yaw,pitch, roll          |
| /motion/63607/ypr/y     | f       | 0      | 360      | yaw                                          |
| /motion/63607/ypr/p     | f       | 0      | 360      | pitch                                        |
| /motion/63607/ypr/r     | f       | 0      | 360      | roll                                         |
| /motion/63607/aaWorld   | iii     | -32767 | 32768    | Acceleration adjusted for rotation & gravity |
| /motion/63607/aaWorld/x | i       | -32767 | 32768    |                                              |
| /motion/63607/aaWorld/y | i       | -32767 | 32768    |                                              |
| /motion/63607/aaWorld/z | i       | -32767 | 32768    |                                              |
| /motion/63607/aaReal    | iii     | -32767 | 32768    |                                              |
| /motion/63607/aa        | iii     | -32767 | 32768    |                                              |
| /motion/63607/raw       | fffffff |        |          | experimental WIP!                            |
| /motion/63607/throw     | T       | true   | true     |                                              |
| /motion/63607/catch     | i       | 0      | infinity | time in milliseconds spent in the air        |

* `quat` stands for Quaternion - rotation represented in 4 dimensions (helps to avoid gimbal lock)
* `ypr` stands for yaw, pitch, roll - rotation represented in degrees. Note that we are sending individual components as well.
* `aaWorld` stands for Acceleration that is adjusted for gravity vector and rotated using Quaternion reading (ie absolute acceleration)
* `throw` - is triggered when the sensor is in freefall
* `catch` - is trigerred if the sensor was previously in free fall and than we get suddent change in acceleration
* `raw` - is experimental mode that sends all the data in unprocessed form, currently unstable WIP (theoretically we can achieve 1000Hz polling rate)

<!-- TOC --><a name="send-osc-commands-api"></a>
#### Send OSC / commands API
These are optional commands you can send to sensor to change it's settings or behaviour. 

| pattern                 | typetag | description                           | response                       |
| ----------------------- | ------- | ------------------------------------- | ------------------------------ |
| /connect                | s\*     | send connect WiFi request             | null                           |
| /disconnect             | null    | stop sending data to this ip          | null                           |
| /connect/serial         | null    | stop sending data to this ip          | prefix/OSCID/connect/serial  T |
| /mode/serial            | T       | toggle between Serial=true/Wifi=false | prefix/OSCID/serialmode T      |
| /restart                | null    | restart controller                    | prefix/OSCID/response s        |
| /offset                 | null    | set zero orientation                  | null                           |
| /calibrate              | null    | calibrate IMU                         | null                           |
| /treshold/throw/set     | i       | change when we detect freefall        | null                           |
| /treshold/throw/get     | null    | get freefall threshold value          | null                           |
| /ssid/set               | s       | change WiFi SSID                      | null                           |
| /ssid/pass              | s       | change WiFi password                  | 32768                          |
| /wifi/reset             | null    | reset SSID WiFi and password          | prefix/OSCID/ssid & /pass s    |
| /factoryreset           | null    | revert to default                     | null                           |
| /preferences/osc/reset  | null    | reset OSC settings                    | null                           |
| /preferences/imu/reset  | null    | reset calibration data                | null                           |
| /preferences/wifi/reset | null    | delete WiFi settings                  | null                           |
| /port/set               | i       | change OSC port                       | null                           |
| /hostidip/set           | i       | chnage host id: X.X.X.Number          | null                           |
| /resetid                | null    | revert OSC id to default              | prefix/OSCID/newid s           |
| /id/set                 | s       | change OSC id                         | null                           |
| /prefix/set             | s       | change OSC prefix                     | null                           |

* `/connect` - if you send it without parameter, the sensor will start to send data to IP that the command was sent from. But you can also specify IP in String ("192.168.0.56") to force the sensor to start sending data to different PC. Sensor will by default send data to IP X.X.X.230. This default IP can be changed with command `/hostidip/set`
* `/hostidip/set` - change the last digit in the IP address (default X.X.X.230) where the sensor send the data when started by default. For example you would send 105 to change the default IP addres to X.X.X.105. Note that first three digits in the IP address are always dynamic. When you use sensor in standalone mode it will be 11.11.11.230 by default, but if you are using dedicated router with DHCP you can have different IP range.
* `/connect/serial` - this will force the sensor to start sending data over USB cable instead of WiFi (altought it can still be connected to the WiFi at the same time). It will auomatically trigger `/mode/serial` set to `true`. The sensor will reply with `prefix/OSCID/connect/serial`, you can listen for this reply to automatically determine to which Serial port the sensor is connected. 
* `/mode/serial` - toggle between sending data over WiFi (false) or Serial (true)

<!-- TOC --><a name="osc-presets"></a>
#### OSC presets
You can define your own OSC presets in JSON format inside [controlApp](https://github.com/trackme518/trackmeifyoucan_motionsensor/releases). In presets you can rename any OSC command's address and remap it's values. Presets are located in `data/presets/generic.json` folder. Simply copy the example `generic.json` file, rename it, change `name` parameter and adjust other values as you see fit. Than inside the controlApp click OSC -> toggle enable proxy and toggle enable preset. You can also adjust OSC proxy port. After this all messages that are send to controlApp will be redirected and remapped according to chosen preset file (you can have multiple files inside preset folder, just make sure to give them unique name attribute and filename).

Supported data types inside typetag:
* `f` - float
* `i` - integer
* `T` - boolean

Each command has defined `min` and `max` for incoming command and `min` and `max` for outgoing command. Value is remapped using those values. You also specify `index` - at which position from original command you are taking the value (so if the index is 2 you will take third value from the original command and remap it, 0 is the first one). You can have multiple outgoing commands for single incoming command. You can also have outgoing command with multiple values (just put commas between min, max and index numbers - typetag remains without commas).

<!-- TOC --><a name="ableton"></a>
#### Ableton
Ableton does not natively supports OSC (Open Sound Control protocol). You have two options:
1. Use our plugins to recieve OSC messages in Ableton (you will need Ableton version 11+)
2. Use our controlApp to convert OSC messages to MIDI and than recieve MIDI inside Ableton (works for any version) Please note that when using MIDI you will loose some resolution. See the chapter on MIDI above.

<!-- TOC --><a name="plugins-to-recieve-osc"></a>
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

<!-- TOC --><a name="download"></a>
##### Download
[Download all plugins](https://github.com/trackme518/trackmeifyoucan_motionsensor/raw/main/Ableton/Ableton11+/MaxOSCMIDIEffects/MaxOSCMIDIEffects.zip)

![Screenshot of OSCmapper plugin inside Ableton](/Ableton/Ableton11+/images/oscmapperscreenshot.jpg)


<!-- TOC --><a name="ardour"></a>
#### Ardour
[Ardour](https://ardour.org/) is a third party, cross-platform open source DAW (we are not affiliated) with native OSC support. It has all the features you want from DAW, including VST support. You can build it for free or download the build for your platform for 1 usd. 

TBD

<!-- TOC --><a name="reaper"></a>
#### Reaper
TBD

<!-- TOC --><a name="processing-java"></a>
### Processing Java
1. ![Download Processing](https://processing.org/download).
2. ![Download libraries (OSCp5, toxicLibs, udp)](/Processing/processingLibraries.zip) - note that we are using modified version of some of the libraries so make sure to use ones from this repository. 
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

<!-- TOC --><a name="python"></a>
### Python
TBD
<!-- TOC --><a name="touchdesigner"></a>
### Touchdesigner
TBD

<!-- TOC --><a name="how-to-use-hardware"></a>
## How to use - Hardware
Please make sure that you connect the battery right way, look for +/- labels on the PCB.

![Make sure you connect battery to +/- in right way](/documentation/battery_polarity2compress.png)

<!-- TOC --><a name="connect-sensor-to-your-pc-standalone-router-ap"></a>
### Connect sensor to your PC (standalone, router, AP)
You can connect the sensor to your PC in various ways:

1. USB serial - connect the sensor to your PC with USB-C cable, make sure that B dip switch is OFF
2. WiFi
    - standalone mode - just turn on the sensor and it will create a new WiFi network for you (defaults to "3motion" with password "datainmotion"). Connect to WiFi and start [controlApp](https://github.com/trackme518/trackmeifyoucan_motionsensor/releases) or other examples. Please note that the first sensor that is turned on will try to find and connect to default WiFi network, if there is no such network it will create an acces point. All other sensors will than connect to this master sensor. Max 3 other sensors can be connected to master. If you need to connect more sensors you will need dedicated router. We also recommend using dedicated router / AP for better performance during public shows. 
    - client mode - you can use your exsiting WiFi network / router. Either change your network to match the default ("3motion" with password "datainmotion") or change settings on the sensor to connect to your network. This is obligatory if you have more than 3 sensors.

![Make sure you connect battery to +/- in right way](/documentation/Ap-modes.jpg)

<!-- TOC --><a name="firmware"></a>
## Firmware

<!-- TOC --><a name="how-to-flash-firmware"></a>
### How to flash firmware
If you bought allinone sensors you don't need to flash the firmware. This is only intended for upgrading or when you have shield only (without microcontroller).

1. Download [latest firmware build](arduino/flashToolWin.zip) with flash script and unzip it
2. Run the .bat script, it will open command line
3. Type the name of the serial port that the board is connected to (for example "COM3"), press any key
4. Confirm the name of the serial port by pressing any key
5. Watch the upload progress, after it finishes, unplug the board to reset it - you are done.

<!-- TOC --><a name="contribute-and-help"></a>
## Contribute and help
* you found a bug - create an issue here 
* you made a project using provided examples - we encourgae you to share it - you can send us photos and or video to [contact](https://trackmeifyoucan.com/contact/) with "project showcase" in subject. We will share it on the website, creating a gallery of cool projects. You can also share your code here - create a pull request or send us zipped file over email / wetransfer.
* you developed new feature / created API for new software - create a pull request or send us the code over [email](https://trackmeifyoucan.com/contact/), we will include it in this repository and add a readme for it. 

<!-- TOC --><a name="collaborators"></a>
## Collaborators
* [@pavelhusa](https://github.com/pavelhusa)
* [@kukas](https://github.com/kukas)

<!-- TOC --><a name="license"></a>
## License
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). When using or distributing the code, give a credit in the form of "DataInMotion (https://trackmeifyoucan.com)". Please refer to the [licence](https://creativecommons.org/licenses/by-nc-sa/4.0/). Author is not liable for any damage caused by the software. Usage of the software is completely at your own risk. For commercial licensing please [contact](https://trackmeifyoucan.com/contact/) us.  
