import java.net.SocketException;

import java.net.NetworkInterface;
import java.net.InetAddress;
import java.net.InterfaceAddress;
import java.net.Inet4Address;
import java.util.Enumeration;
import java.util.List;

//scan for all avaliable ips
ArrayList<InetAddress> getBroadcastInetAddresses() {
  ArrayList<InetAddress>ips = new ArrayList<InetAddress>();
  try {
    Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      NetworkInterface iface = interfaces.nextElement();
      if (iface.isLoopback() || !iface.isUp())
        continue;
      List<InterfaceAddress> addresses = iface.getInterfaceAddresses();
      for (InterfaceAddress address : addresses) {
        InetAddress broadcast = address.getBroadcast();
        // check ipv4
        if (broadcast != null && broadcast instanceof Inet4Address) {
          ips.add(broadcast);
        }
      }
    }
  }
  catch (SocketException e) {
    println(e);
  }

  return ips;
}
