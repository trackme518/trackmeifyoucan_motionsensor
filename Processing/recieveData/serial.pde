import processing.serial.*; //import Serial
Serial myPort; //this has to be public in order for serialEvent listener to function...oh my

boolean serialEnabledGlobal = false;
SerialManager serialManager;
//long[] timeSerialDebounce = new long[5];//setup timers
//boolean[] terminated = new boolean[5];
//int wait = 250; //change the time for light bulbs delay


//----------------------------------
//SERIAL - send request to sensor to start sending data over USB instead of WiFi
//you can be connected to only one serial port at a time
//we will send connect request to all serial ports and we are waiting for reply - if it comes from given port we know this is the port we need to use
void enablemodeserial(boolean val) { //switch between wifi and serial mode
  serialManager.sendToSerial( new OscMessage( "/mode/serial", val) );
}

void connectSerial() {
  serialManager.sendToSerial( new OscMessage( "/connect/serial") );
}

void disconnectSerial() {
  serialManager.sendToSerial( new OscMessage( "/disconnect") );
}
//------------------------------------------

//serial event listener
void serialEvent(Serial p) {
  //decode the message
  while (p.available () > 0) {
    serialManager.decodeSLIP((byte)p.readChar());
    //serialManager.decodeSLIP(byte(p.read()));
  }
}
//----------------SERIAL-----------------------
//main class that recieves the OSC over serial port
class SerialManager {
  int baudrate = 115200;
  PApplet context;
  boolean serialEnabled = false;
  String portName = "COM3"; //Serial.list()[0] Serial port - specify
  String[] avaliableSerialPorts;
  //----------------------------
  //try to automatically find the right serial port
  int pingSerialIndex = 0; //iterate over all serial port interfaces to find the right one
  long lastSerialPingTime = 0; //the last time we sent connect request to the serial port
  boolean scanSerial = false;
  //------------------------------
  //store the bytes in a buffer
  private int SLIP_SERIAL_BUFFER_SIZE = 1024; //somehow ti gets exceeded - when smaller and big bundles send....I should check for parallel acces...
  private byte[] buffer;

  //the serial object
  //some slip constants
  private byte eot = (byte) 0300;
  private byte slipesc = (byte) 0333;
  private byte slipescend = (byte) 0334;
  private byte slipescesc = (byte) 0335;
  int bufferIndex = 0;

  SerialManager(PApplet that) {
    context = that;
    initSerial();
    buffer = new byte[SLIP_SERIAL_BUFFER_SIZE];
  }
  //list all ports
  void initSerial() {
    avaliableSerialPorts = Serial.list();
    if (avaliableSerialPorts.length<1) {
      println("No Serial port avaliable");
      avaliableSerialPorts = new String[1];
      avaliableSerialPorts[0] = "no serial found";
    }
    println("ports: //----------------");
    println(avaliableSerialPorts);
    println("-------------------------");
  }
  //close currently opened serial port
  void closeSerial() {
    if (myPort!=null) {
      enablemodeserial(false); //let module send data over WiFi instead
      //does not work every time?
      serialEnabled = false; //set a flag to mark that serial port is closed inside this class
      myPort.clear();// Clear the buffer, or available() will still be > 0
      myPort.stop(); //stop previously opened serial
      flushBuffer();
      println("Serial port "+portName+" closed");
    }
  }
  //open given serial port for commmunication - serial ports are exclusive - you need to close the port in other application otherwise it will fail (like Arduino Serial monitor for example)
  void openSerial(String comName) {
    //initSerial();
    closeSerial(); //try to close first
    avaliableSerialPorts = Serial.list();
    boolean matchFound = false;
    for (int i=0; i<avaliableSerialPorts.length; i++) {
      if (avaliableSerialPorts[i].equals(comName)) {
        matchFound = true;
        break;
      }
    }
    if (!matchFound) {
      println("No matching Serial name found");
      serialEnabled = false;
      return;
    }

    try {
      portName = comName;
      myPort = new Serial(context, portName, baudrate);
      portName = comName;
      println("Serial port "+portName+" opened");
      serialEnabled = true;
    }
    catch(Exception e) {
      println(e);
      serialEnabled = false;
    }
  }

  void scanSerialInterfaces() {
    if (scanSerial) {
      if ( millis()-100>lastSerialPingTime ) {
        pingSerial(pingSerialIndex);
        lastSerialPingTime = millis();
        pingSerialIndex++;
        if ( pingSerialIndex >avaliableSerialPorts.length-1) { //we tried all of them
          stopSerialPortScan(); //serial was not
        }
      }
    }
  }

  void startSerialScan() {
    scanSerial = true;
  }

  void stopSerialPortScan() {
    scanSerial = false;
    pingSerialIndex = 0;
    lastSerialPingTime = 0;
    println("Serial port interfaces scan finished");
  }

  void pingSerial(int serialIndex) {
    openSerial(avaliableSerialPorts[serialIndex]);//open the port
    connectSerial(); //send connect message
  }

  //============================================
  void sendToSerial( OscMessage m ) {
    if (myPort==null || !serialEnabled) {
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
}
