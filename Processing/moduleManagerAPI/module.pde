import toxi.geom.Quaternion; //import toxiclibs library for quaternion math

class Module {

  int index = 0; //this is assigned as a position inside the ArrayList
  boolean serialModeModule = false;

  int channel;
  PVector pos;
  String id;

  InetAddress ip;
  Quaternion rot; //current rotation as quaternion - more precise and avoids gimbal lock
  PVector ypr; //more traditional rotation in yaw pitch roll format - easier to use
  PVector accel; // absolute acceleration 
  NetAddress remoteAddress; //this sensor address = ip+port

  float scale = 1.0;
  boolean inAir = false; //whether the module is thrown in the air - we can detect gravity + acceleration forces
  long inAirStarted = 0; //last time when the module was thrown into the air

  int throwAccelThreshold = 4700; //default throw threshold

  Module(String myid, InetAddress myip, int myIndex) { //, int chan
    index = myIndex;
    id = myid;
    ip = myip;

    rot = new Quaternion(1, 0, 0, 0);
    ypr = new PVector(0, 0, 0);
    accel = new PVector(0, 0, 0);
    remoteAddress = new NetAddress(ip, defaultOSCport );

    pos = new PVector( 100,160+myIndex*200, 0 );
    println("module position: "+pos);

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
  }

  void throwEvent() {
    inAir = true;
    inAirStarted = millis(); //save when the throw was started
  }

  void catchEvent(int airtime) {
    inAir = false;
    inAirStarted = 0;
  }

  void render() {
    pushMatrix();
    translate(pos.x-width/2, pos.y-height/2, pos.z);
    pushStyle();
    //-------------------------------

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
    }
    scale(scale);
    box(30); //display 3D object
    popMatrix();


    pushMatrix();
    //ignore rotation for text label
    translate(width/2-50, height/2, 0); //this is weird should be in the center...
    fill(255);
    textSize(24);
    text(id, 100, 0);
    popMatrix();

    popMatrix();//second layer pop
    popStyle();

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
    sendCommand( new OscMessage("/treshold/throw/set", val) );
  }
  void getthresholdthrow() {
    //it will reply with address: msgPrefix+"/"+ID+"/treshold/throw"
    //no value needed
    sendCommand( new OscMessage("/treshold/throw/get") );
  }
  //customize WiFi settings
  //=========================
  //set SSID of the WiFi this sensor will try to connect to or crea AP, persistant
  void setssid(String val) {
    sendCommand( new OscMessage("/ssid/set", val) );
  }
  //set PASSWORD of the WiFi this sensor will try to connect to or crea AP, persistant
  void setpass(String val) {
    sendCommand( new OscMessage("/ssid/pass", val) );
  }
  //reset WiFi settings on the module to default
  void resetwifi() { //reset WiFi SSID & password to defaults
    sendCommand( new OscMessage("/wifi/reset") );
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
  }

  void resetimupreferences() { // wipe IMU preferences saved inside EEPROM = throw threshold & calibration data!
    sendCommand( new OscMessage("/preferences/imu/reset") );
  }

  void resetwifipreferences() { // wipe WiFi preferences saved inside EEPROM = idHostIP & SSID & password & port & ID
    sendCommand( new OscMessage("/preferences/wifi/reset") );
  }

  //set OSC port number - persistant
  void setport(int val) {
    sendCommand( new OscMessage("/port/set", val) );
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
    //it will reply with msgPrefix+"/"+ID+"/response" and string value of new id
  }
  //set OSC ID for this module - persistant, should be unique
  void setid(String val) { //max 12 characters
    sendCommand( new OscMessage("/id/set", val) );
  }
  //set OSC ID for this module - persistant, should be unique
  void setprefix(String val) { //max 12 characteres
    sendCommand( new OscMessage( "/prefix/set", val) );
  }
  //-------------------------------
}
