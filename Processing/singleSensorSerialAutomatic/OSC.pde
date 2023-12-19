import hypermedia.net.*; // import UDP library
import oscP5.*; // import OSC library
import oscP5.OscPatcher;
import netP5.*;
import java.net.InetAddress;

boolean loadedOSC = false; //make sure that OSC is initiated first

OscP5 oscP5;
NetAddress myRemoteLocation;

UDP udp;  // define the UDP object -> send osc message packet from Serial to oscEvent parser

void initOSC() {
  oscP5 = new OscP5(this, defaultOSCport );
  udp = new UDP(this); //without listener
  loadedOSC = true;
}

//PARSE OSC
void oscEvent(OscMessage m) {
  if (!loadedOSC) {
    return;
  }
  //-----------------------------------------------------------
  //recieve quaternion rotation
  if (m.getAddress().endsWith("quat") && m.checkTypetag("ffff")) {
    //println("quat received");
    qRotation = new Quaternion(m.floatValue(0), m.floatValue(1), m.floatValue(2), m.floatValue(3));//w,x,y,z -> update global variable
  }
  /*
  //--------------------------------------------------
   //recieve YAW PITCH ROLL rotation format
   else if (m.getAddress().contains("ypr") && m.checkTypetag("fff")) {
   //println("ypr received");
   PVector yprOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
   }
   //----------------------------------------------------
   //recieve World Acceleration
   else if (m.getAddress().contains("aaWorld") && m.checkTypetag("fff")) {
   //println("accel received");
   PVector accelOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
   }
   */
  //----------------------------------------------------
  //recieve throw event
  else if (m.getAddress().endsWith("throw")) {
    inAir = true;
    println("throw received");
  }
  //----------------------------------------------------
  //recieve catch event
  else if (m.getAddress().endsWith("catch") && m.checkTypetag("i") ) { //catch with airtime value in millis
    inAir = false;
    println("catch received");
  } else if (m.getAddress().endsWith("/connect/serial") ) { //recieve OSC over Serial = USB cable instead of WiFi
    if (serialManager != null) {
      println("Serial port with module FOUND");
      serialManager.stopSerialPortScan(); //stop scanning - we found the right one
    }
  }
}

/*
String parseOSCid(String fullstring) {
 String[] list = split(fullstring, '/');
 if (list.length<2) {
 return null;
 }
 return list[2];
 }
 */
