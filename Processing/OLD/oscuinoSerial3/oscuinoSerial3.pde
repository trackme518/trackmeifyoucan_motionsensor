//import com.illposed.osc.utility.*;
//import com.illposed.osc.*;
import processing.serial.*;
Serial myPort;

import oscP5.*;
import netP5.*;
import java.net.InetAddress;

import hypermedia.net.*;
UDP udp;
OscP5 oscP5;
// The serial port:
//Serial arduino;
//the slip decoder/encoder
SLIPEncodedSerial SLIPSerial;


void setup() {
  size(320, 100);
  frameRate(200);
  //  I use the first port which is usually the Arduino

  udp = new UDP(this);
  oscP5 = new OscP5(this, 7777 );

  SLIPSerial = new SLIPEncodedSerial(this);
  //myPort = new Serial(this, "COM3", 115200);
  //setup the drawing output

  background(0);
}

void draw() {
}

void serialEvent(Serial p) {
  while (p.available () > 0) {
    //println((byte)p.readChar());
    SLIPSerial.decodeSLIP((byte)p.readChar());
  }
}

void oscEvent(OscMessage m) {
  println( "Address: " + m.getAddress()+" from IP: " + m.getIP()+" Typetag: " + m.getTypetag()  );
}

//SLIP ENCODED SERIAL
//encodes/decodes SLIP coming from the arduino's serial port
public class SLIPEncodedSerial {
  PApplet context;
  //store the bytes in a buffer
  private int SLIP_SERIAL_BUFFER_SIZE = 512;
  private byte[] buffer;

  //the serial object
  //some slip constants
  private byte eot = (byte) 0300;
  private byte slipesc = (byte) 0333;
  private byte slipescend = (byte) 0334;
  private byte slipescesc = (byte) 0335;
  int bufferIndex = 0;
  //Serial myPort;

  public SLIPEncodedSerial (PApplet that) {
    context = that;
    buffer = new byte[SLIP_SERIAL_BUFFER_SIZE];
    //serial = ser;
    myPort = new Serial(context, "COM3", 115200);
  }

  //adds a byte to the buffer
  private void addToBuffer(byte toAdd) {
    //increment the head
    if(bufferIndex<SLIP_SERIAL_BUFFER_SIZE){
      //put the char in the buffer
      buffer[bufferIndex] = toAdd;
      bufferIndex++;
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
          if (udp!=null) {
              udp.send( buffer, "127.0.0.1", 7777 );
              buffer = new byte[SLIP_SERIAL_BUFFER_SIZE]; //reset buffer
              bufferIndex = 0;
          }
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
