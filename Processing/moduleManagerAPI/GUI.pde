void keyPressed() {
  if (key=='c') {
    if (!serialEnabledGlobal) {
      WiFiConnect connectThread = new WiFiConnect (true);
      println("send WiFi connect request");
    } else {
      serialManager.startSerialScan(); //send connect request to all avaliable serial ports and wait for response
      println("send Serial connect request");
    }
  } else if (key=='d') {
    if (!serialEnabledGlobal) {
      WiFiConnect connectThread = new WiFiConnect (false);
    } else {
      serialManager.closeSerial();
    }
    println("send disconnect request");
  } else if (key=='s') {
    serialEnabledGlobal = !serialEnabledGlobal;
    println("serial mode set to: "+serialEnabledGlobal);
  }
}
