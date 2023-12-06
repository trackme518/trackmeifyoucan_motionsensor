//Simple example of a single motion sensor sending data over WiFi
//disable firewall to allow sending .255 udp broadcast

//TABS-----------------------------------------------------------------------------------
//OSC - parse incoming messages for incoming data and update global variable - rotation + throw state
//GUI - simple keyboard control for selected functions
//---------------------------------------------------------------------------------------

import toxi.geom.Quaternion; //import toxiclibs library for quaternion math
import java.net.InetAddress;

Quaternion qRotation;
boolean inAir = false;

//variables for connecting over network
String broadcastip = "11.11.11.255"; //change this to match your IP range - last digit should always be .255, 11.11.11.X is default ip when using sensor as an Acces point (ie without router)
int defaultOSCport = 7777; //port for listening + sending to modules
NetAddress broadcastAddress = new NetAddress(broadcastip, defaultOSCport );


void keyPressed() {
  if (key=='c') {
    oscP5.send( broadcastAddress, "/connect", true);
    println("send connect request");
  } else if (key=='d') {
    oscP5.send( broadcastAddress, "/connect", false);
    println("send disconnect request");
  }
}

void setup() {
  size(640, 640, P3D);
  println(System.getProperty("java.version"));
  frameRate(100);
  initOSC(); //init OSC - see OSC tab
  //you don't need to send connect request if you can set your pc's IP static
  //prefferably set your PC IP to 11.11.11.233 which is default IP address that the sensor is sending data without connect request when in standalone (Acces Point) mode = without router
  //if you are using DHCP router set your IP to X.X.X.233 where X is address range served by your router
  oscP5.send( broadcastAddress, "/connect", true); //try to connect to the sensor
}

float scale = 1.0;

void draw() {
  ortho();
  background(0);

  fill(255);
  textSize(24);
  text("WiFi: 3motion, pass: datainmotion", 30, 40);
  text("'c' = connect, 'd' = disconnect", 30, 80);
  //-------------------------------

  //render visualization
  pushMatrix();
  translate(width/2, height/2, 0);
  float[] axis = qRotation.toAxisAngle();
  rotate(axis[0], -axis[1], axis[3], axis[2]);

  if (inAir) {
    scale=2.0; //increase scale as the time spent in the air increases
    fill(255, 0, 0);
  } else {
    fill(255);
    if (scale>1.05) {
      scale -= 0.05;
    }
  }
  scale(scale);
  box(50); //display 3D object
  popMatrix();

  if ( frameCount%10==0 ) {
    //display FPS of the main program thread and also OSC bundles
    surface.setTitle("www.trackmeifyoucan.com fps: "+round(frameRate) );
  }
}
