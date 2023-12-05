#ifndef OSCMANAGER_HPP
#define OSCMANAGER_HPP

#include <OSCBundle.h>
#include <OSCBoards.h>
#include <OSCMessage.h>
#include <SLIPEncodedSerial.h>

#ifdef BOARD_HAS_USB_SERIAL
SLIPEncodedUSBSerial SLIPSerial(thisBoardsSerialUSB);
#else
SLIPEncodedSerial SLIPSerial(Serial);  // Change to Serial1 or Serial2 etc. for boards with multiple serial ports that don’t have Serial
#endif

#include <WiFiUdp.h>
#include <functional>
#include "WifiManager.hpp"
#include "ImuManager.hpp"

class OSCManager {
public:
  boolean senddata = true;

private:
  WiFiUDP Udp;
  WifiManager &wifiman;
  ImuManager &imuman;

/*
  void establishConnection(OSCMessage &msg) {
    char ipServerAddress[18];
    msg.getString(0, ipServerAddress, 18);
    wifiman.unicastIP.fromString(ipServerAddress);
    delay(100);
    wifiman.directConnection = true;
  }
  */

  void parseOSC(OSCMessage &msg, const IPAddress &remoteip) {
    boolean hasip = false;
    if (msg.fullMatch("/connect")) {
      ////Serial.println("connect request");
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

      ////Serial.println("connection established");
      delay(100);
      senddata = true;
    } else if (msg.fullMatch("/disconnect")) {
      Serial.println("Disconnecting WiFi");
      senddata = false;
    } else if (msg.fullMatch("/offset")) { //else if (msg.fullMatch("/zeroPosition")) {
      ////Serial.println("Zeroing position");
      imuman.zeroPosition();
      imuman.getZeroPosition();
    } else if (msg.fullMatch("/calibrate")) {
      ////Serial.println("Calibrating");
      imuman.calibrate(true);
    } else if (msg.fullMatch("/treshold/throw/set")) {
      //Serial.print("Changing throw treshold: ");
      ////Serial.println(msg.getInt(0));
      imuman.setThrowThreshold(msg.getInt(0));
    } else if (msg.fullMatch("/treshold/throw/get")) {
      //Serial.print("Treshold: ");
      ////Serial.println(imuman.getThrowThreshold());
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
        ////Serial.println("max 12 characters allowed");
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
      //Serial.print("change saveIdHostIP: ");
      //Serial.print(wifiman.idHostIP);
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
      ////Serial.println("restart");
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

      ////Serial.println("reset wifi setup");
      wifiman.resetWifiSetup();
    } else if (msg.fullMatch("/resetid")) {
      ////Serial.println("reset id:");
      String responseMsgString = msgPrefix + "/" + ID + "/newid";
      OSCMessage responseMsg(responseMsgString.c_str());
      ID = String(wifiman.getChipId());  // actually set new ID
      ////Serial.println(ID);
      responseMsg.add(ID.c_str());  // send new ID at old ID address - so that client can change it
      sendOSC(responseMsg);
      wifiman.saveID();  // save to memory
    } else if (msg.fullMatch("/port/set")) {
      int16_t newPortNum = msg.getInt(0);
      //Serial.print("Changing OSC port: ");
      ////Serial.println(newPortNum);
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
      ////Serial.println("factory reset intiated");
      wifiman.deletePreferences();  //delete WiFi preferences
      imuman.deletePreferences();   //delete IMU preferences including calibration data
      deletePreferences();          //delete this class preferences - OSC prefix & ID
      ESP.restart();                //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/osc/reset")) {
      ////Serial.println("osc preferences reset intiated");
      deletePreferences();  //delete this class preferences - OSC prefix & ID
      ESP.restart();        //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/imu/reset")) {
      ////Serial.println("IMU preferences reset intiated");
      imuman.deletePreferences();  //delete IMU preferences including calibration data
      ESP.restart();               //restart ESP so changes take effect
    } else if (msg.fullMatch("/preferences/wifi/reset")) {
      ////Serial.println("WiFi preferences reset intiated");
      wifiman.deletePreferences();  //delete WiFi preferences
      ESP.restart();                //restart ESP so changes take effect
    } else if (msg.fullMatch("/mode/serial")) {
      boolean val = msg.getBoolean(0);
      String responseMsgString = msgPrefix + "/" + ID + "/serialmode";
      OSCMessage responseMsg(responseMsgString.c_str());
      responseMsg.add(val);  //confirm mode change over new communication protocol
      sendOSC(responseMsg);  //reply on previous interface

      serialMode = val;  //set in global var

    } else if (msg.fullMatch("/debug/serial")) {
      //OSCBundle bundle;
      String responseMsgString = msgPrefix + "/" + ID + "/debug";
      OSCMessage msg(responseMsgString.c_str());
      msg.add("this msg is from serial");
      sendOSCSerial(msg);
    } else if (msg.fullMatch("/connect/serial")) {  //reply to queried serial port                            //has to be bundle for the SLIP parser in Processing to be able to read it...
      String responseMsgString = msgPrefix + "/" + ID + "/connect/serial";
      OSCMessage responseMsg(responseMsgString.c_str());
      responseMsg.add(true);
      sendOSCSerial(responseMsg);  //always send over serial!
      serialMode = true;           //switch to sending sensor data over serial as well - seems practical
      senddata = true;
    }
  }

public:
  OSCManager(WifiManager &wifiman, ImuManager &imuman)
    : wifiman(wifiman), imuman(imuman){};

