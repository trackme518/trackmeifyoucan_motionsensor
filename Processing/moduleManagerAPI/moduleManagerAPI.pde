//Conenct to motion sensor over WiFi OR Serial and recieve OSC data

//This is more complicated example with object oriented approach
//Each sensor is given an instance of Module class and we use ModuleManager class to manage them.
//Connect request over WiFi AND Serial is automated
//Module class includes all the OSC commands that can be sent to sensor - not used in this sketch thought
//To call the command you would use moduleManager.get(i).somecommand(); -> moduleManager.get(0).resetwifipreferences();
//When debugging you should disable firewall.

//TABS-----------------------------------------------------------------------------------
//OSC - parse incoming messages for incoming data and update the given sensor instance
//module - class that represents each sensor with all OSC commands you can send to it
//GUI - simple keyboard control for selected functions
//ip - helper function to list your local ip address (in case of multiple interfaces, it will return all ip addresses of your PC)
//connect - it will send connect OSC message to all clients on all network interfaces - effectively automating the connection process to the sensors without needing to know sensor IP address
//quat - just some helper function for quaternion math - you can safely ignore this
//---------------------------------------------------------------------------------------

import java.net.InetAddress;

void setup() {
  size(640, 640, P3D);
  println(System.getProperty("java.version"));
  frameRate(100);

  initOSC(); //init OSC
  serialManager = new SerialManager(this); //init serial port = USB
  moduleManager = new ModuleManager(); //manages individual sensors/modules
  WiFiConnect connectThread = new WiFiConnect (true); // try to connect to all modules on the WiFi - the command is using another thread to help with performance
}

void draw() {
  ortho();
  background(0);

  moduleManager.run(); //update and render individual module instances

  serialManager.scanSerialInterfaces(); //when send connecte request over serial, listen for response

  fill(255);
  textSize(24);
  text("WiFi: 3motion, pass: datainmotion OR use an USB cable", 30, 40);
  text("'c' = connect, 'd' = disconnect, 's' = toggle usb/wifi mode", 30, 80);
  String mode = "WiFi";
  if (serialEnabledGlobal) {
    mode = "Serial";
  }
  text("modules connected: "+moduleManager.count()+" mode: "+mode, 30, 120);

  if ( frameCount%10==0 ) {
    //display FPS of the main program thread and also OSC bundles
    surface.setTitle("www.trackmeifyoucan.com fps: "+round(frameRate)+" OSC pps: "+oscMsgPerSecondCount );
  }
}
