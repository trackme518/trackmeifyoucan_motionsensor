//UDP communication
UDP udp;

String ipAddress = "127.0.0.1";

void setupUDP() {
  udp = new UDP( this );
  //udp.log( true );     // <-- printout the connection activity
}

void stopUDP() {
  udp.close();
}

void UDPSendBuffer(byte[] data) {
  udp.send( data, ipAddress, oscPort );
}

//called when UDP receives some data
void receive( byte[] data) {
  drawIncomingUDP();
  //send it over to serial
  serialSend(data);
}
