//disable firewall
//TABS:
//OSC - parse incoming messages
//cmds - OSC commands that can be sent to module (calibrate, connect, disconnect etc.)
//module - class that represents each sensor

//GUI - simple interactive control
//shell - just a help functions to execute native OS commands if you need to
//ip - helping function to list your local ip address (in case of multiple interfaces you can choose)
//quat - just some helper function for quaternion math, not needed

//import org.apache.commons.math3.complex.Quaternion;//org.apache.commons.math3.complex;

//import toxi.geom.*;
import toxi.geom.Quaternion;
import toxi.processing.*;
ToxiclibsSupport gfx;


import java.net.InetAddress;

//ArrayList<String>localIPs=new ArrayList<String>();
//int ipIndex = 0;
//String localIP = "";

String surfaceName = "Data in Motion";
int sketchW = 800;
int sketchH = 640;

void checkSketchSize() {
  if (width != sketchW ||  height != sketchH) {
    sketchW = width;
    sketchH = height;
    println("sketch resized to "+sketchW+"*"+sketchH);
  }
}

Loading loadingStatus;

void setup() {
  size(800, 600, P3D);
  surface.setResizable(true);
  println(System.getProperty("java.version"));
  frameRate(60); //for debug only - go as fast as we can
  background(0);

  loadingStatus = new Loading();

  /*
//UNCOMMENT HERE FOR GUI DEBUG WITHOUT HW MODULES-------
   //debug GUI - add fake modules
   for (int i=0; i<3; i++) {
   try {
   InetAddress randomIp = InetAddress.getByName("127.0.0."+str(floor(random(0, 256))));
   Module currModule = new Module(str(int(random(0, 999))), randomIp, getModel(), i ); //custom build of original oscP5 library to expose hostAddress
   moduleManager.add( currModule );
   }
   catch(Exception e) {
   System.out.println(e);
   }
   }
   println("Modules size "+moduleManager.modules.size());
   //UNCOMMENT HERE FOR GUI DEBUG WITHOUT HW MODULES--------
   */

  //connect(); //try to connect to first found network interface straight away

  //cursor(CROSS);
}

//float ry;
boolean initialized = false;
boolean loading = false;

class Loading {
  String loadingStatusString = "LOADING";
  String loadingString = "";
  long loadingUpdateTime = 0;
  float stringWidth = 98;
  float dotWidth = 14; //textWidth(".")
  int ticks = 0;

  Loading() {
    fontMedium = createFont(dataPath("JetBrainsMonoNL-Regular.ttf"), 12);
    fontLarge = createFont(dataPath("JetBrainsMonoNL-Regular.ttf"), 24);
    textFont(fontLarge);
    fill(255);

    stringWidth = textWidth(loadingStatusString);
    dotWidth = textWidth(".");
  }

  void update() {
    if (!initialized) {
      background(0);
      textFont(fontLarge);
      fill(255);
      
      if (millis()-loadingUpdateTime>500) {
        ticks++;
        loadingUpdateTime = millis();
        //println(".");
        loadingString = loadingString+".";
      }

      text(loadingStatusString, width/2-stringWidth/2, height/2-30);
      text(loadingString, width/2-(ticks*dotWidth)/2, height/2);
    }
  }
}

void draw() {
  //move some of the file loading into draw at later stage - sometimes when setup() is taking too long it crashes
  loadingStatus.update();

  if (!initialized && frameCount>1 && !loading) {
    loading = true;
    cursor(CROSS);
    //initGUI(); //this has to be in main thread because we are drawing into main openGL buffer with it
    thread("initGUI");

    moduleManager = new ModuleManager(); //keep tabs on individual sensors/modules
    //initGUI();
    //thread("initGUI");//initGUI();
    shapeMode(CORNER);
    //load on separate threads
    thread("initOSC"); //initOSC(); //OSC tab
    thread("initSynth");//initSynth(); //audio tab

    //loadModels();
    thread("loadModels");
    thread("initReplay");

    serialManager = new SerialManager(this);
    wallpaper = new Wallpaper(); //wallpaper tab - shaders based background
    //replay = new Replay();
    //initialized = true;
  }

  if ( !initialized && loadedSynth && loadedGUI && loadedOSC && loadedModels && gui!=null && replayLoaded) {
    //replay.init();
    //moduleManager = new ModuleManager(); //keep tabs on individual sensors/modules
    initialized = true;
    println("resources loaded");
  }

  ortho();
  //lights();

  /*
  for (int i = 0; i<timeSerialDebounce.length; i++) {
   //------SERIAL---------------------
   terminateCommandToSerial(i); //Terminate command
   }
   
   try{
   updateGUI(); //check for general GUI evets and perform actions
   }catch(Exception e){
   println(e);
   }
   */

  if (initialized) {
    wallpaper.render();
    moduleManager.run(); //update and render individual module instances
    serialManager.scanSerialInterfaces(); //automatically find serial port with module when enabled
    updateGUI(); //check for general GUI evets and perform actions
    synth.update();
    checkSketchSize();

    if ((oscFpsTimer+1000)<millis()) {
      oscFps = oscMsgPerSecondCount; //1212 for wifi, 144 for serial
      oscMsgPerSecondCount = 0;
      oscFpsTimer = millis(); //resest
    }
    //replay.update();
  }


  if ( frameCount%10==0 ) {
    surface.setTitle(surfaceName+" fps: "+round(frameRate)+ " OSC fps: "+oscFps );
  }
}
