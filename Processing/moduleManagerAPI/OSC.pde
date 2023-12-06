import oscP5.*; // import OSC library
import netP5.*;
import java.net.InetAddress;

import hypermedia.net.*; // import UDP library

boolean loadedOSC = false; //make sure that OSC is initiated first

OscP5 oscP5;
NetAddress myRemoteLocation;

UDP udp;  // define the UDP object -> this will not be needed if I do parse packet on serial recieved data....

boolean connected = false;
String prefix = "/motion";

int defaultOSCport = 7777; //port for listening + sending to modules
int oscProxyPort = 8888;
NetAddress oscProxyLocation;
boolean enableOscProxy = true;

//boolean recieveOSC = false;
int oscMsgPerSecondCount = 0; //counter for incoming OSC messages measure fps of packet parsing
long oscFpsTimer = 0; //last time we started measuring
int oscFps = 0;

void initOSC() {
  oscP5 = new OscP5(this, defaultOSCport );
  oscProxyLocation = new NetAddress("127.0.0.1", oscProxyPort);
  udp = new UDP(this); //without listener
  loadedOSC = true;
}

//long osctimer = 0; //debug throttling

//PARSE OSC
void oscEvent(OscMessage m) {
  if (!loadedOSC) {
    return;
  }
  //verify we are getting valid message
  String currAddress = null;
  try {
    currAddress = m.getAddress();
  }
  catch(Exception e) {
    //println(e);
    return;
  }

  //uncomment to print all incoming messages:
  //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );

  //repeat the recieved message to another port - act as a proxy
  if (enableOscProxy) {
    oscP5.send(oscProxyLocation, m);
  }

  //printing will slow down the traffic
  //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
  //--------------------------------------------------------------------
  //DATA SENT FROM SENSOR EXAMPLE:
  // /motion/63607/aa from IP: 192.168.4.1 Typetag: iii
  // /motion/63607/ypr from IP: 192.168.4.1 Typetag: fff
  // /motion/63607/raw from IP: 192.168.4.1 Typetag: fffffff
  // /motion/63607/ypr/y from IP: 192.168.4.1 Typetag: f
  // /motion/63607/ypr/p from IP: 192.168.4.1 Typetag: f
  // /motion/63607/ypr/r from IP: 192.168.4.1 Typetag: f
  // /motion/63607/quat from IP: 192.168.4.1 Typetag: ffff
  // /motion/63607/aaWorld from IP: 192.168.4.1 Typetag: iii
  // /motion/63607/aaWorld/y from IP: 192.168.4.1 Typetag: i
  // /motion/63607/aaWorld/z from IP: 192.168.4.1 Typetag: i
  // /motion/63607/aaReal from IP: 192.168.4.1 Typetag: iii
  // /motion/63607/throw from IP: 192.168.8.207 Typetag: T
  // String catchMsg = msgPrefix + "/" + ID + "/catch";
  //String airtimeAddress = msgPrefix + "/" + ID + "/airtime";
  //-----------------------------------------------------------------------

  //if module manager is not ready - not loaded yet
  if ( moduleManager == null  ) {
    return;
  }

  Module currModule = null; //instance of Sensor that we want to update

  //find which module is sending this message:
  if (m.getAddress().contains(prefix)) { //search for OSC prefix
    InetAddress currip = null;
    String currId = parseOSCid(currAddress); //parse ID from message pattern - inefficient but it solves lot of issues
    try {
      currip = InetAddress.getByName(m.getIP()); //also try to get current IP address of the sensor sending the data
    }
    catch(UnknownHostException e) {
      println(e);
      return;
    }

    boolean matchFound = false;
    //go through all exsiting instances of sensors and try to match the incoming message to existing sensor
    for (int i=0; i<moduleManager.count(); i++) {

      boolean ipMatch = false;
      boolean idMatch = false;
      if (currip.equals(moduleManager.get(i).ip)) { //IP address match - this is guaranteed to identify correct sensor
        currModule = moduleManager.get(i);
        ipMatch = true;
      }
      if (currId.equals(moduleManager.get(i).id) ) { // OSC ID match - this might change if you change sensor ID
        currModule = moduleManager.get(i);
        idMatch = true;
      }
      if (ipMatch || idMatch) { //we found either IP or OSC ID matching
        matchFound = true;
        if ( ipMatch && idMatch) {
          break; // we found what we have looking for - continue
        } else { //either ip or id differs
          if (ipMatch) {
            if (currModule!=null) {
              currModule.id = currId; //update module OSC ID - it was probably changed by user
            }
          } else {
            currModule.ip = currip; //update IP - for example when main router assigns another IP or you disconnected / reconnected the sensor to already running network
          }
        }
      }
    }

    if ( !matchFound) { // no existing sensor was found
      if ( moduleManager != null) {
        currModule = new Module(currId, currip, moduleManager.modules.size() ); //create new sensor instance
        moduleManager.add( currModule ); //add it to module manager
      }
    }
  } else {
    return; //ignore everything else
  }

  //END CHECK FOR PENDULUM OSC MSG
  //-----------------------------------------------------------
  //recieve quaternion rotation
  if (m.getAddress().contains("quat") && m.checkTypetag("ffff")) {
    oscMsgPerSecondCount++; //note that we are ONLY counting the quat messages - so essentially we are measuring bundles per second - put this outside the function to measure all messages
    //println("quat received");
    Quaternion oscQuat = new Quaternion(m.floatValue(0), m.floatValue(1), m.floatValue(2), m.floatValue(3));//w,x,y,z
    if (currModule != null ) {
      oscQuat.normalize();
      currModule.setQuatRotation(oscQuat);
    }
  }
  //--------------------------------------------------
  //recieve YAW PITCH ROLL rotation format
  else if (m.getAddress().contains("ypr") && m.checkTypetag("fff")) {
    PVector yprOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
    if (currModule != null ) {
      currModule.setYpr(yprOsc);
    }
  }
  //----------------------------------------------------
  //recieve World Acceleration
  else if (m.getAddress().contains("aaWorld") && m.checkTypetag("fff")) {
    PVector accelOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
    if (currModule != null ) {
      currModule.setAccel(accelOsc);
    }
  }
  //----------------------------------------------------
  //recieve throw event
  else if (m.getAddress().contains("throw")) {
    if (currModule != null ) {
      currModule.throwEvent();
    }
  }
  //----------------------------------------------------
  //recieve catch event
  else if (m.getAddress().contains("catch") && m.checkTypetag("i") ) { //catch with airtime value in millis
    //&& m.checkTypetag("T")
    if (currModule != null ) {
      currModule.catchEvent(m.intValue(0)); //ctach event also send time spent in the air between last throw and catch event in milliseconds
    }
  }
  //-----------------------------------------------------
  //TBD IMPLEMENT
  else if (m.getAddress().contains("/treshold/throw")  ) { //not tested yet - response message from sensor after user change
    println("got reply with threshold value");
    println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
    int val = m.intValue( 0 );
    println("recieved throw threshold value: "+str(val)+" from module: "+parseOSCid(m.getAddress()));
    if (currModule != null ) {
      currModule.setThrowAccelThreshold(val);
    }
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("/connect/serial") ) { //recieve OSC over Serial = USB cable instead of WiFi
    if (serialManager != null) {
      println("Serial port with module FOUND");
      serialManager.stopSerialPortScan(); //stop scanning - we found the right one
      //automatically switch to sending data over serial from this module
      //enablemodeserial(true); //this will happen automatically in firmware when the /connect/serial is recieved
    }
  }
}


String parseOSCid(String fullstring) {
  String[] list = split(fullstring, '/');
  if (list.length<2) {
    return null;
  }
  return list[2];
}
