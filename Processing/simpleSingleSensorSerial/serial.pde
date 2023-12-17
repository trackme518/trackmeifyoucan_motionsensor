import processing.serial.*; //import Serial
Serial myPort;
boolean serialEnabled = true;

//----------------------------------
//SERIAL - send request to sensor to start sending data over USB instead of WiFi
//you can be connected to only one serial port at a time

void enablemodeserial(boolean val) { //switch between wifi and serial mode
  sendToSerial( new OscMessage( "/mode/serial", val) );
}

void connectSerial() {
  sendToSerial( new OscMessage( "/connect/serial") );
}

void disconnectSerial() {
  sendToSerial( new OscMessage( "/disconnect/serial") );
}
//------------------------------------------

//serial event listener - constantly listens for incoming bytes
void serialEvent(Serial p) {
  //decode the message
  while (p.available () > 0) {
    decodeSLIP((byte)p.readChar());
  }
}
//----------------SERIAL-----------------------
//recieves the OSC over serial port

int baudrate = 115200;

//----------------------------

//------------------------------
//store the bytes in a buffer
private int SLIP_SERIAL_BUFFER_SIZE = 1024; //somehow ti gets exceeded - when smaller and big bundles send....I should check for parallel acces...
private byte[] buffer = new byte[SLIP_SERIAL_BUFFER_SIZE];

//the serial object
//some slip constants
private byte eot = (byte) 0300;
private byte slipesc = (byte) 0333;
private byte slipescend = (byte) 0334;
private byte slipescesc = (byte) 0335;
int bufferIndex = 0;

//open given serial port for commmunication - serial ports are exclusive - you need to close the port in other application otherwise it will fail
//(like Arduino Serial monitor for example)
void openSerial(String comName) {
  // go throught all avaliable serial port and try to find match between comName and avaliable ports
  String[] avaliableSerialPorts = Serial.list();
  boolean matchFound = false;
  println("----------------------");
  println("Avaliable serial ports:");
  for (int i=0; i<avaliableSerialPorts.length; i++) {
    println( avaliableSerialPorts[i] );
    if (avaliableSerialPorts[i].equals(comName)) {
      println("matching serial port name found");
      matchFound = true;
      break;
    }
  }
  println("----------------------");

  if (!matchFound) {
    println("No matching Serial name found");
    serialEnabled = false;
    return;
  }
  //-----------------
  try {
    portName = comName;
    //you can also use Serial.list()[0] instead of portName - to open first serial port found
    myPort = new Serial(this, portName, baudrate);
    portName = comName;
    println("Serial port "+portName+" opened");
    serialEnabled = true;
  }
  catch(Exception e) {
    println(e);
    serialEnabled = false;
  }
}

//============================================
//send OSC message to sensor over serial
void sendToSerial( OscMessage m ) {
  if (myPort==null || !serialEnabled) {
    println("serial not enabled");
    return; //RuntimeException: Error writing to serial port COM3: Port not opened
  }
  byte[] data = m.getBytes();
  //encode the message and send it
  for (int i = 0; i < data.length; i++) {
    slipEncode(data[i]);
  }
  //write the eot
  myPort.write(eot);
  println("command send to serial");
}

//-----------------------------------------
//SLIP ENCODING
void slipEncode(byte incoming) {
  //serial must be opened at this point
  if (incoming == eot) {
    myPort.write(slipesc);
    myPort.write(slipescend);
  } else if (incoming==slipesc) {
    myPort.write(slipesc);
    myPort.write(slipescesc);
  } else {
    myPort.write(incoming);
  }
}
//-------------------------
//DECODING
//adds a byte to the buffer
void flushBuffer() {
  buffer = new byte[SLIP_SERIAL_BUFFER_SIZE]; //reset buffer
  bufferIndex = 0;
}

private void addToBuffer(byte toAdd) {
  if (bufferIndex<SLIP_SERIAL_BUFFER_SIZE) {
    try {
      //put the char in the buffer
      buffer[bufferIndex] = toAdd;
      //increment the counter
      bufferIndex++;
    }
    catch (Exception e) {
      println(e);
      flushBuffer(); //reset buffer
    }
  }
}

//does the slip decoding and adds it to the buffer
private void decodeSLIP(byte inByte) {
  //byte inByte = (byte) serial.readChar();
  if (inByte==slipesc) {
    //then read the next one
    byte next = inByte;
    if (next==slipescend) {
      addToBuffer(eot);
    } else if (next==slipescesc) {
      addToBuffer(slipesc);
    }
  }
  //if its the end of transmission
  else if (inByte==eot) {
    try {
      if (bufferIndex>0) {
        udp.send( buffer, "127.0.0.1", 7777 );
        flushBuffer();
      }
    }
    catch(Exception e) {
      println(e);
    }
  } else {
    addToBuffer(inByte);
  }
}
