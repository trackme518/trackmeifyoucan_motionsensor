import oscP5.*;
import netP5.*;
import java.net.InetAddress;

import com.krab.lazy.*;
import grafica.*;

LazyGui gui;

OscP5 osc;
ModuleManager moduleManager;

public GPlot plot2;

int sensorPort = 7777;
boolean connected = false;
String prefix = "/motion";

void setup() {
  size(1960, 1080, P3D);

  ortho();
  lights();
  gui = new LazyGui(this);
  
  osc = new OscP5(this, sensorPort);
  moduleManager = new ModuleManager(osc);

  plot2 = new GPlot(this);
  plot2.setPos(100, 0);
  plot2.setDim(400, 200);
  plot2.getTitle().setText("IMU Acceleration x,y,z or magnitude");
  plot2.getXAxis().getAxisLabel().setText("Time (ms)");
  plot2.getYAxis().getAxisLabel().setText("Acceleration (g)");
  plot2.addLayer("x", new GPointsArray());
  plot2.getLayer("x").setLineColor(color(200, 0, 0));
  plot2.getLayer("x").setPointColor(color(255, 0, 0));
  plot2.addLayer("y", new GPointsArray());
  plot2.getLayer("y").setLineColor(color(0, 200, 0));
  plot2.getLayer("y").setPointColor(color(0, 255, 0));
  plot2.addLayer("z", new GPointsArray());
  plot2.getLayer("z").setLineColor(color(0, 0, 200));
  plot2.getLayer("z").setPointColor(color(0, 0, 255));
  plot2.addLayer("mag", new GPointsArray());
  plot2.getLayer("mag").setLineColor(color(0));
  plot2.getLayer("mag").setPointColor(color(50));
}

void draw() {
  background(0);
  // Draw the second plot  
  // plot2.beginDraw();
  // plot2.drawBackground();
  // plot2.drawBox();
  // plot2.drawXAxis();
  // plot2.drawYAxis();
  // plot2.drawTitle();
  // plot2.drawGridLines(GPlot.BOTH);
  // plot2.drawLines();
  // plot2.drawPoints();
  // plot2.drawFilledContours(GPlot.HORIZONTAL, 0);
  // plot2.endDraw();

  plot2.updateLimits();
  plot2.beginDraw();
  plot2.drawBackground();
  plot2.drawBox();
  plot2.drawXAxis();
  plot2.drawYAxis();
  plot2.drawTitle();
  // plot2.drawLines();
  // plot2.drawPoints();
  if (gui.toggle("draw magnitude")) {
    plot2.getLayer("mag").drawLines();
    plot2.getLayer("mag").drawPoints();
  }
  else {
    plot2.getLayer("x").drawLines();
    plot2.getLayer("y").drawLines();
    plot2.getLayer("z").drawLines();

    plot2.getLayer("x").drawPoints();
    plot2.getLayer("y").drawPoints();
    plot2.getLayer("z").drawPoints();
  }

  plot2.endDraw();

  ortho();
  int y = 20;



  int t = millis();

  for (Module b : moduleManager.getModules()) {
    // text vlevo
    fill(255);
    textAlign(LEFT);
    text(b.ip+": accel: "+b.accel + " ypr: " + b.ypr + " quat: " + b.rot, 10, y, 0);
    // text("accelMagnitude: "+b.accel.mag(), 10, y+20, 0);
    // text("realAccelMagnitude: "+b.getGravityAdjustedAccel().mag(), 10, y+40, 0);
    text("velocity: "+b.velocity, 10, y+60, 0);
    text("position: "+b.position, 10, y+80, 0);
    // if (b.accel.x == 32767 || b.accel.y == 32767 || b.accel.z == 32767) {
    //   fill(255, 0, 0);
    //   rect(0, 0, 200, 200);
    // }
    y += 20;

    // ccircle(b.position.x, b.position.y, b.accel.mag()/100);

    // int num_points = gui.sliderInt("num_points", 100, 10, 1000);
    // while (plot2.getPointsRef("x").getNPoints() > num_points)
    //   plot2.removePoint(0, "x");
    // // plot2.getLayer("x").addPoint(t, b.accel.x);

    // while (plot2.getPointsRef("y").getNPoints() > num_points)
    //   plot2.removePoint(0, "y");
    // // plot2.getLayer("y").addPoint(t, b.accel.y);

    // while (plot2.getPointsRef("z").getNPoints() > num_points)
    //   plot2.removePoint(0, "z");
    // // plot2.getLayer("z").addPoint(t, b.accel.z);
        
    // while (plot2.getPointsRef("mag").getNPoints() > num_points)
    //   plot2.removePoint(0, "mag");
    // plot2.getLayer("mag").addPoint(t, b.accel.mag());
    // plot2.updateLimits();

    // kreslení kostky ======================
    pushMatrix();

    float[] axis = b.rot.toAxisAngle();
    //translate(250, y+50, 0);
    // translate(100, 100+y, 0); //avoid colliding with background zero plane by going in foreground
    translate(b.position.x, b.position.y, b.position.z);

    // čára síly
    float s = 0.01;
    stroke(255, 0, 0);
    line(0, 0, 0, b.accel.x*s, b.accel.y*s, b.accel.z*s);

    // čára gravitace
    stroke(0, 255, 0);
    PVector g = b.getGravity();
    line(0, 0, 0, g.x*s, g.y*s, g.z*s);


    // čára odečtená gravitace
    // stroke(0, 0, 255);
    // PVector areal = b.getGravityAdjustedAccel();
    // line(0, 0, 0, areal.x*s, areal.y*s, areal.z*s);


    // rotate(axis[0], -axis[1], axis[3], axis[2]);
    rotate(axis[0], axis[2], axis[1], -axis[3]);
    stroke(255);
    // barvení podle eventu
    fill(100);

    s = 10; //20
    box(2*s);
    stroke(255, 0, 0);
    fill(255, 0, 0);
    // označím jednu stranu pro lepší orientaci
    line(s, -s, -s, s, s, s);
    line(s, s, -s, s, -s, s); 

    popMatrix();

    y += 200;
  }
  
}

void sendConnect(NetAddress addr) {
    osc.send(addr, "/connect");
}

void stop() {
  for (Module b : moduleManager.getModules()) {
    b.disconnect();
  }
} 

void keyPressed() {
  switch(key) {
    case('c'):
      ArrayList<InetAddress> broadcasts = getBroadcastInetAddresses();
      for (InetAddress broadcast : broadcasts) {
        println(broadcast);
        NetAddress addr = new NetAddress(broadcast, 7777);
        sendConnect(addr);
      }
    break;
    case('o'):
      for (Module b : moduleManager.getModules()) {
        b.offset();
      }
    break;
    case('k'):
      for (Module b : moduleManager.getModules()) {
        b.calibrate();
      }
    break;
    case('d'):
      for (Module b : moduleManager.getModules()) {
        b.disconnect();
      }
    break;
  }
}

void oscEvent(OscMessage message) {
  // println("received a message", message);
  // println(message.getIP());
  if (message.getAddress().startsWith(prefix)) {
    moduleManager.parseMessage(message);
  }
}
