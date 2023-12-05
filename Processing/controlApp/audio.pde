import java.util.Arrays;

import javax.sound.midi.MidiSystem;
import javax.sound.midi.MidiDevice;
import javax.sound.midi.Synthesizer;
import javax.sound.midi.MidiChannel;
import javax.sound.midi.Instrument;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Receiver;
import javax.sound.midi.MidiUnavailableException;


import processing.sound.*;

import java.nio.file.Path;
import java.nio.file.Paths;

boolean loadedSynth = false;

Synth synth;
boolean enableMIDIproxy = false;

GuiSound guiSound;

void initSynth() {
  synth = new Synth(this);
  guiSound = new GuiSound(this);
  loadedSynth = true;
}

public class GuiSound {
  SoundFile guiClickSound = null;// = new SoundFile(context, path);
  PApplet that;
  GuiSound(PApplet context) {
    that = context;
    try {
      guiClickSound = new SoundFile(that, dataPath("gui/clickSound.wav"));
      guiClickSound.amp(1.0);
      println("loaded data/gui/clickSound.wav");
    }
    catch(Exception e) {
      println("audio tab - problem loading data/gui/clickSound.wav ");
      println(e);
    }
  }

  void playClick() {
    if (guiClickSound!=null) {
      guiClickSound.play();//play click sound to enable synchronizing external video recorded with the OSC events recording
    }
  }
}

public class Synth {
  PApplet context;

  String samplesDir = "samples";
  String playbackDir = "playback";

  boolean MIDIenabled = false;
  ArrayList<MidiDevice>midiDevices = new ArrayList<MidiDevice>(); //list all MIDI devices avaliable
  ArrayList<String>avaliableMidiDevicesNames = new ArrayList<String>(); //names of the above
  MidiDevice midiDevice;
  Receiver midiReciever;
  String midiDeviceName = "Microsoft GS Wavetable Synth"; //which device to open by default
  boolean proxyMIDI = false; //should we send the MIDI to toher devices? Can be loopback interface for DAW or HW synth
  boolean enableSoundSampler = true;
  //Synthesizer synth;
  //Instrument[] instruments;
  //ArrayList<String>instrumentNames = new ArrayList<String>();
  MidiChannel[] channels;

  int PPQ = 24; //pulses per quarter note
  int bpm = 120;
  int tickPerMinute = bpm * PPQ; // PPQ = 24 => 2880 tick per minute
  int tickPerSecond = tickPerMinute/60; //2880 tick per minute => 48ticks per second, PPQ 12=>24ticks per second....
  float msPerTick = 1000.0/float(tickPerSecond); //20ms per tick => 1000/20=50fps
  long timeOffset = 0;
  boolean firstNotePlayed = false;


  ArrayList<SoundBank>soundBanks;
  SoundBank playbackBank = null;

  float[] octave = {0.25, 0.5, 1.0, 2.0, 4.0};


  Synth(PApplet myapplet) {
    context = myapplet;
    //load and list MIDI devices avaliable + choose one
    midiDevices = getMidiDevices(); //get list of MIDI devices that can recieve MIDI
    midiDevice = midiDeviceMatches(midiDevices, midiDeviceName); //try to open MIDI device by name - defaults to first one found
    avaliableMidiDevicesNames = midiDevicesToString(midiDevices); //store names of MIDI devices into String ArrayList
    if (enableMIDIproxy) {
      openMidiDevice(midiDevice); //try to open/connect to other MIDI device (DAW or HW)
    }

    //openSynth(); //try to init MIDI synth
    //hold all sound samples - soundbank->samples
    //soundBanks = new ArrayList<SoundBank>();
    soundBanks = loadSamples(samplesDir);
    ArrayList<SoundBank>playbackList = loadSamples(playbackDir);
    if (playbackList.size()>0) {
      playbackBank = playbackList.get(0);
    } else {
      println("No playback files provided");
    }
    println("Quantization set to "+msPerTick+"ms per Tick");
  }

  void update() {
    if (playbackBank!=null) {
      playbackBank.updatePlaylist();
      playbackBank.render();
    }
  }

  //subclass to hold all audio files
  class SoundBank {
    ArrayList<SoundFile>samples = new ArrayList<SoundFile>();
    ArrayList<String>samplesNames = new ArrayList<String>();
    String name;
    PApplet context;
    boolean loop = false;
    int playIndex = 0;
    boolean playbackStarted = false;

    float maxAirTime = 1500; //in milliseconds - maximum time spent in the air - used to map pitch

    SoundBank(String _name, PApplet _this) {
      name = _name;
      context = _this;
      /*
      soundfile = new SoundFile(this, sampleName);
       fileLoaded = true;
       soundfile.play();
       soundfile.stop();
       */
    }

    void add(String path) {
      try {
        SoundFile sample = new SoundFile(context, path);
        samples.add(sample);
        Path p = Paths.get(path); //FileSystems.getDefault().getPath(
        String fileName = p.getFileName().toString();
        samplesNames.add(fileName);
        println("Sound bank: "+name+" sample: "+fileName+ " duration: "+sample.duration()+" seconds");
        //sample.sampleRate() + " Hz");
        //sample.frames() + " samples");
      }
      catch(Exception e) {
        println(e);
      }
    }

