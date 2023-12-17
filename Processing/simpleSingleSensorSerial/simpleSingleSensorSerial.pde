//Simple example of a single motion sensor sending data over Serial (USB cable)

//TABS-----------------------------------------------------------------------------------
//serial - decode incoming bytes into complete packet - than send that packet over to OSC listener
//OSC - parse incoming messages for incoming data and update global variable - rotation + throw state
//---------------------------------------------------------------------------------------

// REPLACE with name of the usb COM port with the sensor connected
//you can also use Serial.list()[0] - to open first serial port found - see function openSerial() inside serial tab
// look to console output - it will list avaliable serial port names - select the one that you are using for the sensor
//you can run this without the sensor connected - check the com port names, than again with sensor connected - new name should correspond to the right port
String portName = "COM3";

import toxi.geom.Quaternion; //import toxiclibs library for quaternion math
import java.net.InetAddress;

Quaternion qRotation = new Quaternion(0, 0, 0, 0);
boolean inAir = false;

int defaultOSCport = 7777; //port for listening + sending to modules

void keyPressed() {
  if (key=='c') {
    //enablemodeserial(true); //this happens automatically inside firmware when it recieves  "/connect/serial" message
    connectSerial();
    println("send connect request");
  } else if (key=='d') {
    enablemodeserial(false); //switch to WiFi mode
    println("send disconnect request");
  }
}

void setup() {
  size(640, 640, P3D);
  println(System.getProperty("java.version"));
  frameRate(100);
  initOSC(); //init OSC - see OSC tab
  openSerial(portName); //change the comPortName name to your port - see the variable at the top of this tab
  connectSerial(); //send connect request to the opened port - see serial tab
}

float scale = 1.0;

void draw() {
  ortho();
  background(0);

  fill(255);
  textSize(24);
  text("Connect sensor with USB serial", 30, 40);
  text("Using comPortName: "+portName, 30, 80);
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
