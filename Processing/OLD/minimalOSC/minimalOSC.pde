void setup() {
  size(640, 480, P2D);
  openSerial(portName);
}

void draw() {
  for (int i = 0; i<timeSerialDebounce.length; i++) {
    //------SERIAL---------------------
    terminateCommandToSerial(i); //Terminate command
  }

  if ( frameCount%10==0 ) {
    surface.setTitle(" FPS: "+round(frameRate) );
  }
}
