class ModuleManager {
  HashMap<String, Module> modules;
  OscP5 osc;

  ModuleManager(OscP5 osc) {
    this.osc = osc;
    modules = new HashMap<String, Module>();
  }

  public void parseMessage(OscMessage message) {
    String address = message.getAddress();
    String[] splitAddress = split(address, '/');
    if (splitAddress.length < 2) {
      println("invalid module address: "+address);
      return;
    }

    String id = splitAddress[2];
    String property = splitAddress[3];
    if (modules.containsKey(id)) {
      Module m = modules.get(id);

      m.updateProperty(property, message);
    }
    else {
      println("no module with id: "+id);

      String ip = message.getIP();
      modules.put(id, new Module(id, ip, osc));
    }
  }

  public ArrayList<Module> getModules() {
    return new ArrayList<Module>(modules.values());
  }
}