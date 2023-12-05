import oscP5.*;
import netP5.*;
import java.net.InetAddress;

OscP5 oscP5;
NetAddress myRemoteLocation;

int oscMsgPerSecondCount = 0; //counter for incoming OSC messages measure fps of packet parsing
long oscFpsTimer = 0; //last time we started measuring
int oscFps = 0;

void initOSC() {
  oscP5 = new OscP5(this, 7777 );
}

void oscEvent(OscMessage m) {

  String currAddress = null;

  try {
    currAddress = m.getAddress();
  }
  catch(Exception e) {
    println(e);
    return;
  }

  oscMsgPerSecondCount++;
  //measure fps of packet parsing
  if ((oscFpsTimer+1000)<millis()) {
    oscFps = oscMsgPerSecondCount; //1212 for wifi, 144 for serial
    //println(oscFps);
    oscMsgPerSecondCount = 0;
    oscFpsTimer = millis(); //resest
  }
  
  //println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
}
