import processing.serial.*;
//download at http://ubaa.net/shared/processing/udp/
import hypermedia.net.*;
//download at www.sojamo.de/libraries/controlp5
import controlP5.*;
import oscP5.*;
import netP5.*;
import java.net.InetAddress;

OscP5 oscP5;
NetAddress oscProxyLocation;

boolean applicationRunning = false;
int oscPort = 8888;

void setup() {
  // configure the screen size and frame rate
  size(550, 350, P3D);
  frameRate(30);

  oscP5 = new OscP5(this, oscPort );
  oscProxyLocation = new NetAddress("127.0.0.1", 9999);

  setupGUI();
}

void draw() {
  background(128);
  if (applicationRunning) {
    drawIncomingPackets();
  }
}

//PARSE OSC
void oscEvent(OscMessage m) {
  println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
}

/************************************************************************************
 VISUALIZING INCOMING PACKETS
 ************************************************************************************/

int lastSerialPacket = 0;
int lastUDPPacket = 0;

void drawIncomingPackets() {
  //the serial packet
  fill(0);
  rect(75, 50, 100, 100);
  //the udp packet
  rect(325, 50, 100, 100);
  int now = millis();
  int lightDuration = 75;
  if (now - lastSerialPacket < lightDuration) {
    fill(255);
    rect(85, 60, 80, 80);
  }
  if (now - lastUDPPacket < lightDuration) {
    fill(255);
    rect(335, 60, 80, 80);
  }
}

void drawIncomingSerial() {
  lastSerialPacket = millis();
}

void drawIncomingUDP() {
  lastUDPPacket = millis();
}
