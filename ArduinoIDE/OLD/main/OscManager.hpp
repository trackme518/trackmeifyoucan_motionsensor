#ifndef OSCMANAGER_HPP
#define OSCMANAGER_HPP

#include <OSCMessage.h>
#include <OSCBundle.h>
#include <WiFiUdp.h>
#include <functional>
#include "WifiManager.hpp"
#include "ImuManager.hpp"

class OSCManager {
private:
  WiFiUDP Udp;
  WifiManager &wifiman;
  ImuManager &imuman;

  void establishConnection(OSCMessage &msg) {
    char ipServerAddress[18];
    msg.getString(0, ipServerAddress, 18);
    wifiman.unicastIP.fromString(ipServerAddress);
    delay(100);
    wifiman.directConnection = true;
#ifdef DEBUG
    Serial.print("Received content:");
    Serial.println(ipServerAddress);
    Serial.print("IP address:");
    Serial.println(wifiman.unicastIP);
    Serial.print("Port: ");
    Serial.println(wifiman.port);
#endif
  }
  void disconnect(OSCMessage &msg) {
    wifiman.directConnection = false;
  }

  void parseOSC(OSCMessage &msg, const IPAddress &remoteip) {
    boolean hasip = false;
    if (msg.fullMatch("/connect")) {
      Serial.println("connect request");
      if (msg.size() > 0) {  // it has a value
        char ipServerAddress[18];
        msg.getString(0, ipServerAddress, 18);
        IPAddress currip;
        if (currip.fromString(ipServerAddress)) {  // str = char * or String
          // it is a valid IP address
          Serial.println("connect request: custom IP");
          wifiman.unicastIP.fromString(ipServerAddress);
          hasip = true;
        } else {
          Serial.println("invalid IP");
        }
      }

      if (!hasip) {
        Serial.println("connect request: no IP specified - use incoming IP: ");
        Serial.println(remoteip);
        wifiman.unicastIP = remoteip;
      }

      String ipMsgString = msgPrefix + "/" + ID + "/ip";  // report back my ip in return
      OSCMessage ipMsg(ipMsgString.c_str());
      ipMsg.add(wifiman.currentIP.toString());
      sendOSC(ipMsg);

      Serial.println("connection established");
      delay(100);
      wifiman.directConnection = true;
    } else if (msg.fullMatch("/disconnect")) {
      Serial.println("Disconnecting");
      disconnect(msg);
    } else if (msg.fullMatch("/zeroPosition")) {
      Serial.println("Zeroing position");
      imuman.zeroPosition();
      imuman.getZeroPosition();
    } else if (msg.fullMatch("/calibrate")) {
      Serial.println("Calibrating");
      imuman.calibrate(true);
    } else if (msg.fullMatch("/treshold/throw/set")) {
      Serial.print("Changing throw treshold: ");
      Serial.println(msg.getInt(0));
      imuman.setThrowThreshold(msg.getInt(0));
    } else if (msg.fullMatch("/treshold/throw/get")) {
      Serial.print("Treshold: ");
      Serial.println(imuman.getThrowThreshold());
      String responseMsgString = msgPrefix + "/" + ID + "/treshold/throw";
      OSCMessage responseMsg(responseMsgString.c_str());
      responseMsg.add(imuman.getThrowThreshold());
      sendOSC(responseMsg);
    } else if (msg.fullMatch("/id/set")) {  // SET CUSTOM OSC ID --------------------------------------------
      char charnewid[12];                   // limit user entered ID to X characters - we do NOT want an overflow here
      // fill strnewid buffer with X characters from the 0th datum
      msg.getString(0, charnewid, 13);  // copy max X characters
      // int charlength = strlen(charnewid);
      if (strlen(charnewid) < 1) {  // empty charr array - likely user exceeded maximum allowed characters
        Serial.println("max 12 characters allowed");
        String errorMsgString = msgPrefix + "/" + ID + "/error";
        OSCMessage errorMsg(errorMsgString.c_str());
        errorMsg.add("max 12 characters allowed");
        sendOSC(errorMsg);
        return;
      }
      charnewid[strlen(charnewid)] = '\0';  //properly null terminate
      ID = String(charnewid);               // convert char array to string here.
      wifiman.saveID();
    } else if (msg.fullMatch("/hostidip/set")) {  // SET UNICAST ID HSOT IP --------------------------------------------
      wifiman.idHostIP = msg.getInt(0);           //set last number in unicast target IP
      Serial.print("change saveIdHostIP: ");
      Serial.print(wifiman.idHostIP);
      wifiman.saveIdHostIP();  //save into persistant memory
      //reply with changed idHostIP to confirm the change
      String responseMsgString = msgPrefix + "/" + ID + "/idhostip";
      OSCMessage responseMsg(responseMsgString.c_str());
      responseMsg.add(wifiman.idHostIP);
      sendOSC(responseMsg);
    } else if (msg.fullMatch("/ssid/set") || msg.fullMatch("/pass/set")) {  // SET WIFI SETUP----------------
      char charnewstr[33];                                                  // limit user entered ID to X characters - we do NOT want an overflow here
      // fill strnewid buffer with X characters from the 0th datum
      msg.getString(0, charnewstr, 32);  // copy max X characters
      // int charlength = strlen(charnewid);
      if (strlen(charnewstr) < 1) {  // empty charr array - likely user exceeded maximum allowed characters
        String errorMsgString = msgPrefix + "/error";
        OSCMessage errorMsg(errorMsgString.c_str());
        errorMsg.add("max 32 characters allowed");
        sendOSC(errorMsg);
        return;
      }

      String responseMsgString = msgPrefix + "/" + ID + "/response";
      OSCMessage responseMsg(responseMsgString.c_str());
      charnewstr[strlen(charnewstr)] = '\0';  //properly null terminate
      if (msg.fullMatch("/ssid/set")) {
        ssid = String(charnewstr);  // convert char array to string here
        responseMsg.add("ssid set: " + String(charnewstr));
      } else {
        pass = String(charnewstr);  // convert char array to string here
        responseMsg.add("pass set: " + String(charnewstr));
      }
      sendOSC(responseMsg);

      wifiman.saveWifiSetup();  // save to preferences
      //-------------------------------------------------------------------------------------------------
    } else if (msg.fullMatch("/restart")) {
      String responseMsgString = msgPrefix + "/" + ID + "/response";
      OSCMessage responseMsg(responseMsgString.c_str());
      responseMsg.add("restarted");
      sendOSC(responseMsg);
      Serial.println("restart");
      ESP.restart();
    } else if (msg.fullMatch("/wifi/reset")) {
      String responseMsgStringSSID = msgPrefix + "/" + ID + "/ssid";
      OSCMessage responseMsgSSID(responseMsgStringSSID.c_str());
      responseMsgSSID.add(defaultssid);
      sendOSC(responseMsgSSID);

      String responseMsgStringPASS = msgPrefix + "/" + ID + "/pass";
      OSCMessage responseMsgPASS(responseMsgStringPASS.c_str());
      responseMsgPASS.add(defaultpass);
      sendOSC(responseMsgPASS);

      Serial.println("reset wifi setup");
      wifiman.resetWifiSetup();
    } else if (msg.fullMatch("/resetid")) {
      Serial.println("reset id:");
      String responseMsgString = msgPrefix + "/" + ID + "/newid";
      OSCMessage responseMsg(responseMsgString.c_str());
      ID = String(wifiman.getChipId());  // actually set new ID
      Serial.println(ID);
      responseMsg.add(ID.c_str());  // send new ID at old ID address - so that client can change it
      sendOSC(responseMsg);
      wifiman.saveID();  // save to memory
    } else if (msg.fullMatch("/port/set")) {
      int16_t newPortNum = msg.getInt(0);
      Serial.print("Changing OSC port: ");
      Serial.println(newPortNum);
      wifiman.setPort(newPortNum);  // change port number and save to eeprom
    } else if (msg.fullMatch("/prefix/set")) {
      char charnewstr[33];  // limit user entered ID to X characters - we do NOT want an overflow here
      // fill strnewid buffer with X characters from the 0th datum
      msg.getString(0, charnewstr, 32);  // copy max X characters
      // int charlength = strlen(charnewid);
      if (strlen(charnewstr) < 1) {  // empty charr array - likely user exceeded maximum allowed characters
        String errorMsgString = msgPrefix + "/" + ID + "/error";
        OSCMessage errorMsg(errorMsgString.c_str());
        errorMsg.add("max 32 characters allowed");
        sendOSC(errorMsg);
        return;
      }
      charnewstr[strlen(charnewstr)] = '\0';
      msgPrefix = String(charnewstr);  // convert char array to string here
      saveOSCprefix();
    } else if (msg.fullMatch("/prefix/get")) {
      String responseMsgString = msgPrefix + "/" + ID + "/prefix";
      OSCMessage prefixMsg(responseMsgString.c_str());
      prefixMsg.add(msgPrefix);
      sendOSC(prefixMsg);
    } else if (msg.fullMatch("/prefix/reset")) {
      msgPrefix = defaultMsgPrefix;  // revert to default and save to memory
      saveOSCprefix();
    } else if (msg.fullMatch("/factoryreset")) {
      Serial.println("factory reset intiated");
      wifiman.deletePreferences();  //delete WiFi preferences
      imuman.deletePreferences();   //delete IMU preferences including calibration data
      deletePreferences();          //delete this class preferences - OSC prefix & ID
      ESP.restart();                //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/osc/reset")) {
      Serial.println("osc preferences reset intiated");
      deletePreferences();  //delete this class preferences - OSC prefix & ID
      ESP.restart();        //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/imu/reset")) {
      Serial.println("IMU preferences reset intiated");
      imuman.deletePreferences();  //delete IMU preferences including calibration data
      ESP.restart();               //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/wifi/reset")) {
      Serial.println("WiFi preferences reset intiated");
      wifiman.deletePreferences();  //delete WiFi preferences
      ESP.restart();                //restart ESP so changes take effect
    }
  }

public:
  OSCManager(WifiManager &wifiman, ImuManager &imuman)
    : wifiman(wifiman), imuman(imuman){};