    void play(int i) {
      if (i<samples.size()) {
        if (!playbackStarted) {
          playbackStarted = true;
        }
        samples.get(i).play();
      }
    }

    void stopPlaylist() {
      samples.get(playIndex).stop();
      playIndex = 0;
      playbackStarted = false;
    }

    //used only for playbackBank SoundBank - see update method of parent class
    void updatePlaylist() {
      if (!playbackStarted) {
        return;
      }
      if (!samples.get(playIndex).isPlaying()) {
        playIndex++;
        if (playIndex>samples.size()-1) { //all files played
          playIndex = 0;
          if (!loop) {
            playbackStarted = false;
          }
        }
        if (playbackStarted) {
          play(playIndex);
        }
      }
    }

    //used only for playbackBank SoundBank - see update method of parent class
    void render() {
      pushStyle();
      textFont(fontMedium);
      SoundFile s = samples.get(playIndex);
      String name = samplesNames.get(playIndex);
      if (name.length()>8) {
        name = name.substring(0, 8); // trim too long file names
      }
      String playbackText = "\""+name+"\" "+(playIndex+1)+"/"+samples.size();
      float stringLen = textWidth(playbackText+" PLAYING % 99 XXX");
      fill(255);
      if (s.isPlaying()) {
        float progress = samples.get(playIndex).percent();
        text(playbackText+" PLAYING % "+nf(progress, 0, 2), width-stringLen-30, 30);
      } else {
        text(playbackText+" PAUSED", width-stringLen-30, 30);
      }
      popStyle();
    }

    void soundThrow() {
      float rate = octave[int(random(0, octave.length))];
      // Play the soundfile from the array with the respective rate and loop set to false
      int sampleIndex = int( random(0, samples.size()) );
      samples.get(sampleIndex).play(rate, 1.0);
    }

    void soundCatch(int airtime) {
      float mapAirTime = map( constrain(float(airtime), 0, maxAirTime), 0, maxAirTime, 0.0, float(octave.length) );
      float rate = octave[floor(mapAirTime)];
      // Play the soundfile from the array with the respective rate and loop set to false
      int sampleIndex = 0;
      //int sampleIndex = int( random(0, samples.size()) );
      samples.get(sampleIndex).play(rate, 1.0);
    }
  }

