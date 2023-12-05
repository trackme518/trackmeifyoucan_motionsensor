import com.krab.lazy.*;
LazyGui gui = null;

boolean loadedGUI = false;

PFont fontMedium;
PFont fontLarge;

String defaultSSID = "3motion";
String defaultWiFiPass = "datainmotion";

int defaultHostIpId = 233;

String selectedMidiDeviceName = "";

//import peasy.PeasyCam;
//PeasyCam cam;

void mousePressed() {
  if (initialized) {
    moduleManager.getSelected(mouseX, mouseY);
  }
}

void mouseReleased() {
  //println("mouse released");
  if (initialized) {
    moduleManager.deselect();
  }
}

void mouseEntered() {
}

void mouseExited() {
}

void keyPressed() {
  if (key==' ') { //start timeline audio playback
    if (synth.playbackBank!=null) {
      synth.playbackBank.play(0);
    }
  } else if (key=='c') {
    //connectWifi();
  }
}

//======================================================================
void initGUI() {
  //gui = new LazyGui(this);
  gui = new LazyGui(this, new LazyGuiSettings()
    // set as false to not load anything on startup, true by default
    .setLoadLatestSaveOnStartup(false)
    // expects filenames like "1" or "auto.json", overrides 'load latest'
    //.setLoadSpecificSaveOnStartup("1")
    // controls whether to autosave, true by default
    .setAutosaveOnExit(false)
    );
  gui.hide("saves"); // hide anything at this path (the prefix stack applies here like everywhere else)
  gui.hide("options"); //these are visual GUI options - hide from user
  gui.hide("windows");
  gui.hide("context lines");

  //Genral GUI set ------------------------
  gui.button("connect");
  gui.button("disconnect");

  gui.toggle("replay/record data", false);
  gui.toggle("replay/replay data", false);


  //gui.radio("my IP:", localIPs, localIP);

  gui.button("offset position");
  gui.button("calibrate IMU");

  gui.button("restart");
  gui.button("factory reset");

  gui.toggle("render wallpaper", true);
  //gui.button("debug");

  //WiFi GUI set ------------------------
  gui.button("WiFi/connect2WiFi");
  gui.text("WiFi/SSID", defaultSSID );
  gui.text("WiFi/WiFi Password", defaultWiFiPass );
  gui.slider("WiFi/host IP id", defaultHostIpId); //gui.sliderSet("x", floatToSet);
  gui.button("WiFi/reset WiFi setup");

  //OSC GUI set ------------------------
  gui.toggle("OSC/OSC proxy", enableOscProxy);
  gui.slider("OSC/OSC port", defaultOSCport);
  gui.slider("OSC/OSC proxy port", oscProxyPort);
  gui.text("OSC/set OSC prefix", prefix ); //UNTESTED TBD
  gui.button("OSC/save settings");

  //MIDI GUI set ------------------------
  gui.toggle("MIDI/MIDI proxy", enableMIDIproxy);

  //General GUI set ------------------------
  gui.button("save settings");
  loadedGUI = true;
}
//-----------------------------------------------
void updateGUI() {
  //-----------------------------
  //MIDI
  enableMIDIproxy  = gui.toggle("MIDI/MIDI proxy", enableMIDIproxy);//update boolean that is checked inside audio tab
  if (synth!=null) {
    if ( synth.MIDIenabled != enableMIDIproxy ) {
      synth.MIDIenabled = enableMIDIproxy;
      if (synth.MIDIenabled) {
        synth.openMidiDevice(synth.midiDevice);
      } else {
        synth.closeMidiDevice(synth.midiDevice);
      }
    }
  }

  if (synth !=null) {

    if ( synth.playbackBank != null ) {
      synth.playbackBank.loop = gui.toggle("loop playback", synth.playbackBank.loop);
      boolean startPlayback = gui.toggle("playback", false);
      if ( startPlayback != synth.playbackBank.playbackStarted) {
        if (startPlayback) {
          synth.playbackBank.play(0);
        } else {
          synth.playbackBank.stopPlaylist();
        }
      }
    }

    String selectedMidiDevice = gui.radio("MIDI/MIDI device:", synth.avaliableMidiDevicesNames, synth.midiDeviceName );
    if (!gui.isMouseOutsideGui()) {//only when hovering over GUI
      if ( !selectedMidiDeviceName.equals(selectedMidiDevice) ) { //on change hack
        selectedMidiDeviceName = selectedMidiDevice; //prevent multiple triggers
        if (enableMIDIproxy) {
          synth.openMidiDevice( synth.getMidiDeviceByName(selectedMidiDevice) ); //open selected MIDI device on change
        }
      }
    }
  }
  //-------------------------
  //select SERIAL interface
  if (serialManager!=null) {
    serialEnabledGlobal = gui.toggle("SERIAL enabled", serialManager.serialEnabled);//update boolean that is checked inside serial tab
    if ( serialManager.serialEnabled != serialEnabledGlobal ) {
      if (serialEnabledGlobal) {
        serialManager.startSerialScan();
      } else {
        serialManager.stopSerialPortScan();
        serialManager.closeSerial(); //serialManager.serialEnabled = false
      }
    }
  }
  //-------------
  //OSC
  enableOscProxy = gui.toggle("OSC/OSC proxy", enableOscProxy);//update boolean that is checked inside OSC tab
  if ( gui.button("OSC/save settings") ) {
    prefix = gui.text("OSC/set OSC prefix", prefix ); //UNTESTED TBD
    oscProxyPort = floor( gui.slider("OSC/OSC proxy port", oscProxyPort) ); //gui.sliderSet("x", floatToSet);
    defaultOSCport = floor( gui.slider("OSC/OSC port", defaultOSCport) );
    //we need to save the settings to modules before changin the setting in the app itself
    println("save OSC changes to modules");
    for (int i=0; i<moduleManager.modules.size(); i++) {
      Module m = moduleManager.modules.get(i);
      if (  m.remoteAddress.port() !=  defaultOSCport) { //change only if it differs
        m.setport( defaultOSCport );
      }
      m.setprefix( gui.text("OSC/set OSC prefix", prefix ) ); //UNTESTED TBD
    }
    //change App OSC settings as well
    initOSC(); //reinitialize
  }
  //---------------
  // getter that is only true once after being clicked and then switches to false
  if (gui.button("connect")) {
    if (!serialEnabledGlobal) { //we are using WiFi
      WiFiConnect connectThread = new WiFiConnect (true);
      //connect(true);
    } else { //we are using Serial
      connectSerial();
    }
  }
  if (gui.button("disconnect")) {
    if (!serialEnabledGlobal) { //we are using WiFi
      WiFiConnect connectThread = new WiFiConnect(false);
      //connect(false);
    } else { //we are using Serial
      disconnectSerial(); //send disconnect command over serial port
    }
  }
  if (gui.button("WiFi/connect2WiFi")) {
    connectWifi();
  }

  /*
  if (gui.button("debug")) {
   debug();
   }
   */
  //-----------------------------------------------
  boolean guirecord = gui.toggle("replay/record data", false); //see record tab
  if (guirecord != recorder.recordingEvents) {
    recorder.recordingEvents = guirecord;
    if (recorder.recordingEvents) {
      recorder.startRecEvent();
    } else {
      recorder.stopRecEvent();
    }
  }

  boolean guireplay = gui.toggle("replay/replay data", false); //see record tab
  if (guireplay != replay.replaying) {
    if (guireplay) {
      replay.play();
    } else {
      replay.stopReplay();
    }
  }

  if ( gui.button("replay/analyze data") ) {
    replay.init();
    replay.analyzeData();
  }
  //-------------------------------

  boolean guiRenderWallpaper = gui.toggle("render wallpaper");
  if (wallpaper.renderWallpaper != guiRenderWallpaper) {
    wallpaper.renderWallpaper  = guiRenderWallpaper;
  }
  //localIP = gui.radio("my IP:", localIPs, localIP);
}

//================================================================
/*
//its tanking performance - replaced with wallpaper class based on shaders - see wallpaper tab
 //slightly out of scope background
 void renderBackground() {
 float margin = 44;
 float density =1.0/1000.0;
 //fill(100,100,100);
 //fill(0);
 noStroke();
 float s = width;
 //translate(margin, margin);
 for (float incr = s; incr > 2; incr=incr/2) {
 float z = incr/100;
 for (float x = 0; x <= s; x += incr) {
 for (float y = 0; y <= s; y += incr) {
 float noize = noise(x * density, y * density, (float)frameCount/1000);
 
 float digit = floor(noize*50);
 if (digit % 2 == 0) {
 int randcol = int( random(20, 100) );
 fill(randcol);
 rect(x, y, 4, 4);
 }
 }
 }
 }
 }
 */
