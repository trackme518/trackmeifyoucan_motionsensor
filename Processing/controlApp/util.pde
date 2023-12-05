import java.io.File;

//recursively scan the given path for all files inside subdirs
void walkFiles( ArrayList<File>foundfiles, String path ) {
  File root = new File( path );
  File[] list = root.listFiles();
  if (list == null) return;
  for ( File f : list ) {
    if ( f.isDirectory() ) {
      //String currpath = f.getAbsolutePath();
      //currpath = currpath.replace("\\", "\\\\");
      walkFiles( foundfiles, f.getAbsolutePath() );
      //println( "Dir:" + f.getAbsoluteFile() );
    } else {
      //println( "File:" + f.getAbsoluteFile() );
      foundfiles.add(f);
    }
  }
}

String[] arrayListToStringArray(ArrayList<String>arr) {
  if (arr.isEmpty()) {
    String[] empty = {""};
    return  empty;
  }
  Object[]arrobj = arr.toArray();
  return Arrays.copyOf(arrobj, arrobj.length, String[].class);
}

ArrayList<File> loadFiles(String dirpath, String ext) {
  //tintObjShader = loadShader(PShader.FLAT, dataPath("shaders/tintFrag.glsl"));
  ArrayList<File>avaliableFiles = new ArrayList<File>();
  ArrayList<File>datafiles = new ArrayList<File>();
  walkFiles( datafiles, dirpath );

  for (int i=0; i<datafiles.size(); i++) {
    String path = datafiles.get(i).getAbsolutePath();

    if (path.toLowerCase().endsWith(ext)) {
      //println(path);
      avaliableFiles.add( datafiles.get(i) );
    }
  }
  return avaliableFiles;
}

ArrayList<String>getPathsFromFiles(ArrayList<File>filelist) {
  ArrayList<String>paths = new ArrayList<String>();
  for (int i=0; i<filelist.size(); i++) {
    paths.add( filelist.get(i).getAbsolutePath() );
  }
  return paths;
}
//------------------------------------------------------------------------------
public static long ntpToUnix(long ntpTimestamp) {
  final long NTP_EPOCH_OFFSET = 2208988800L; // Number of seconds between 1900-01-01 and 1970-01-01
  final long NTP_FRACTION_SCALE = 1L << 32; // 2^32
  // Extract seconds and fraction parts from NTP timestamp
  long ntpSeconds = ntpTimestamp >>> 32;
  long ntpFraction = ntpTimestamp & 0xFFFFFFFFL; // Treat as unsigned
  // Convert NTP timestamp to Unix timestamp
  long unixSeconds = ntpSeconds - NTP_EPOCH_OFFSET;
  long unixMillis = (long) ((double) ntpFraction / (double) NTP_FRACTION_SCALE * 1000.0);
  long unixTimestamp = unixSeconds * 1000L + unixMillis;
  return unixTimestamp+1; //+1 is arbitrary - but it seems missing somehow
}

public static long unixToNtp(long unixTimestamp) {
  final long NTP_EPOCH_OFFSET = 2208988800L; // Number of seconds between 1900-01-01 and 1970-01-01
  final long NTP_FRACTION_SCALE = 1L << 32; // 2^32
  // Convert Unix timestamp to NTP timestamp
  long ntpSeconds = unixTimestamp / 1000L + NTP_EPOCH_OFFSET;
  long ntpFraction = (long) ((double) (unixTimestamp % 1000L) / 1000.0 * (double) NTP_FRACTION_SCALE);
  // Combine seconds and fraction into a single long value
  long ntpTimestamp = (ntpSeconds << 32) | (ntpFraction & 0xFFFFFFFFL); // Treat as unsigned
  ntpTimestamp = ntpTimestamp & 0x7FFFFFFFFFFFFFFFL; // Mask out sign bit - treat as unsigned
  return ntpTimestamp;
}
//----------------------------------------------------------------------------------
public static double[] convertFloatsToDoubles(float[] input) {
  if (input == null)
  {
    return null; // Or throw an exception - your choice
  }
  double[] output = new double[input.length];
  for (int i = 0; i < input.length; i++)
  {
    output[i] = input[i];
  }
  return output;
}
//---------------------------
// ArrayList to Array Conversion
float[] listToArray( ArrayList<Float> al) {
  float[] arr = new float[al.size()];
  for (int i = 0; i < al.size(); i++) {
    arr[i] = al.get(i);
  }
  return arr;
}

double[] floatListToDoubleArray( ArrayList<Float> al) {
  double[] arr = new double[al.size()];
  for (int i = 0; i < al.size(); i++) {
    arr[i] = (double)al.get(i);
  }
  return arr;
}
