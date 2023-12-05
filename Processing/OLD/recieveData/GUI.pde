void keyPressed() {
  if (key=='a') {
    if ( ipIndex+1<localIPs.size()) {
      ipIndex++;
    } else {
      ipIndex = 0;
    }
    localIP = localIPs.get(ipIndex);
  } else if (key=='c') {
    connect(localIP);
  } else if (key=='s') {
    modules.get(0).setssid("motion");
  }
}
