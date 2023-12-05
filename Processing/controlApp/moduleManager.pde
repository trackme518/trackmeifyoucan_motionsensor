ModuleManager moduleManager;

class ModuleManager {
  boolean sendOverSerial = false;

  public ArrayList<Module> modules = new ArrayList<Module>();
  Module selectedModule = null;
  PGraphics pg;//picker offscreen buffer
  float mouseOffsetX = 0;//offset when object first clicked
  float mouseOffsetY = 0;

  ModuleManager() {
    modules = new ArrayList<Module>();
    pg = createGraphics(width, height, P3D);
    pg.beginDraw();
    pg.background(0);
    pg.endDraw();
  }

  void add(Module m) {
    modules.add(m);
  }

  void run() {
    for (int i=0; i<modules.size(); i++) {
      Module m = modules.get(i);
      m.update();
      m.render();
    }

    pickerDrawbuffer(); //render each module flat shaded in semiunique color into offcscreen buffer
    //image(pg,0,0); //debug picker

    if ( mousePressed && (selectedModule!=null) && gui.isMouseOutsideGui()) {//only when NOT hovering over GUI
      selectedModule.pos.set(mouseX+mouseOffsetX, mouseY+mouseOffsetY, 0);
    }

    //-------------------------------------
    //GUI updates - start actions for all modules
    if (gui.button("WiFi/save settings")) {
      println("save WiFi changes");
      for (int i=0; i<modules.size(); i++) {
        Module m = modules.get(i);
        m.setssid(gui.text("WiFi/SSID", defaultSSID));
        m.setpass(gui.text("WiFi/WiFi Password", defaultWiFiPass));
        m.sethostidip(int(gui.slider("WiFi/host IP id", defaultHostIpId)));
      }
    }
    //----------------
    if ( gui.button("offset position") ) {
      for (int i=0; i<modules.size(); i++) {
        modules.get(i).offset();
      }
    }
    //--------
    if ( gui.button("calibrate IMU") ) {
      for (int i=0; i<modules.size(); i++) {
        modules.get(i).calibrate();
      }
    }
    //--------
    if ( gui.button("WiFi/reset WiFi setup") ) {
      println("reset wifi settings for all modules");
      for (int i=0; i<modules.size(); i++) {
        modules.get(i).resetwifi();
      }
    }
    //--------
    if ( gui.button("restart") ) {
      println("hard restart all modules");
      for (int i=0; i<modules.size(); i++) {
        modules.get(i).restart(); //restart the MCU
      }
    }
    //--------
    if ( gui.button("factory reset") ) {
      println("erase all preferences saved in EEPROM and restart all modules");
      for (int i=0; i<modules.size(); i++) {
        modules.get(i).factoryreset(); //restart the MCU
      }
    }
    //--------
    /*
    boolean guiserial = gui.toggle("send over Serial", sendOverSerial);//switch module to send over serial mode / wifi
    if ( guiserial!=sendOverSerial) {
      sendOverSerial = guiserial;
      enablemodeserial(sendOverSerial); //send over serial with global function
    }
    */
    //-------------------------------------
  }

  Module get(int i) {
    return modules.get(i);
  }

  int count() {
    return modules.size();
  }

  int getPickerColor(int mx, int my) {
    return pg.get(mx, my);
  }

  void pickerDrawbuffer() {
    pg.beginDraw();
    pg.background(0);
    pg.ortho();
    for (int i=0; i<modules.size(); i++) {
      Module m = modules.get(i);
      m.renderPicker(pg);
    }
    pg.endDraw();
    //image(pg,0,0);
  }

  Module getSelected(float mx, float my) { //input is mouse coordinates
    int colAtMouse = getPickerColor(int(mx), int(my));
    //println("colAtMouse "+colAtMouse);
    for (int i=0; i<modules.size(); i++) {
      Module m = modules.get(i);
      //println(m.pickerColor);
      if ( m.pickerColor == colAtMouse) {
        selectedModule = m;
        //println("selected: "+m.id); 
        mouseOffsetX = selectedModule.pos.x-mx;
        mouseOffsetY = selectedModule.pos.y-my;
        return selectedModule;
      }
    }
    //println("deselected");
    selectedModule = null;
    return selectedModule;
  }

  void deselect() {
    //println("deselected");
    selectedModule = null;
    mouseOffsetX = 0;
    mouseOffsetY = 0;
  }
}
