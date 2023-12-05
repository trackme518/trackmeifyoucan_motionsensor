import java.util.concurrent.atomic.AtomicBoolean; //prevent conflict when checking on separate thread
import java.lang.InterruptedException;

import processing.serial.*; //import Serial


// import UDP library - needed to proxy the serial byte buffer to myself as UDP packet
import hypermedia.net.*;

ControlSubThread serialManager;

void setup() {
  size(640, 480, P2D);
  initOSC();
  serialManager = new ControlSubThread(this);
  serialManager.start(); //start the process on separate thread
  
}

void draw() {
  if ( frameCount%10==0 ) {
    surface.setTitle("Serial test fps: "+round(frameRate)+ " OSC fps: "+oscFps );
  }
}


class ControlSubThread implements Runnable {

  Serial myPort = null;

  private Thread worker;
  private final AtomicBoolean running = new AtomicBoolean(false);
  private int interval;

  //the serial object
  //some slip constants
  final byte eot = (byte) 0300;
  final byte slipesc = (byte) 0333;
  final byte slipescend = (byte) 0334;
  final byte slipescesc = (byte) 0335;

  UDP udp;

  int bufferIndex = 0;
  final int bufferSize = 1024;
  byte[] buffer = new byte[bufferSize];

  public ControlSubThread( PApplet context) {
    myPort = new Serial(context, "COM3", 115200); //open serial
    udp = new UDP(this); //without listener
  }

  public void start() {
    worker = new Thread(this);
    worker.start();
  }

  public void stop() {
    running.set(false);
  }

  void addToBuffer(byte toAdd) {
    if (bufferIndex<buffer.length) {
      buffer[bufferIndex] = toAdd;
      bufferIndex++;
    }
  }
  //------------------------
  public void run() {
    running.set(true);



    while (running.get()) {
      if (myPort!=null) {
        while (myPort.available () > 0) {
          byte inByte = (byte)myPort.readChar();
          //println(inByte);
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
                //println(bufferIndex);
                udp.send( buffer, "127.0.0.1", 7777 );
                buffer = new byte[bufferSize]; //reset buffer
                bufferIndex = 0;
                //flushBuffer();
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
    }
  }//end run fce
  //--------------------------------
}//end serial class
