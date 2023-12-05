//for calculating zscore - see code folder
import java.util.function.BiConsumer;
import org.apache.commons.math3.distribution.NormalDistribution;
import org.apache.commons.math3.distribution.RealDistribution;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

//for thread control:
import java.util.concurrent.atomic.AtomicBoolean;
Replay replay;
boolean replayLoaded = false;

void initReplay(){
replay = new Replay();
}

class Replay implements Runnable {
  ArrayList<File>datafiles;
  ArrayList<String>tableNames = new ArrayList<String>();
  String selectedFileName = "";
  //ArrayList<String>tableAddresses = new ArrayList<String>();
  Table table = null;
  boolean loop = false;
  long timeStarted = 0;

  int rowIndex = 0;

  boolean readNext = true;
  boolean replaying = false;
  long currTimetag = 0;
  OscMessage oscMessage = null;

  Thread localThread;
  long threadStartTime = 0;

  NetAddress remoteAddress;

  AtomicBoolean threadActive = new AtomicBoolean(true);

  Replay() {
    /*
    //debug loading
    while ( millis() < 10000) {
      ;
    }
    */
    replayLoaded = false;
    init();
  }

  //-------------------
  void init() {
    datafiles = loadFiles(dataPath("recordedData"), ".csv") ;
    int currPort = defaultOSCport;
    if (gui !=null) {
      currPort = int( gui.slider("OSC/OSC port", defaultOSCport) );
    }
    remoteAddress = new NetAddress("127.0.0.1", currPort );

    if ( datafiles.size()>0) {
      tableNames.clear();
      for (int d=0; d<datafiles.size(); d++) {
        tableNames.add( datafiles.get(d).getName() );
      }

      if (tableNames.size()<1) {
        tableNames.add("no files found");
      }
      //push names into GUI folder
      if (gui != null ) {
        selectedFileName = gui.radio("replay/files", tableNames);
      } else {
        selectedFileName = tableNames.get(0);
      }
      //selectedFileName = gui.radio("replay/files", tableNames);

      File tableFile = getTableFile(selectedFileName);
      if (tableFile !=null) {
        String filepath = tableFile.getAbsolutePath(); //getName()
        table = loadTable(filepath, "header");
        println("loaded table: "+tableFile.getName()+" "+table.getRowCount() + " rows");
      }
    }
    replayLoaded = true;
  }
  //------------------------
  File getTableFile(String filnam) {
    for (int i=0; i<datafiles.size(); i++) {
      if ( filnam.equals( datafiles.get(i).getName() ) ) {
        return datafiles.get(i);
      }
    }
    return null;
  }
  //------------------------
  //void update() {
  void run() {
    while (threadActive.get()) {

      while (replaying && table!=null) {
        //if (replaying && table!=null) {
        if (readNext) {
          if (rowIndex>table.getRowCount()-1) {
            println("end of the replayed file reached");
            stopReplay();
            break;
          }
          TableRow currRow = table.getRow(rowIndex);
          oscMessage = parseRow(currRow);
          currTimetag = currRow.getLong("timestamp");
          //println(currTimetag);
          readNext = false;
          rowIndex++;
        }
        //-----
        if ( oscMessage!= null ) {
          if (currTimetag<(millis()-timeStarted)  ) { //time to replay
            if (oscP5 != null ) {
              oscP5.send(remoteAddress, oscMessage);
            }
            //udp.send(oscMessage.getBytes(), "127.0.0.1", 7777 ); //proxy to OSC tab parser
            readNext = true; //read another row
            oscMessage = null;//prevent duplicities being send
          }
        }
        //------
      }
    }//thread active check ends
  }

  void stopReplay() {
    replaying = false;
    oscMessage = null;
    rowIndex = 0;
    threadActive.set(false);
  }

  void play() {
    init();

    //selectedFileName = gui.radio("replay/files", tableNames);
    threadActive.set(true);

    rowIndex = 0;
    timeStarted = millis();
    replaying = true;
    readNext = true;

    localThread = new Thread(this);
    threadStartTime = millis();
    localThread.start();
  }

