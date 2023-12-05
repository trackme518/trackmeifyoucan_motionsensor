// import UDP library - needed to proxy the serial byte buffer to myself as UDP packet
import hypermedia.net.*;
import processing.serial.*; //import Serial
Serial myPort; //this has to be public in order for serialEvent listener to function...oh my

boolean serialEnabledGlobal = false;
SerialManager serialManager;
//long[] timeSerialDebounce = new long[5];//setup timers
//boolean[] terminated = new boolean[5];
//int wait = 250; //change the time for light bulbs delay

//-----------------------------------
void serialEvent(Serial p) {
  //decode the message
  while (p.available () > 0) {
    serialManager.decodeSLIP((byte)p.readChar());
    //serialManager.decodeSLIP(byte(p.read()));
  }
}
//----------------SERIAL-----------------------
class SerialManager {
  int baudrate = 115200;
  //int baudrate = 921600; //921600;
  PApplet context;
  boolean serialEnabled = false;
  //Serial myPort;  // global - has to be public in main class for listener to work
  String portName = "COM3"; //Serial.list()[0] Serial port - specify
  //int val;        // Data received from the serial port
  String[] avaliableSerialPorts;

  //----------------------------
  //try to automatically find the right serial port
  int pingSerialIndex = 0; //iterate over all serial port interfaces to find the right one
  long lastSerialPingTime = 0; //the last time we sent connect request to the serial port
  boolean scanSerial = false;
  //------------------------------
  //UDP udp;  // define the UDP object

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
    //udp = new UDP(context);
    initSerial();
    //gui.radio( "SERIAL port", avaliableSerialPorts, portName ); //not needed we scan for it automatically

    buffer = new byte[SLIP_SERIAL_BUFFER_SIZE];
  }

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
      gui.toggleSet("SERIAL enabled", serialEnabled); //set to false
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
      gui.toggleSet("SERIAL enabled", serialEnabled); //set to false
    }
    /*
    //reset global avrs
     for (int i=0; i<5; i++) {
     timeSerialDebounce[i]  = millis();//store the current time
     terminated[i] = false;
     }
     */
  }

  //avaliableSerialPorts = Serial.list();
  //for (int i=0; i<avaliableSerialPorts.length; i++) {
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
    //delay(1000);
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


/*
void sendCommandToSerial(int ID) {
 if (serialEnabled && (myPort!=null)) {
 if (ID<5) {
 myPort.write(str(ID)); // send a sipmple number ID to indicate catch to relay server
 timeSerialDebounce[ID] = millis();
 terminated[ID]=false; //enable terminate command
 //println("turn on "+ID);
 }
 }
 }
 
 void terminateCommandToSerial(int ID) {
 if (serialEnabled && (myPort!=null)) {
 //Terminate light ON
 if ((ID<5) && (terminated[ID]==false)) {
 if (millis() >timeSerialDebounce[ID] +wait) {
 myPort.write(str(ID+5));
 //println("turn off"+ID );
 terminated[ID]=true; //set terminate flag to avoid multiple commands
 }
 }
 }
 }
 */
