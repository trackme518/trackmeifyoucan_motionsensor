import java.io.InputStreamReader; //for returning value from exec shell
import java.util.Arrays; //for returning value from exec shell
import java.lang.System; //detect current OS - needed for OS specific shell commands - notably connecting to WiFi from GUI

void runCmd(String cmdstr) {
  try {
    Process Return = Runtime.getRuntime().exec(cmdstr); //run the shell file
    println(Return);
  }
  catch (IOException e) {
    e.printStackTrace();
  }
}

String runCmdReturn(String[] args) {
  String outcmd = "";
  Runtime runtime = Runtime.getRuntime();
  try {
    Process process = runtime.exec(args);
    //Process process = runtime.exec(args);
    InputStream is = process.getInputStream();
    InputStreamReader isr = new InputStreamReader(is);
    BufferedReader br = new BufferedReader(isr);
    String line;

    System.out.printf("Output of running %s is:",
      Arrays.toString(args));

    //Arrays.toString(cmdstr));


    while ((line = br.readLine()) != null) {
      outcmd = outcmd+line;
      println(line);
      System.out.println(line);
    }
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  return outcmd;
}
