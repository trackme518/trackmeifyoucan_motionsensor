ArrayList<Module> modules = new ArrayList<Module>();

class Module {
  String id;
  String ip;
  Quaternion rot; //current rotation
  PVector ypr;
  PVector accel;
  NetAddress remoteAddress;

  Module(String myid, String myip) {
    id = myid;
    ip = myip;
    rot = new Quaternion(1, 0, 0, 0);
    ypr = new PVector(0, 0, 0);
    accel = new PVector(0, 0, 0);
    remoteAddress = new NetAddress(ip, sensorPort);
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
  //===========================================================================================
  //create your functions here
  void render() {
    pushMatrix();
    translate(width/2, height/2, 0);
    float[] axis = rot.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);
    scale(2.2);
    box(30);
    popMatrix();
  }

  //===========================================================================================
  //-----------------------------------------------------------------
  //OSC API communication / commands to module
  //when there will be error it can return msgPrefix+"/"+ID+"/error" and string value with status
  //when command is OK it can reply with msgPrefix+"/"+ID+"/response" and string value or else
  //general type of commands
  //=========================
  //stop communicating with this PC - stop sending data
  void disconnect() {
    oscP5.send( remoteAddress, "/disconnect");
  }
  //restart module - will halt communication and try to reconnect with WiFi
  void restart() {
    oscP5.send( remoteAddress, "/restart");
  }
  //save current 3D rotation as a zero position - all future values are substracted from the offset
  void offset() {
    oscP5.send( remoteAddress, "/zeroPosition", true);
  }
  //calibrate module's IMU - should be done at least once when first flashed to increase accuracy
  void calibrate() {
    oscP5.send( remoteAddress, "/calibrate", true);
  }
  //--------------------------
  //tweak the detection values
  //=========================
  //set value that when exceeded will trigger the throw OSC event
  void thresholdthrow(String val) {
    oscP5.send(remoteAddress, "/treshold/throw/set", val);
  }

  void getthresholdthrow(String val) {
    //it will reply with address: msgPrefix+"/"+ID+"/treshold/throw"
    //with single value of current threshold
    oscP5.send(remoteAddress, "/treshold/throw/get", val);
  }
  //customize WiFi settings
  //=========================
  //set SSID of the WiFi this sensor will try to connect to or crea AP, persistant
  void setssid(String val) {
    oscP5.send(remoteAddress, "/ssid/set", val);
  }
  //set PASSWORD of the WiFi this sensor will try to connect to or crea AP, persistant
  void setpass(String val) {
    oscP5.send(remoteAddress, "/ssid/pass", val);
  }
  //reset WiFi settings on the module to default
  void resetwifi() {
    oscP5.send(remoteAddress, "/resetwifi");
    //it will reply with msgPrefix+"/"+ID+"/ssid" and string value of SSID
    //and msgPrefix+"/"+ID+"/pass" and string value of password
  }
  //set OSC port number - persistant
  void setport(int val) {
    oscP5.send(remoteAddress, "/port/set", val);
  }
  //set last number in target IP adress where the data from sensor are send by default (after restart)
  void sethostidip(int val) {
    oscP5.send(remoteAddress, "/hostidip/set", val); //by default 233 (so the target IP is X.X.X.233)
    //note that first three digits in the IP adress are still dynamic - so when you change network it will still work
  }
  //--------------------------------
  //OSC specific settings
  //=========================
  //reset OSC ID of this module to default value - string with unique number based on module's MAC
  void resetid() {
    oscP5.send(remoteAddress, "/resetid", true);
    //it will reply with msgPrefix+"/"+ID+"/response" and string value of new id
  }
  //set OSC ID for this module - persistant, should be unique
  void setid(String val) { //max 12 characters
    oscP5.send(remoteAddress, "/id/set", val);
  }
  //set OSC ID for this module - persistant, should be unique
  void setprefix(String val) { //max 12 characteres
    oscP5.send(remoteAddress, "/prefix/set", val);
  }
}
