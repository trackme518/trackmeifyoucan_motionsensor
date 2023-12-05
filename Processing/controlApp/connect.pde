/*
void scanNetworkINterfaces() {
 localIPs = getIp();
 if (localIPs!=null) {
 if (localIPs.size()>0) {
 localIP = localIPs.get(0);
 }
 }
 }
 */

public class WiFiConnect implements Runnable {
  boolean connectVal;
  String ip = null;
  Thread localThread;
  long startTime = 0;

  WiFiConnect(boolean con) {
    connectVal = con;
    localThread = new Thread(this);
    startTime = millis();
    localThread.start();
  }

  WiFiConnect(boolean con, String myip) {
    connectVal = con;
    ip = myip;

    localThread = new Thread(this);
    startTime = millis();
    localThread.start();
  }

  public void run() {
    if (ip==null) {
      connect(connectVal);
    } else {
      connect(connectVal, ip);
    }
  }

  //super broadcast over all avaliable network interfaces
  void connect(boolean con) {
    ArrayList<String>currLanIps = getIp();
    for (int i=0; i<currLanIps.size(); i++) {
      connect(con, currLanIps.get(i));
    }
  }
  //send request for data from modules
  //simply ask anyone listening to send data to this PC
  void connect(boolean con, String myip) {
    String[] list = split( myip, '.');//split( gui.radio("my IP:", localIPs, localIP), '.');
    if (list.length<4) {
      println("invalid local ip format");
      return;
    }
    //fake broadcast - iteratively try every IP in range
    //unlike true broadcast, unicast does not need exception in firewall nor admin privileges
    String baseip = list[0]+"."+list[1]+"."+list[2]+".";
    println("starting sending connect requests");
    int currport = defaultOSCport;
    for (int i=1; i<=255; i++) {
      String currip = baseip+str(i);
      NetAddress broadcastAddress = new NetAddress(currip, currport );
      //println(currip+":"+currport);
      try {
        if (con) {
          oscP5.send( broadcastAddress, "/connect", true);
        } else {
          oscP5.send( broadcastAddress, "/disconnect");
        }
      }
      catch(Exception e) {
        println(e);
      }
    }
    if (con) {
      println("connect requests sent to "+baseip+"255");
    } else {
      println("disconnect requests sent to "+baseip+"255");
    }
  }
}
/*
//overloaded fce
 //ask only one module at given IP for data / to disconnect
 void connect(boolean con, String sensorip) {
 NetAddress broadcastAddress = new NetAddress(sensorip, defaultOSCport );
 try {
 if (con) {
 oscP5.send( broadcastAddress, "/connect");
 println("connect requests sent to "+sensorip);
 } else {
 oscP5.send( broadcastAddress, "/disconnect");
 println("disconnect requests sent to "+sensorip);
 }
 }
 catch(Exception e) {
 println(e);
 }
 }
 
 //overloaded fce
 //ask only one module at given IP to send data to another IP
 void connect(String sensorip, String targetip) {
 NetAddress broadcastAddress = new NetAddress(sensorip, defaultOSCport );
 try {
 oscP5.send( broadcastAddress, "/connect", targetip);
 }
 catch(Exception e) {
 println(e);
 }
 println("connect requests sent to "+sensorip+" with target "+targetip);
 }
 */
//----------------------------------
//SERIAL
//since we can be connected to only one serial port at a time we can send this command over serial always
void enablemodeserial(boolean val) { //switch between wifi and serial mode
  serialManager.sendToSerial( new OscMessage( "/mode/serial", val) );
}

void debug() {
  serialManager.sendToSerial( new OscMessage( "/debug/serial") );
}

void connectSerial() {
  serialManager.sendToSerial( new OscMessage( "/connect/serial") );
}

void disconnectSerial() {
  serialManager.sendToSerial( new OscMessage( "/disconnect") );
}