  void begin() {
    Udp.begin(wifiman.port);
    getOSCprefix();  // load OSC prefix from memory

    //start OSC over Serial
    //moved to setup()...
    //SLIPSerial.begin(115200);  // set this as high as you can reliably run on your platform
  }

  void receiveOSC() {
    OSCMessage msgIN;
    int size;
    //read OSC over WiFi -----------------------
    size = Udp.parsePacket();
    if (size > 0) {
      OSCMessage inboundMsg;
      while (size--) {
        inboundMsg.fill(Udp.read());
      }
      if (!inboundMsg.hasError()) {
        const IPAddress hostip = Udp.remoteIP();  // must be constant otherwise I can not get a pointer to it
        parseOSC(inboundMsg, hostip);
      } else {
        Serial.println("UDP OSC msg has errors");
      }
    }
    //read OSC over Serial ------------------------

    //OSCMessage msgIN;
    //int size;

    static unsigned long microsTime = 0;
    boolean serialMsgRecieved = false;
    while (!SLIPSerial.endofPacket()) {
      if ((size = SLIPSerial.available()) > 0) {
        microsTime = micros();
        while (size--) {  //this needs a byte limit
          msgIN.fill(SLIPSerial.read());
        }
        serialMsgRecieved = true;
      }
      if ((micros() - microsTime) > 10000) {  //1000 micro seconds == 1ms
        serialMsgRecieved = false;            //only partial msg recieved or error occured
        break;                                //Timeout for no eoP()
      }
    }

    if (serialMsgRecieved) {
      if (!msgIN.hasError()) {
        const IPAddress hostip = IPAddress(127, 0, 0, 1);  //fake ip -> serial has no ID
        parseOSC(msgIN, hostip);
      }
    }

    //----------------------------------------
  }
  //-----------------------------------------
  //SEND DATA OUT
  //overloaded function :-) - send as you like
  void sendOSC(OSCMessage &msg) {
    if (serialMode) {  //global var
      sendOSCSerial(msg);
    } else {
      sendOSCUdp(msg);
    }
    msg.empty();  // free space occupied by message
  }

  void sendOSC(OSCBundle &bundle) {
    if (serialMode) {  //global var
      sendOSCSerial(bundle);
    } else {
      sendOSCUdp(bundle);
    }
    bundle.empty();  // free space occupied by message
  }
  //--------------------------
  //send over Serial
  void sendOSCSerial(OSCMessage &msg) {
    SLIPSerial.beginPacket();
    msg.send(SLIPSerial);    // send the bytes to the SLIP stream
    SLIPSerial.endPacket();  // mark the end of the OSC Packet
  }

  void sendOSCSerial(OSCBundle &bundle) {
    SLIPSerial.beginPacket();
    bundle.send(SLIPSerial);  // send the bytes to the SLIP stream
    SLIPSerial.endPacket();   // mark the end of the OSC Packet
  }
  //send over WiFi UDP mode
  void sendOSCUdp(OSCMessage &msg) {
    Udp.beginPacket(wifiman.unicastIP, wifiman.port);
    msg.send(Udp);
    Udp.endPacket();
  }

  void sendOSCUdp(OSCBundle &bundle) {
    Udp.beginPacket(wifiman.unicastIP, wifiman.port);
    bundle.send(Udp);
    Udp.endPacket();
  }
  //----------------------------------------------------
  void saveOSCprefix() {
    // save to EEPROM or something like that ;-)
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.putString("prefix", msgPrefix);
    preferences.end();
    ////Serial.println("OSC msg prefix set: " + msgPrefix);
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
    ////Serial.println("OSC msg prefix: " + msgPrefix);
  }
};

#endif
