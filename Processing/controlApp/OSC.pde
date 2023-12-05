import oscP5.*;
import netP5.*;
import java.net.InetAddress;

boolean loadedOSC = false;

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
  String currAddress = null;
  try {
    currAddress = m.getAddress();
  }
  catch(Exception e) {
    println(e);
    return;
  }
  //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
  //motion/s1/ypr from IP: 127.0.0.1 Typetag: fff
  //repeat the recievede message to another port - act as a proxy
  if (enableOscProxy) {
    oscP5.send(oscProxyLocation, m);
  }

  if (recorder!=null) {
    recorder.saveEvent(m); //if recording is toggled true it will save incoming messages into .csv file - see record tab
  }

  /*
  //debug throttling
   if (osctimer>millis()-33) {
   return;
   }
   osctimer = millis();
   */

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

  //String responseMsgString = msgPrefix + "/" + ID + "/response";
  //  //msgPrefix + "/" + ID + "/treshold/throw
  //-----------------------------------------------------------------------

  //if module manager is not ready - we need 3d models to be loaded as well at this point to be able to display the instance
  if ( moduleManager == null || !loadedModels ) {
    return;
  }

  Module currModule = null;

  //int moduleIndex = 0; //module instance index inside ArrayList - used to send command over serial to control lights

  if (m.getAddress().contains(prefix)) {
    InetAddress currip = null;
    String currId = parseOSCid(currAddress); //parse ID from message pattern - inefficient but it solves lot of issues
    try {
      currip = InetAddress.getByName(m.getIP());
    }
    catch(UnknownHostException e) {
      println(e);
      return;
    }

    boolean matchFound = false;

    for (int i=0; i<moduleManager.count(); i++) {
      //moduleIndex = i;
      boolean ipMatch = false;
      boolean idMatch = false;
      if (currip.equals(moduleManager.get(i).ip)) {
        currModule = moduleManager.get(i);
        ipMatch = true;
      }
      if (currId.equals(moduleManager.get(i).id) ) {
        currModule = moduleManager.get(i);
        idMatch = true;
      }
      if (ipMatch || idMatch) {
        matchFound = true;
        if ( ipMatch && idMatch) {
          break; // we found what we have looking for - continue
        } else { //either ip or id differs
          if (ipMatch) {
            if (currModule!=null) {
              currModule.setModuleId(currId); //hie previous GUI folder - create new one with proper name
            }
            //currModule.id = currId; //update ID
          } else {
            currModule.ip = currip; //update IP
          }
        }
      }
    }

    if ( !matchFound) {
      //retrieve OSC ID as well
      if ( moduleManager != null) {
        currModule = new Module(currId, currip, getModel(), moduleManager.modules.size() ); //custom build of original oscP5 library to expose hostAddress
        //currModule = new Module(currId, theOscMessage.netAddress().address() ); //works with 0.9.9
        moduleManager.add( currModule );
        //moduleIndex = moduleManager.count()-1; //used to send command over serial and control lights
      }
    }
  } else {
    return; //ignore everything else
  }

  //END CHECK FOR PENDULUM OSC MSG
  //-----------------------------------------------------------
  //recieve quaternion rotation
  if (m.getAddress().contains("quat") && m.checkTypetag("ffff")) {

    oscMsgPerSecondCount++;
    //measure fps of packet parsing
    /*
    if ((oscFpsTimer+1000)<millis()) {
     oscFps = oscMsgPerSecondCount; //1212 for wifi, 144 for serial
     //println(oscFps);
     oscMsgPerSecondCount = 0;
     oscFpsTimer = millis(); //resest
     }
     */

    //println("quat received");
    //w,x,y,z
    Quaternion oscQuat = new Quaternion(m.floatValue(0), m.floatValue(1), m.floatValue(2), m.floatValue(3));
    if (currModule != null ) {
      oscQuat.normalize();
      currModule.setQuatRotation(oscQuat);
    }
  }
  //--------------------------------------------------
  else if (m.getAddress().contains("ypr") && m.checkTypetag("fff")) {
    PVector yprOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
    if (currModule != null ) {
      currModule.setYpr(yprOsc);
    }
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("aaWorld") && m.checkTypetag("fff")) {
    PVector accelOsc = new PVector(m.floatValue(0), m.floatValue(1), m.floatValue(2));
    if (currModule != null ) {
      currModule.setAccel(accelOsc);
    }
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("throw")) {
    //&& m.checkTypetag("T")
    if (currModule != null ) {
      currModule.throwEvent();
      //sendCommandToSerial(moduleIndex);

      /*
      if (synth!= null) {
       int indexSoundBank = int(random(0, synth.soundBanks.size() ));
       synth.soundBanks.get(indexSoundBank).noteOn();
       }
       */
    }
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("catch") && m.checkTypetag("i") ) { //catch with airtime value in millis
    //&& m.checkTypetag("T")
    if (currModule != null ) {
      currModule.catchEvent(m.intValue(0));
    }
  }
  //----------------------------------------------------
  //response from module with new id assigned by resetid command
  else if (m.getAddress().contains("newid")  ) {
    //else if (m.getAddress().contains("newid") && m.checkTypetag("s") ) {
    //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
    String msg = m.stringValue( 0 );
    println("new id "+msg+" update recieved for module id "+parseOSCid(m.getAddress()));
    if (currModule != null ) {
      if ( !currModule.id.equals(msg) ) {
        currModule.setModuleId(msg);
      }
    }
  }
  //-----------------------------------------------------
  //TBD IMPLEMENT
  else if (m.getAddress().contains("/treshold/throw")  ) { //  //msgPrefix + "/" + ID + "/treshold/throw
    //else if (m.getAddress().contains("newid") && m.checkTypetag("s") ) {
    println("got reply with threshold value");
    println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
    /*
    int val = m.intValue( 0 );
     println("recieved throw threshold value: "+str(val)+" from module: "+parseOSCid(m.getAddress()));
     if (currModule != null ) {
     currModule.setThrowAccelThreshold(msg);
     }
     */
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("/debug") && m.checkTypetag("s") ) {
    println("debug msg recieved: "+m.stringValue(0) );
    //will print:
    //debug msg recieved: this msg is from serial
    //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
  }
  //----------------------------------------------------
  else if (m.getAddress().contains("/connect/serial") ) {
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
