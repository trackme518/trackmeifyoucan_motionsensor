import oscP5.*;
import netP5.*;
import java.net.InetAddress;
import java.net.UnknownHostException;

OscP5 oscP5;
NetAddress myRemoteLocation;

boolean connected = false;
String prefix = "/motion";

int oscProxyPort = 8888;
NetAddress oscProxyLocation;
boolean enableOscProxy = true;

//boolean recieveOSC = false;

void initOSC() {
  oscP5 = new OscP5(this, 7777 );
  oscProxyLocation = new NetAddress("127.0.0.1", oscProxyPort);
}

//long osctimer = 0; //debug throttling

//PARSE OSC
void oscEvent(OscMessage m) {

  //printing will slow down the traffic
  println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );

  //repeat the recievede message to another port - act as a proxy

  if (enableOscProxy) {
    oscP5.send(oscProxyLocation, m);
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
  String currAddress = m.getAddress();

  //----------------------------------------------------
  if (m.getAddress().contains("throw")) {
    int moduleIndex = 0; //module instance index inside ArrayList - used to send command over serial to control lights
    String currId = parseOSCid(currAddress);
    if (currId.length()>1) {
      moduleIndex = int( currId.substring(1) ); //used to send command over serial and control lights
    }
    //&& m.checkTypetag("T")
    sendCommandToSerial(moduleIndex);
  }
}


String parseOSCid(String fullstring) {
  String[] list = split(fullstring, '/');
  if (list.length<2) {
    return null;
  }
  return list[2];
}
