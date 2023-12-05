import toxi.geom.Quaternion;

class Module {
  String id;
  String ip;
  Quaternion rot; //current rotation
  PVector ypr;
  PVector accel;
  PVector smoothAccel;
  PVector velocity;
  PVector smoothVelocity;
  PVector position;
  long lastUpdate = 0;
  NetAddress remoteAddress;
  OscP5 osc;

  Module(String id, String ip, OscP5 osc) {
    this.id = id;
    this.ip = ip;
    this.osc = osc;
    rot = new Quaternion(1, 0, 0, 0);
    ypr = new PVector(0, 0, 0);
    smoothAccel = new PVector(0, 0, 0);
    accel = new PVector(0, 0, 0);
    velocity = new PVector(0, 0, 0);
    smoothVelocity = new PVector(0, 0, 0);
    position = new PVector(200.0, 200.0, 0);
    remoteAddress = new NetAddress(ip, sensorPort);
  }

  void setQuatRotation(Quaternion q) {
    rot.set(q);
  }

  void setYpr(PVector newypr) {
    ypr.set(newypr);
  }

  void setAccel(PVector newAccel) {
    accel.set(newAccel);
  }

  void offset() {
    osc.send(remoteAddress, "/zeroPosition", true);
  }

  void calibrate() {
    osc.send(remoteAddress, "/calibrate", true);
  }

  void disconnect() {
    osc.send(remoteAddress, "/disconnect", true);
  }

  public String toString() {
      String s = "id: " + id + " ip: " + ip + " rot: " + rot + " ypr: " + ypr + " accel: " + accel;
      return s;
  }

  PVector getGravity() {
    PVector gravity = new PVector(0, 0, 0);
    gravity.x = 2 * (rot.x * rot.z - rot.w * rot.y);
    gravity.y = 2 * (rot.w * rot.x + rot.y * rot.z);
    gravity.z = rot.w * rot.w - rot.x * rot.x - rot.y * rot.y + rot.z * rot.z;
    return gravity;
  }

  PVector getGravityAdjustedAccel() {
    PVector gravity = getGravity();
    return accel.copy().sub(gravity);
  }

  void updateProperty(String property, OscMessage message) {
    switch (property) {
      case "quat":
        if (message.getArguments().length == 4) {
          rot.set(message.floatValue(0), message.floatValue(1), message.floatValue(2), message.floatValue(3));
        }
        break;
      case "ypr":
        if (message.getArguments().length == 3) {
          ypr.set(message.floatValue(0), message.floatValue(1), message.floatValue(2));
        }
        break;
      case "aaReal":
        if (message.getArguments().length == 3) {
          PVector a_old = accel.copy();
          // println(accel);
          accel.set(message.floatValue(0), message.floatValue(1), message.floatValue(2));

          // int t = millis();
          // int num_points = gui.sliderInt("num_points", 100, 10, 1000);
          // if (plot2 != null) {
          //   // while (plot2.getPointsRef("x").getNPoints() > num_points)
          //   //   plot2.removePoint(0, "x");
          //   plot2.getLayer("x").addPoint(t, accel.x);

          //   // while (plot2.getPointsRef("y").getNPoints() > num_points)
          //   //   plot2.removePoint(0, "y");
          //   plot2.getLayer("y").addPoint(t, accel.y);

          //   // while (plot2.getPointsRef("z").getNPoints() > num_points)
          //   //   plot2.removePoint(0, "z");
          //   plot2.getLayer("z").addPoint(t, accel.z);
                
          //   // while (plot2.getPointsRef("mag").getNPoints() > num_points)
          //   //   plot2.removePoint(0, "mag");
          //   plot2.getLayer("mag").addPoint(t, accel.mag());
          // }



          // hack: high-pass filter the acceleration 
          float alpha = gui.slider("highpass_accel", 0.99, 0, 1);
          smoothAccel = accel.copy().mult(1-alpha).add(smoothAccel.copy().mult(alpha));
          accel.sub(smoothAccel);

          // accel.div(16384.0);
          // println(accel);
          // PVector realAccel = getGravityAdjustedAccel();
          if (gui.slider("accel_threshold", 30) > accel.mag()) {
            velocity.set(0, 0, 0);
            smoothVelocity.set(0, 0, 0);
          }
          else {

            float dt = 1/16384.0*100;
            String mode = gui.radio("integration", new String[]{"euler", "verlet"});
            if (mode.equals("euler")){
              // euler
              velocity.add(accel.copy().mult(dt));
              position.add(velocity.copy().mult(dt));
            }
            else if (mode.equals("verlet")){
              // verlet
              position.add(velocity.copy().mult(dt).add(a_old.copy().mult(0.5*dt*dt)));
              velocity.add(accel.copy().add(a_old.copy()).mult(0.5*dt));
            }

            // high-pass filter the velocity
            float beta = gui.slider("highpass_velocity", 1.0, 0, 1);
            smoothVelocity = velocity.copy().mult(1-beta).add(smoothVelocity.copy().mult(beta));
            velocity.sub(smoothVelocity);
          }


          // hacks
          velocity.mult(gui.slider("friction", 1.0, 0, 1));
          if (gui.toggle("steer to 0 z position", true))
            position.z = position.z * 0.99;

          if (position.x < 0 || position.x > width || position.y < 0 || position.y > height || gui.button("reset position")) {
            position.set(width/2, height/2, 0);
          }
          if (gui.button("reset velocity")) {
            velocity.set(0, 0, 0);
          }
        }
        break;
      default:
        // println("unknown property: "+property+" message: "+message);
        break;
    }
  }
}
