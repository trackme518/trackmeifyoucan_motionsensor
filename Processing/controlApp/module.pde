class Module {

  int index = 0; //this is assigned as a position inside the ArrayList
  boolean serialModeModule = false;

  color pickerColor;
  PVector pickerVector;

  int channel;
  PVector pos;
  String id;
  int hash = 0;
  InetAddress ip;
  Quaternion rot; //current rotation
  PVector ypr;
  PVector accel;
  NetAddress remoteAddress; //this( theNetAddress.address( ) , theNetAddress.port( ) );
  PShapeModel obj = null;
  //PShape objPicker = null; //clone of object without texture and semiunique color with flat shading to detect when user click on it

  float scale = 1.0;
  boolean inAir = false; //whether the module is thrown in the air - we can detect gravity + acceleration forces
  long inAirStarted = 0;

  PVector texCol = new PVector(1, 1, 1); //used to highlight when the module is thrown in the air
  String guifolder; //gui stack path
  int throwAccelThreshold = 4700;

  float marginOffset = 100; //keep random starting position from the windows border

  Module(String myid, InetAddress myip, PShapeModel model, int myIndex) { //, int chan
    index = myIndex;
    id = myid;
    ip = myip;
    hash = myid.hashCode(); //neat Java function that turns string into hash
    //channel = chan;
    rot = new Quaternion(1, 0, 0, 0);
    ypr = new PVector(0, 0, 0);
    accel = new PVector(0, 0, 0);
    remoteAddress = new NetAddress(ip, int( gui.slider("OSC/OSC port", defaultOSCport) ) );

    //processing does not have native fce to copy PShape, it only reference original
    //pickerVector = new PVector( random(0, 1), random(0, 1), random(0, 1) );
    //pickerColor =  color( (int)map( pickerVector.x, 0, 1, 0, 255 ), (int)map( pickerVector.y, 0, 1, 0, 255 ), (int)map( pickerVector.z, 0, 1, 0, 255 ), 255 ); //should be unique
    
    PVector randomColor = new PVector( floor(random(1, 256)), floor(random(1, 256)), floor(random(1, 256)) );
    //println("random vector: "+randomColor);
    pickerColor = color( randomColor.x, randomColor.y, randomColor.z, 255); //should be unique
    pickerVector = new PVector(map( (float)randomColor.x, 0, 255, 0, 1 ), map( (float)randomColor.y, 0, 255, 0, 1 ), map( (float)randomColor.z, 0, 255, 0, 1 ) ); //map 0-255 range color to 0-1 for the sahder
    //println("remapped color: "+map( pickerVector.x, 0, 1, 0, 255 ), map( pickerVector.y, 0, 1, 0, 255 ), map( pickerVector.z, 0, 1, 0, 255 ) );
    
    if (model!=null) {
      obj = model;
      //obj.setPickerColor(pickerColor); //set fill to flat shading version
      println("assigned 3D model: "+obj.name); //somehow this might be null? loading errors...
    } else {
      println("obj null, tab module");
    }

    pos = new PVector( random(marginOffset, (float)width-marginOffset), random(marginOffset, (float)height-marginOffset), 0 );
    println("module position: "+pos);

    guifolder = "modules/"+(String)id;
    renderGUI(); //initialize setters

    if (!serialEnabledGlobal) { //we are using WiFi
      enablemodeserial(false); //switch to sending data over WiFi
    } else {
      enablemodeserial(true); //switch to serial sending sensor data
    }

    //getthresholdthrow(); //ask for current throw acceleration threshold (throwAccelThreshold) -> this will get update once we get OSC message back
  }
  //=================================
  void updateModulePort(int pp) {
    remoteAddress = new NetAddress(ip, pp );
  }

  //=========================================================================================
  //general functions to recieve the data from sensor
  void setQuatRotation(Quaternion q) {
    rot.set(q);
  }

  void setYpr(PVector newypr) {
    ypr.set(newypr);
  }

  void setAccel(PVector newAccel) {
    accel.set(newAccel);
  }

  void setThrowAccelThreshold(int val) {
    throwAccelThreshold = val;
  }

  //===========================================================================================
  void update() {
    if (inAir) {
      if ( (millis()-inAirStarted) >1500) { //safety - when the catch event is lost, limit the air time to max 1.5sec
        catchEvent(1500);
      }
    }
    updateGUI();
  }

  void throwEvent() {
    //syntak.noteOn(channel, 60, 127); //noteOn(int chanNum, int pitch, int currVel)
    texCol = new PVector( random(0, 1), random(0, 1), random(0, 1) ); //assign random effect color multiplier
    inAir = true;
    inAirStarted = millis(); //save when the throw was started
  }

  void catchEvent(int airtime) {
    inAir = false;
    inAirStarted = 0;

    //each module has can have its own soundbank
    if (index<synth.soundBanks.size()) {
      synth.soundBanks.get(index).soundCatch(airtime);
    }
  }

  void renderPicker(PGraphics pg) {
    if (obj.obj==null || flatFillObjShader == null) {
      return;
    }

    pg.pushMatrix();
    pg.translate(pos.x-width/2, pos.y-height/2, pos.z);
    pg.pushMatrix();
    pg.translate(width/2, height/2, 0);
    float[] axis = rot.toAxisAngle();
    pg.rotate(axis[0], -axis[1], axis[3], axis[2]);
    pg.scale(2.2 * scale);

    pg.shader(flatFillObjShader);
    flatFillObjShader.set("col", pickerVector ); //set fill without texture color using custom shader
    pg.shape(obj.obj);

    pg.popMatrix();
    pg.popMatrix();
  }

  void render() {
    pushMatrix();
    translate(pos.x-width/2, pos.y-height/2, pos.z);
    pushStyle();
    //-------------------------------
    if (obj!=null || tintObjShader==null) {
      pushMatrix();
      translate(width/2, height/2, 0);
      float[] axis = rot.toAxisAngle();
      rotate(axis[0], -axis[1], axis[3], axis[2]);
      //rotateZ(PI); //peasy cam quick fix
      if (inAir) {
        scale=2.0; //increase scale as the time spent in the air increases
      } else {
        if (scale>1.05) {
          scale -= 0.05;
        }
        PVector addcolor = new PVector(0.05, 0.05, 0.05);
        texCol.add(addcolor);
        //limit overall magnitude of the vector to 1,1,1
        texCol.limit(1.7320508); //magnitude is calculate as such: println( sqrt(x*x + y*y + z*z) );
      }

      shader(tintObjShader);
      tintObjShader.set("col", new PVector(texCol.x, texCol.y, texCol.z)); //tint texture color using custom shader
      scale(2.2 * scale);

      shape(obj.obj); //java.lang.ArrayIndexOutOfBoundsException: Index -1 out of bounds for length 2

      resetShader();
      popMatrix();
    }

    pushMatrix();
    //ignore rotation
    translate(width/2-50, height/2, 0); //this is weird should be in the center...
    fill(255);
    textFont(fontLarge);
    text(id, 100, 0);
    popMatrix();

    popMatrix();//second layer pop
    popStyle();
    renderGUI();
  }
  //render GUI with settings
  void renderGUI() {
    //guifolder = "modules/"+(String)id;
    // getter that specifies a default content
    //println(id);
    //println(guifolder);
    gui.pushFolder(guifolder); //alternative is to call the getter with forward slash foldername/IP
    gui.textSet("IP", ip.getHostAddress()); // one time setter that also blocks any interaction when called every frame

    gui.toggle("send over Serial", serialModeModule);//switch module to send over serial mode / wifi

    gui.slider("throw threshold", throwAccelThreshold ); //allow individual throw threshold adjustment

    gui.button("offset position");
    gui.button("calibrate IMU");

    gui.button("connect");
    gui.button("disconnect");
    gui.button("restart");
    gui.button("factory reset");
    gui.text("OSC ID", id );
    gui.button("save");
    gui.button("reset OSC ID");

    gui.button("debug");

    gui.popFolder();
  }

  void setModuleId(String newid) {
    gui.hide(guifolder);
    id = newid;
    guifolder = "modules/"+(String)id;
    gui.show(guifolder);
  }

  void updateGUI() {
    if ( gui.button(guifolder+"/reset OSC ID") ) {
      println("reset ID for module "+id);
      //gui.hide(guifolder);
      resetid(); //save OSC ID
      //this i unfrotunetly only graphical...so memory will grow - but realistically this should not be a problem
    }
    //update is merged with render
    if ( gui.button(guifolder+"/save") ) {
      println("save settings for module "+id);
      id = gui.text(guifolder+"/OSC ID");
      setModuleId(id);
      //gui.text("label", guifolder); //this will rename its parent folder at runtime (text equals "") //does not work?
      setid( id ); //save OSC ID
      setthresholdthrow( floor( gui.slider(guifolder+"/throw threshold") ) ); //save OSC threshold value - UNTESTED TBD
      //sethostidip(int(gui.slider(guifolder+"/host IP id", defaultHostIpId))); //UNTESTED
      //sethostidip
      //gui.hideCurrentFolder(); //hied this stack
    }
    if ( gui.button(guifolder+"/offset position") ) {
      offset();
    }
    if ( gui.button(guifolder+"/calibrate IMU") ) {
      calibrate();
    }
    if ( gui.button(guifolder+"/restart") ) {
      restart();
    }
    if ( gui.button(guifolder+"/connect") ) {
      WiFiConnect connectThread = new WiFiConnect (true, ip.getHostAddress());
      //connect(true, ip.getHostAddress() );
    }
    if ( gui.button(guifolder+"/disconnect") ) {
      //connect(false, ip.getHostAddress() );
      WiFiConnect connectThread = new WiFiConnect (false, ip.getHostAddress());
    }
    if ( gui.button(guifolder+"/factory reset") ) {
      factoryreset();
    }
    if ( gui.button(guifolder+"/debug") ) {
      debug();
    }

    boolean guiserial = gui.toggle(guifolder+"/send over Serial", serialModeModule);//switch module to send over serial mode / wifi
    if ( guiserial!=serialModeModule) {
      serialModeModule = guiserial;
      enablemodeserial(serialModeModule); //send this command over serial with global function
    }
    //-----------------------------
  }
  //===========================================================================================
  //-----------------------------------------------------------------
  //OSC API communication / commands to module
  //when there will be error it can return msgPrefix+"/"+ID+"/error" and string value with status
  //when command is OK it can reply with msgPrefix+"/"+ID+"/response" and string value or else
  //general type of commands
  //=========================
  void sendCommand(OscMessage m) {
    if (!serialEnabledGlobal) {
      oscP5.send(remoteAddress, m);
      println("OSC send over WiFi");
      //oscP5.send( remoteAddress, "/disconnect");
    } else { //send over Serial port
      serialManager.sendToSerial(m);
      println("OSC send over Serial");
    }
    //println(remoteAddress + " : "+m.toString());
    //println(m.getAddress()+" "+val);
  }
  //=========================
  //stop communicating with this PC - stop sending data
  void disconnect() {
    sendCommand( new OscMessage("/disconnect") );
    //oscP5.send( remoteAddress, "/disconnect");
  }
  //restart module - will halt communication and try to reconnect with WiFi
  void restart() {
    sendCommand( new OscMessage("/restart") );
    //oscP5.send( remoteAddress, "/restart");
  }
  //save current 3D rotation as a zero position - all future values are substracted from the offset
  void offset() {
    sendCommand( new OscMessage("/offset", true) );
  }
  //calibrate module's IMU - should be done at least once when first flashed to increase accuracy
  void calibrate() {
    //oscP5.send( remoteAddress, "/calibrate", true);
    sendCommand( new OscMessage("/calibrate", true) );
  }
  //--------------------------
  //tweak the detection values
  //=========================
  //set value that when exceeded will trigger the throw OSC event
  void setthresholdthrow(int val) {
    //oscP5.send(remoteAddress, "/treshold/throw/set", val);
    sendCommand( new OscMessage("/treshold/throw/set", val) );
  }
  void getthresholdthrow() {
    //it will reply with address: msgPrefix+"/"+ID+"/treshold/throw"
    //no value needed
    sendCommand( new OscMessage("/treshold/throw/get") );
    //oscP5.send(remoteAddress, "/treshold/throw/get");
  }
  //customize WiFi settings
  //=========================
  //set SSID of the WiFi this sensor will try to connect to or crea AP, persistant
  void setssid(String val) {
    sendCommand( new OscMessage("/ssid/set", val) );
    //oscP5.send(remoteAddress, "/ssid/set", val);
  }
  //set PASSWORD of the WiFi this sensor will try to connect to or crea AP, persistant
  void setpass(String val) {
    sendCommand( new OscMessage("/ssid/pass", val) );
    //oscP5.send(remoteAddress, "/ssid/pass", val);
  }
  //reset WiFi settings on the module to default
  void resetwifi() { //reset WiFi SSID & password to defaults
    sendCommand( new OscMessage("/wifi/reset") );
    //oscP5.send(remoteAddress, "/wifi/reset");
    //it will reply with msgPrefix+"/"+ID+"/ssid" and string value of SSID
    //and msgPrefix+"/"+ID+"/pass" and string value of password
  }
  //control how the data are send from module
  //================================
  void enablemodeserial(boolean val) {
    sendCommand( new OscMessage( "/mode/serial", val) );//true will switch to serial mode, false will switch to wifi
  }
  //control memory settings
  //=================================
  void factoryreset() { //completely wipe all preferences saved inside EEPROM - this also delete calibration data!
    sendCommand( new OscMessage("/factoryreset") );
    //oscP5.send(remoteAddress, "/factoryreset");
  }

  void resetimupreferences() { // wipe IMU preferences saved inside EEPROM = throw threshold & calibration data!
    sendCommand( new OscMessage("/preferences/imu/reset") );
    //oscP5.send(remoteAddress, "/preferences/imu/reset");
  }

  void resetwifipreferences() { // wipe WiFi preferences saved inside EEPROM = idHostIP & SSID & password & port & ID
    sendCommand( new OscMessage("/preferences/wifi/reset") );
    //oscP5.send(remoteAddress, "/preferences/wifi/reset");
  }

  //set OSC port number - persistant
  void setport(int val) {
    sendCommand( new OscMessage("/port/set", val) );
    //oscP5.send(remoteAddress, "/port/set", val);
  }
  //set last number in target IP adress where the data from sensor are send by default (after restart)
  void sethostidip(int val) {
    sendCommand( new OscMessage("/hostidip/set", val) );
    //oscP5.send(remoteAddress, "/hostidip/set", val); //by default 233 (so the target IP is X.X.X.233)
    //note that first three digits in the IP adress are still dynamic - so when you change network it will still work
  }
  //--------------------------------
  //OSC specific settings
  //=========================
  //reset OSC ID of this module to default value - string with unique number based on module's MAC
  void resetid() {
    sendCommand( new OscMessage("/resetid", true) );
    //oscP5.send(remoteAddress, "/resetid", true);
    //it will reply with msgPrefix+"/"+ID+"/response" and string value of new id
  }
  //set OSC ID for this module - persistant, should be unique
  void setid(String val) { //max 12 characters
    sendCommand( new OscMessage("/id/set", val) );
    //oscP5.send(remoteAddress, "/id/set", val);
  }
  //set OSC ID for this module - persistant, should be unique
  void setprefix(String val) { //max 12 characteres
    sendCommand( new OscMessage( "/prefix/set", val) );
    //oscP5.send(remoteAddress, "/prefix/set", val);
  }
  //-------------------------------
  void debug() {
    sendCommand( new OscMessage( "/debug/serial") );
  }
}