  //load audio sample files from data folder - each instrument samples should be in one folder inside samples dir inside data dir
  ArrayList<SoundBank> loadSamples(String dirToSamples) {
    ArrayList<SoundBank>newbanks = new ArrayList<SoundBank>();
    ArrayList<File>datafiles = loadFiles(dataPath(dirToSamples), ".wav"); //see util tab
    println("loaded audio samples: //------------------------");
    for (int i=0; i<datafiles.size(); i++) {
      String path = datafiles.get(i).getAbsolutePath();//datafilespaths.get(i);
      try {
        String parentDirName = datafiles.get(i).getParentFile().getName();
        //String fileName = datafiles.get(i).getName();
        //SoundFile sample = new SoundFile(context, path);
        boolean matchFound = false;
        SoundBank bank = null;
        for (int s=0; s<newbanks.size(); s++) {
          if ( newbanks.get(s).name.equals(parentDirName) ) {
            bank = newbanks.get(s);
            matchFound = true;
            break;
          }
        }
        if (!matchFound) {
          newbanks.add( new SoundBank(parentDirName, context));
          bank = newbanks.get(0);
        }

        if (bank!=null) {
          bank.add(path);
        }
      }
      catch(Exception e) {
        println(e);
      }
    }
    println("//-----------------------------------------------");
    return newbanks;
  }
  //------------------------------------------------------------------
  /*
  void openSynth() {
   try {
   // Open default MIDI synthesizer
   synth = MidiSystem.getSynthesizer();
   synth.open();
   channels = synth.getChannels();
   instruments = synth.getDefaultSoundbank().getInstruments();
   instrumentNames = instrumentsToString(instruments);
   }
   catch (Exception e) {
   throw new RuntimeException(e);
   }
   }
   //------------------------------------------------------------------
   void closeSynth() {
   if (synth!=null) {
   synth.close();
   }
   }
   */
  //------------------------------------------------------------------
  //retrieve MIDI devices that can actually recieve
  public ArrayList<MidiDevice> getMidiDevices() {
    MidiDevice.Info[] midiDeviceInfos = MidiSystem.getMidiDeviceInfo();
    ArrayList<MidiDevice>rightTypeDevices = new ArrayList<MidiDevice>();
    try {
      println("MIDI DEVICES: //----------------------");
      for (int i = 0; i < midiDeviceInfos.length; i++) {
        MidiDevice device = MidiSystem.getMidiDevice(midiDeviceInfos[i]);
        boolean canReceive = device.getMaxReceivers() != 0;
        //boolean canTransmit = device.getMaxTransmitters() != 0;
        if (canReceive) {
          println( midiDeviceInfos[i].getName() );
          rightTypeDevices.add(device);
        }
      }
      println("//------------------------------------");
    }
    catch (MidiUnavailableException e) {
      System.out.printf("MIDI not available: %s\n", e);
    }
    return rightTypeDevices;
  }
  //-------------------------------------------------------------------
  void openMidiDevice(MidiDevice device) {
    if (MIDIenabled) {
      try {
        closeMidiDevice(midiDevice); //close previously opened device if any
        device.open(); //try to open new device
        midiReciever = device.getReceiver();
        MidiDevice.Info info = device.getDeviceInfo();
        midiDeviceName = info.getName();
        midiDevice = device;
        println("MIDI device "+midiDeviceName+" opened");
      }
      catch (MidiUnavailableException e) {
        System.out.printf("MIDI not available: %s\n", e);
      }
    } else {
      println("enableMIDIproxy set to "+enableMIDIproxy);
    }
  }
  //-------------------------------------------------------------------
  void closeMidiDevice(MidiDevice device) {
    if (device!=null) {
      MidiDevice.Info info = device.getDeviceInfo();
      midiDeviceName = info.getName();
      device.close();
      midiReciever = null;
      println("MIDI device "+midiDeviceName+" closed");
    }
  }
  //-------------------------------------------------------------------
  void closeMidiDevice() { //overloaded function - default to selected device when called without argument
    MidiDevice.Info info = midiDevice.getDeviceInfo();
    midiDeviceName = info.getName();

    midiDevice.close();
    midiReciever = null;

    println("MIDI device "+midiDeviceName+" closed");
  }
  //-------------------------------------------------------------------
  MidiDevice getMidiDeviceByName(String device) {
    for (int i=0; i<midiDevices.size(); i++) {
      MidiDevice m = midiDevices.get(i);
      MidiDevice.Info info = m.getDeviceInfo();
      String name = info.getName();
      if (device.equals(name)) {
        //midiDeviceName = name; //done in midiDeviceOpen and close fce
        return m;
      }
    }
    return null;
  }
  //-------------------------------------------------------------------
  ArrayList<String>midiDevicesToString(ArrayList<MidiDevice>devices) {
    ArrayList<String>out = new ArrayList<String>();
    for (int i=0; i<devices.size(); i++) {
      MidiDevice.Info info = devices.get(i).getDeviceInfo();
      String name = info.getName();
      out.add(name);
    }
    return out;
  }
  //-------------------------------------------------------------------
  //list instrument names as arraylist string
  /*
  ArrayList<String>instrumentsToString(Instrument[] instr) {
   ArrayList<String>out = new ArrayList<String>();
   for (int i=0; i<instr.length; i++) {
   synth.loadInstrument( instr[i] );//load an instrument
   out.add( instr[i].getName() );
   }
   return out;
   }
   */
  //------------------------------------------------------------------
  //retrieve MIDI device by name from list of devices
  MidiDevice midiDeviceMatches( ArrayList<MidiDevice>devices, String deviceName) {
    for (int i=0; i<devices.size(); i++) {
      MidiDevice.Info info = devices.get(i).getDeviceInfo();
      String name = info.getName();
      String description = info.getDescription();
      if ( name.contains(deviceName) || description.contains(deviceName) ) {
        return devices.get(i);
      }
    }
    if (devices.size()>0) {
      return devices.get(0);
    }
    return null;
  }
  //------------------------------------------------------------------
  /*
  int getInstrumentIndex(String instrName) {
   for (int i=0; i<instruments.length; i++) {
   if ( instrName.equals( instruments[i].getName() ) ) {
   return i;
   }
   }
   return 0;//default
   }
   */
  //------------------------------------------------------------------
  //helper fce to construct MIDI event - to be sent to other device
  public ShortMessage makeShortMessage( int command, int channel, int note, int velocity ) {
    ShortMessage a = new ShortMessage();
    try {
      a.setMessage(command, channel, note, velocity);
    }
    catch (Exception ex) {
      ex.printStackTrace();
    }
    return a;
  }
  //------------------------------------------------------------------
  int getTicks() { //current time in millis
    long timeMs = millis();
    long currMs = timeMs-timeOffset;
    int calcTicks = int( ( (float)currMs/1000.0)*tickPerSecond );
    //println(calcTicks);
    return calcTicks;
  }
  //------------------------------------------------------------------
  void noteOn(int chanNum, int pitch, int currVel) {
    if (!firstNotePlayed) {
      timeOffset = millis();
      firstNotePlayed = true;
    }
    //PLAY NOTE
    if (enableSoundSampler) {
      /*
      if (chanNum<channels.length) {
       channels[chanNum].noteOn(pitch, currVel ); //start playing a note
       } else {
       println("chanNum "+chanNum+" out of bounds for chanel size "+channels.length);
       }
       */
    }

    //SEND NOTE TO OTHER DEVICE
    //makeShortMessage( int command, int channel, int note, int velocity )
    if (MIDIenabled) { //only if enabled in GUI
      ShortMessage myMsg =  makeShortMessage( ShortMessage.NOTE_ON, chanNum, pitch, currVel  );
      midiReciever.send(myMsg, (long)getTicks() );
    }
  }
}
