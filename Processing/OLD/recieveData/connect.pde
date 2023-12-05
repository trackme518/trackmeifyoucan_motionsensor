//send request for data from modules
//simply ask anyone listening to send data to this PC
void connect() {
  String[] list = split(localIP, '.');
  if (list.length<4) {
    println("invalid local ip format");
    return;
  }
  /*
  String baseip = list[0]+"."+list[1]+"."+list[2]+"."+255;
   NetAddress broadcastAddress = new NetAddress("192.168.4.1", sensorPort);
   oscP5.send( broadcastAddress, "/connect" );
   //oscP5.send( broadcastAddress, "/connect", "192.168.4.2" ); //connect sensor to specific IP
   println("connection request send to sensor");
   */

  //fake broadcast - iteratively try every IP in range
  //unlike true broadcast, unicast does not need exception in firewall nor admin privileges
  String baseip = list[0]+"."+list[1]+"."+list[2]+".";
  println("starting sending connect requests");
  for (int i=1; i<=255; i++) {
    String currip = baseip+str(i);
    NetAddress broadcastAddress = new NetAddress(currip, sensorPort);
    oscP5.send( broadcastAddress, "/connect");
    //println("broadcast IP: "+currip);
    //println("local ip: "+val+" broadcast IP: "+currip);
  }
  println("connect requests sent");
}

//overloaded fce
//ask only one module at give IP for data
void connect(String sensorip) {
  NetAddress broadcastAddress = new NetAddress(sensorip, sensorPort);
  oscP5.send( broadcastAddress, "/connect");
}

//overloaded fce
//ask only one module at given IP to send data to another IP
void connect(String sensorip, String targetip) {
  NetAddress broadcastAddress = new NetAddress(sensorip, sensorPort);
  oscP5.send( broadcastAddress, "/connect", targetip);
}
