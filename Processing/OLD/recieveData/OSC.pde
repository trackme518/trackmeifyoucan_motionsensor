import oscP5.*;
import netP5.*;
import java.net.InetAddress;

OscP5 oscP5;
NetAddress myRemoteLocation;

int sensorPort = 7777;
boolean connected = false;
String prefix = "/motion";

void initOSC() {
  oscP5 = new OscP5(this, sensorPort);
  //myRemoteLocation = new NetAddress("127.0.0.1", sensorPort);
}

//PARSE OSC
void oscEvent(OscMessage m) {

  println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );

  String currAddress = m.getAddress();
  Module currModule = null;

  if (m.getAddress().contains(prefix)) {
    String[] list = split(currAddress, '/');
    if (list.length<2) {
      return;
    }
    String currId = list[2];
    boolean matchFound = false;

    for (int i=0; i<modules.size(); i++) {
      if ( modules.get(i).id.equals(currId) ) {
        currModule = modules.get(i);
        matchFound = true;
      }
    }

    if ( !matchFound) {
      currModule = new Module(currId, m.getIP() ); //custom build of original oscP5 library to expose hostAddress
      //currModule = new Module(currId, theOscMessage.netAddress().address() ); //works with 0.9.9
      modules.add( currModule );
    }
  } else {
    return; //ignore everything else
  }

  //END CHECK FOR PENDULUM OSC MSG
  //-----------------------------------------------------------
  //recieve quaternion rotation
  if (m.getAddress().contains("quat") && m.checkTypetag("ffff")) {
    //println("quat received");
    //w,x,y,z
    Quaternion oscQuat = new Quaternion(m.get(0).floatValue(), m.get(1).floatValue(), m.get(2).floatValue(), m.get(3).floatValue());
    if (currModule != null ) {
      oscQuat.normalize();
      currModule.setQuatRotation(oscQuat);
    }
  }
  //--------------------------------------------------
  if (m.getAddress().contains("ypr") && m.checkTypetag("fff")) {
    PVector yprOsc = new PVector(m.get(0).floatValue(), m.get(1).floatValue(), m.get(2).floatValue());
    if (currModule != null ) {
      currModule.setYpr(yprOsc);
    }
  }
  //----------------------------------------------------
  if (m.getAddress().contains("aaWorld") && m.checkTypetag("fff")) {
    PVector accelOsc = new PVector(m.get(0).floatValue(), m.get(1).floatValue(), m.get(2).floatValue());
    if (currModule != null ) {
      currModule.setAccel(accelOsc);
    }
  }
  //----------------------------------------------------
}