  //-----------------------------------------
  //create OSC message packet from the .csv table
  OscMessage parseRow(TableRow row) {
    try {
      //long timestamp = row.getLong("timestamp");
      String OSCaddress = row.getString("OSCaddress");
      String OSCtypetag = row.getString("typetag");
      OscMessage m = new OscMessage(OSCaddress);
      for (int i=0; i<OSCtypetag.length(); i++) {
        Character currType = OSCtypetag.charAt(i);
        if ( currType.equals('f') ) {
          m.add( row.getFloat(i+3) );
        } else if ( currType.equals('i') ) {
          m.add( row.getInt(i+3) );
        } else if ( currType.equals('s') ) {
          m.add( row.getString(i+3) );
        } else if ( currType.equals('d') ) {
          m.add( row.getDouble(i+3) );
        }
      }
      //println(m);
      return m;
    }
    catch(Exception e) {
      println(e);
    }
    return null;
  }
  //-------------------
  class Dataset {
    ArrayList<Float>[] vals;
    Dataset(int size) {
      vals = new ArrayList[size];
      for (int i=0; i<vals.length; i++) { //initialize
        vals[i] = new ArrayList<Float>();
      }
    }

    void add(int index, float val) {
      vals[index].add(val);
    }

    void analyze() {
      for (int i=0; i<vals.length; i++) {
        double[] values = floatListToDoubleArray(vals[i]);
        computeZScoreAndSurvivalFunctions(values);
      }
    }
  }

  //-------------------
  void analyzeData() {
    if (table!=null) {
      Dataset quats = new Dataset(4);
      Dataset accels = new Dataset(3);

      for (TableRow row : table.rows()) {
        OscMessage m = parseRow(row);
        float[] values;
        if (m.getAddress().contains("quat") && m.checkTypetag("ffff")) {
          //values = m.floatValues(0, 4);
          //println(m.floatValue(1));
          for (int i = 0; i<m.getTypetag().length(); i++) {
            quats.add(i, m.floatValue(i) );
            //quats.add(i, values[i]);
          }
        }

        if (m.getAddress().contains("aaWorld") && m.checkTypetag("fff") ) {
          for (int i = 0; i<m.getTypetag().length(); i++) {
            accels.add(i, m.floatValue(i) );
          }
        }
        //println(timestamp + "," + OSCaddress + "," + OSCtypetag);
      }//table end
      //zcore
      quats.analyze();
      accels.analyze();
    }//table not null
  }
  //-------------------
  void computeZScoreAndSurvivalFunctions( double[] values ) {
    DescriptiveStatistics ds = new DescriptiveStatistics(values);
    RealDistribution dist = new NormalDistribution();
    double variance = ds.getPopulationVariance();
    double sd = Math.sqrt(variance);
    double mean = ds.getMean();

    System.out.printf("| %4s | %4s | %4s | %4s |%n", "original", "zscore", "sf", "mapped");
    System.out.printf("--------------------------------%n");

    float min = 999999999;
    float max = -999999999;

    for ( int index = 0; index < ds.getN(); ++index) {
      double zscore = (ds.getElement(index)-mean)/sd;
      if (zscore<min) {
        min = (float)zscore;
      }
      if (zscore> max) {
        max = (float)zscore;
      }

      //double sf = 1.0 - dist.cumulativeProbability(Math.abs(zscore));
      //System.out.printf("%5d | %5f | %5f | %5f | %n", (int)ds.getElement(index), zscore, sf, map((float)zscore, -3, 3, 0, 1) );
      //println("original: "+ds.getElement(index)+" zscore: "+zscore+" sf: "+sf+" mapped: "+map((float)zscore,-3,3,0,1) );
    }

    for ( int index = 0; index < ds.getN(); ++index) {
      double zscore = (ds.getElement(index)-mean)/sd;
      double sf = 1.0 - dist.cumulativeProbability(Math.abs(zscore));
      System.out.printf("%5d | %5f | %5f | %5f | %n", (int)ds.getElement(index), zscore, sf, map((float)zscore, min, max, 0, 1) );
      //println("original: "+ds.getElement(index)+" zscore: "+zscore+" sf: "+sf+" mapped: "+map((float)zscore,-3,3,0,1) );
    }
  }

  //------------
}

/*
//skeleton of limiting thread framerate
 double interpolation = 0;
 final int TICKS_PER_SECOND = 25;
 final int SKIP_TICKS = 1000 / TICKS_PER_SECOND;
 final int MAX_FRAMESKIP = 5;
 
 @Override
 public void run() {
 double next_game_tick = System.currentTimeMillis();
 int loops;
 
 while (true) {
 loops = 0;
 while (System.currentTimeMillis() > next_game_tick
 && loops < MAX_FRAMESKIP) {
 
 update_game();
 
 next_game_tick += SKIP_TICKS;
 loops++;
 }
 
 interpolation = (System.currentTimeMillis() + SKIP_TICKS - next_game_tick
 / (double) SKIP_TICKS);
 display_game(interpolation);
 }
 }
 */
