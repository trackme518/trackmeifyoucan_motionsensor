//save recorded events for later
import java.io.FileWriter;
import java.io.BufferedWriter;

Recorder recorder = new Recorder();

class Recorder {
  //boolean recevents = false; //flag to save the incoming events to text file
  boolean recordingEvents = false; //flag to save the incoming events to text file
  boolean convertNtpToUnix = false; //whether to convert timetag of the incoming OSC msg to UNIX format (easier format)
  String recpath; // = dataPath("recordedEvents_"+day()+"_"+month()+"_"+year()+"-"+ int( random(0,1)*1000 )+".csv");
  int recTimeOffset = 0;
  boolean firtEventSaved = false; //first event was saved
  PrintWriter output;

  Recorder() {
  }

  //save incoming events to text file with timestamp
  void saveEvent( OscMessage msg ) {

    if (output != null && recordingEvents) {
      //println(" timetag: "+msg.timetag());
      int currtime = millis();
      if (!firtEventSaved) {
        recTimeOffset = millis();
        firtEventSaved = true;
        
        if (guiSound!=null) {
          guiSound.playClick();//play click sound to enable synchronizing external video recorded with the OSC events recording
        }
        
      }

      String addr = msg.addrPattern();
      String typetag = msg.typetag();

      //get timetag - this is only present in OSC bundle messages otherwise equals to 1
      //convert to unix because NTP is stupid
      long timetag = msg.timetag();
      if (convertNtpToUnix) {
        if ( timetag != 1) {
          timetag = ntpToUnix( timetag );
        }
      }

      String record = str(currtime-recTimeOffset)+","+addr+","+typetag+","+timetag+",";

      for (int i=0; i< typetag.length(); i++) {
        Character currType = typetag.charAt(i);
        if ( currType.equals('f') ) {
          record+=str( msg.get(i).floatValue() )+",";
        }
        if ( currType.equals('i') ) {
          record+=str( msg.get(i).intValue() )+",";
        }
        if ( currType.equals('s') ) {
          record+= msg.get(i).stringValue() +",";
        }
        if ( currType.equals('d') ) {
          record+= String.valueOf( msg.get(i).doubleValue() ) +","; //cast double to string
        }
      }

      record = record.substring(0, record.length()-1);//trim last comma
      //println( record );
      output.println( record );//output to buffered writer
    }
  }

  //init output file strea
  void startRecEvent() {
    recpath = dataPath("recordedData/rec-"+day()+"_"+month()+"_"+year()+"-"+hour()+"_"+minute()+"_"+second()+"-"+ int( random(0, 1)*1000 )+".csv"); //reset record path
    output = createWriter(recpath);
    recordingEvents = true;
    String header ="timestamp,OSCaddress,typetag,timetag";
    output.println( header ); //write header to the file
    println("recording started to "+recpath);
  }

  //close and flush file output stream
  void stopRecEvent() {
    if (output != null) {
      output.flush();
      output.close();
    }
    recordingEvents = false;
    firtEventSaved = false;
    recTimeOffset = 0;
    println("recording stoped");
  }
}
//----------------------------------------------------------------------------------------------------------------------------
