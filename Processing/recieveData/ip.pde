import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.regex.*;

import java.net.InetAddress;
import java.net.UnknownHostException;

import java.util.*;
import java.lang.reflect.*;

//scan for all avaliable ip addresses
ArrayList<String> getIp() {
  ArrayList<String>ips = new ArrayList<String>();
  try {
    Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      NetworkInterface iface = interfaces.nextElement();
      // filters out 127.0.0.1 and inactive interfaces
      if (iface.isLoopback() || !iface.isUp())
        continue;

      Enumeration<InetAddress> addresses = iface.getInetAddresses();
      while (addresses.hasMoreElements()) {
        InetAddress addr = addresses.nextElement();
        String ip = addr.getHostAddress();
        //System.out.println(iface.getDisplayName() + " " + ip);
        //println(ip);
        boolean valid = isValidIPAddress(ip);
        if (valid) {
          //System.out.println(iface.getDisplayName() + " " + ip);
          //--------------------------

          boolean isReachable = false;
          try {
            if (addr.isReachable(500)) { //delay 500
              isReachable = true;
            }
          }
          catch(Exception e) {
            println(e);
          }
          //----
          if (isReachable) {
            //System.out.println("can b pinged");
            // machine is turned on and can be pinged
            String currName = iface.getDisplayName();
            if ( !currName.toLowerCase().contains("virtual") ) { //exclude virtual adapters (like WmWare)
              println(currName + " " + ip);
              //println( "HOST ADDRESS : "+addr.getHostAddress() );
              ips.add(ip);
            }
          } else if (!addr.getHostAddress().equals(addr.getHostName())) {
            //System.out.println("Name is......"+addr.getHostName()+"\tIP is......."+addr.getHostAddress());
            // machine is known in a DNS lookup
          } else {
            System.out.println("nothing");
            // the host address and host name are equal, meaning the host name could not be resolved
          }
          //------------------------------
        }
        //println( "VALID: "+valid);
      }
    }
    ips.add("127.0.0.1"); //add local host for debugging
    return ips;
  }
  catch (SocketException e) {
    println(e);
    return ips;
    //throw new RuntimeException(e);
  }
}


// Function to validate the IPs address.
boolean isValidIPAddress(String ip) {
  // Regex for digit from 0 to 255.
  String zeroTo255
    = "(\\d{1,2}|(0|1)\\"
    + "d{2}|2[0-4]\\d|25[0-5])";
  // Regex for a digit from 0 to 255 and
  // followed by a dot, repeat 4 times.
  // this is the regex to validate an IP address.
  String regex
    = zeroTo255 + "\\."
    + zeroTo255 + "\\."
    + zeroTo255 + "\\."
    + zeroTo255;
  // Compile the ReGex
  Pattern p = Pattern.compile(regex);
  // If the IP address is empty
  // return false
  if (ip == null) {
    return false;
  }
  // Pattern class contains matcher() method
  // to find matching between given IP address
  // and regular expression.
  Matcher m = p.matcher(ip);
  // Return if the IP address
  // matched the ReGex
  if (m.matches()) {
    return true;
  }
  return false;
  //return m.matches();
}
