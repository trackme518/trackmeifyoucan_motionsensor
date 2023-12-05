//disable firewall
//TABS:
//OSC - parse incoming messages
//cmds - OSC commands that can be sent to module (calibrate, connect, disconnect etc.)
//module - class that represents each sensor

//GUI - simple interactive control
//shell - just a help functions to execute native OS commands if you need to
//ip - helping function to list your local ip address (in case of multiple interfaces you can choose)
//quat - just some helper function for quaternion math, not needed

import toxi.geom.*;
import toxi.processing.*;
ToxiclibsSupport gfx;
import java.net.InetAddress;

ArrayList<String>localIPs=new ArrayList<String>();
int ipIndex = 0;
String localIP = "";

String surfaceName = "Data in Motion";

void setup() {
  size(640, 640, P3D);
  println(System.getProperty("java.version"));

  //cam = new PeasyCam(this, 400);

  initOSC();
  localIPs = getIp();
  if (localIPs!=null) {
    if (localIPs.size()>0) {
      localIP = localIPs.get(0);
      connect(); //try to connect to first found network interface straight away
    }
  }

  //debug GUI
  for (int i=0; i<3; i++) {
    Module currModule = new Module(str(int(random(0, 99999))), "127.0.0."+str(int(random(0, 256)))); //custom build of original oscP5 library to expose hostAddress
    modules.add( currModule );
  }

  background(0);
}

float ry;

void draw() {
  ortho();
  //lights();

  background(127);


  //fill(0, 0, 0, 10);
  //rect(0, 0, width, height);
  //renderBackground();

  /*
  textSize(24);
   fill(255);
   text("a = change your IP", 200, 30);
   text("c = connect", 200, 60);
   
   for (int i=0; i<localIPs.size(); i++) {
   fill(255);
   if (ipIndex == i) {
   fill(255, 255, 153);
   }
   String localip = localIPs.get(i);
   text(localip, 30, 30*(i+1));
   }
   */
  for (int i=0; i<modules.size(); i++) {
    Module m = modules.get(i);
    pushMatrix();
    float offsetY = -(200*modules.size())/2+200*i;
    translate(0,offsetY,0);
    m.render();
    popMatrix();
  }

  if ( frameCount%10==0 ) {
    surface.setTitle(surfaceName+" fps: "+round(frameRate) );
  }
}