  void begin() {
    Udp.begin(wifiman.port);
    getOSCprefix();  // load OSC prefix from memory
  }

  void receiveOSC() {
    int size = Udp.parsePacket();
    if (size > 0) {
      OSCMessage inboundMsg;
#ifdef DEBUG
      Serial.print("Recieved packet of size ");
      Serial.println(size);
#endif
      while (size--) {
        inboundMsg.fill(Udp.read());
      }
      if (!inboundMsg.hasError()) {
        // if (!inboundMsg.hasError() && inboundMsg.size() > 0) {
        const IPAddress hostip = Udp.remoteIP();  // must be constant otherwise I can not get a pointer to it
        parseOSC(inboundMsg, hostip);
      }
#ifdef DEBUG
      else {
        Serial.print("Error parsing OSC: ");
        Serial.println(inboundMsg.getError());
      }
#endif
    }
  }

  void sendOSC(OSCMessage &msg) {
    Udp.beginPacket(wifiman.unicastIP, wifiman.port);
    msg.send(Udp);
    Udp.endPacket();
  }
  void sendOSC(OSCBundle &bundle) {
    Udp.beginPacket(wifiman.unicastIP, wifiman.port);
    bundle.send(Udp);
    Udp.endPacket();
  }

  void saveOSCprefix() {
    // save to EEPROM or something like that ;-)
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.putString("prefix", msgPrefix);
    preferences.end();
    Serial.println("OSC msg prefix set: " + msgPrefix);
  }

  void deletePreferences() {
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.clear();  // Remove all preferences under the opened namespace
    preferences.end();
  }

  void getOSCprefix() {
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    msgPrefix = preferences.getString("prefix", defaultMsgPrefix);  // second param is default value if it fails to retrieve
    preferences.end();
    Serial.println("OSC msg prefix: " + msgPrefix);
  }
};

#endif
