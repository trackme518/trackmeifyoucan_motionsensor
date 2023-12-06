ModuleManager moduleManager;

class ModuleManager {
  boolean sendOverSerial = false;

  public ArrayList<Module> modules = new ArrayList<Module>();
  Module selectedModule = null;

  float mouseOffsetX = 0;//offset when object first clicked
  float mouseOffsetY = 0;

  ModuleManager() {
    modules = new ArrayList<Module>();
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
  }

  Module get(int i) {
    return modules.get(i);
  }

  int count() {
    return modules.size();
  }
}
