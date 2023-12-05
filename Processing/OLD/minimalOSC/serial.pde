import processing.serial.*;
boolean serialEnabled = true;

long[] timeSerialDebounce = new long[5];//setup timers
boolean[] terminated = new boolean[5];
int wait = 250; //change the time for light bulbs delay

//----------------SERIAL-----------------------
Serial myPort;  // Create object from Serial class
String portName = "COM5"; //Serial.list()[0] Serial port - specify


void openSerial(String comName) {
  println("Avaliable Serial ports:");
  printArray(Serial.list());
  println("-------------------");
  
  if (myPort!=null) {
    println("Serial port "+portName+" closed");
    myPort.stop(); //stop previously opened serial
  }
  try {
    myPort = new Serial(this, portName, 115200);
    portName = comName;
    println("Serial port "+portName+" opened");
    serialEnabled = true;
  }
  catch(Exception e) {
    println(e);
    serialEnabled = false;
  }

  //reset global avrs
  for (int i=0; i<5; i++) {
    timeSerialDebounce[i]  = millis();//store the current time
    terminated[i] = false;
  }
}

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
