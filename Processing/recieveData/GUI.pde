void keyPressed() {
  if (key=='c') {
    WiFiConnect connectThread = new WiFiConnect (true);
    println("send connect request");
  } else if (key=='d') {
    WiFiConnect connectThread = new WiFiConnect (false);
    println("send disconnect request");
  }else if (key=='s') {
    serialEnabledGlobal = !serialEnabledGlobal;
    println("serial mode set to: "+serialEnabledGlobal);
  }
}
