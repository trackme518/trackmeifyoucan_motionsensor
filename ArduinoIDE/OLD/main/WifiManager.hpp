#ifndef WIFIMANAGER_HPP
#define WIFIMANAGER_HPP

#include <WiFi.h>
#include <WiFiUdp.h>
#include <Preferences.h>

String defaultssid = "3motion";
String defaultpass = "datainmotion";

String ssid = defaultssid;
String pass = defaultpass;
#define WIFI_PREF_NAMESPACE "WIFI"  // preferences ->something like eeprom, allocate unique space in storage

class WifiManager {
public:
  IPAddress currentIP;
  IPAddress broadcast;
  IPAddress unicastIP;
  //the last number in IP adress that we will target - we will append it to currentIP to create unicastIP
  int idHostIP = 233;

  int16_t defaultPort = 7777;
  int16_t port = defaultPort;
  volatile bool directConnection = false;

  void begin() {
    Serial.println("Initializing Wifi");
    Serial.println("Network settings:");
    //--------------------------------

    loadWifiSetup();  // load ssid and password from preferences
    getPort();        // load OSC port number from preferences, defaults to defaultPort
    getID();          // load ID from preferences, default to unique 16bit int based on MAC
                      //load last number in target IP address where we send sensor data
    getIdHostIP();    //this way we can avoid connect request

    smartConnect();  // scan if AP exists - if not create a new one

    Serial.print("IP address: ");
    Serial.println(currentIP);
    broadcast = currentIP;
    broadcast[3] = 255;
    Serial.print("Broadcast: ");
    Serial.println(broadcast);
    unicastIP = currentIP;
    unicastIP[3] = idHostIP;
    //we just assume that target is there - since we are using UDP we don't care about timeout
    directConnection = true;  //this will trigger the data sending to unicastIP
  }

  void smartConnect() {
    Serial.println("Set to station mode for scanning");
    WiFi.mode(WIFI_STA);
    Serial.println("** Scan Networks **");
    int numSsid = WiFi.scanNetworks();
    Serial.print(numSsid);
    Serial.println(" networks found");
    bool ap_found = false;

    // check for the AP--------------------------------------
    for (int thisNet = 0; thisNet < numSsid; thisNet++) {
      String thisSsid = WiFi.SSID(thisNet);
      Serial.print("\t");
      Serial.print(thisSsid);
      if (thisSsid == ssid.c_str()) {
        Serial.print(" = AP found !!!");
        ap_found = true;
      }
      Serial.println();
    }

    if (!ap_found) {
      Serial.println("No running AP found");
    }

    if (numSsid == -1) {
      Serial.println("Couldn't find any wifi connection");
    }

    if (!ap_found) {  // if we have not found a running ap
      beginAP();
    }
    // client scenario - connect to ap
    if (ap_found) {
      beginClient();
    }
    //-------------------------------------------------
  }
  //ultity function to get unique number based on MAC¨
  //this should be semiunique for each MCU so we can flash universally
  uint16_t getChipId() {
    uint64_t chipid = ESP.getEfuseMac();  // The chip ID is essentially its MAC address(length: 6 bytes).
    // Serial.printf("ESP32 Chip ID = %04X\n", (uint16_t)(chipid >> 32));  //print High 2 bytes
    // Serial.printf("%08X\n",(uint32_t)chipid);//print Low 4bytes.
    uint16_t chip = (uint16_t)(chipid >> 32);
    return chip;
  }
  //------------------------------------
  //OSC ID
  void getID() {
    uint16_t chip = getChipId();
    // check preferences if ID is already set by user
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    ID = preferences.getString("id", (String)chip);  // second param is default value if it fails to retrieve
    preferences.end();
    Serial.println("ID: " + ID);
  }

  void deletePreferences() {
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.clear();  // Remove all preferences under the opened namespace
    preferences.end();
  }

  void saveID() {
    // save to EEPROM or something like that ;-)
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.putString("id", ID);
    preferences.end();
    Serial.println("id set: " + ID);
  }

  //------------------------------------
  //last number in target IP adress where we send data
  void saveIdHostIP() {
    // save to EEPROM or something like that ;-)
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.putInt("idHostIP", idHostIP);
    preferences.end();
    Serial.println("idHostIP set: " + idHostIP);
  }

  void getIdHostIP() {
    uint16_t chip = getChipId();
    // check preferences if ID is already set by user
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    idHostIP = preferences.getInt("idHostIP", idHostIP);  // second param is default value if it fails to retrieve
    preferences.end();
    Serial.println("idHostIP: " + idHostIP);
  }
  //--------------------------------------------

  void setPort(uint16_t newportnum) {
    port = newportnum;
    // save to EEPROM or something like that ;-)
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    preferences.putInt("port", port);
    preferences.end();
    Serial.println("port set: " + port);
  }

  void getPort() {
    Preferences preferences;
    preferences.begin(ID_PREF_NAMESPACE, false);
    port = preferences.getInt("port", defaultPort);  // second param is default value if it fails to retrieve
    preferences.end();
    Serial.println("port: " + port);
  }

  void loadWifiSetup() {
    Preferences preferences;
    preferences.begin(WIFI_PREF_NAMESPACE, false);
    ssid = preferences.getString("ssid", ssid);  // second param is default value if it fails to retrieve
    pass = preferences.getString("pass", pass);  // second param is default value if it fails to retrieve
    preferences.end();
    Serial.println("ssid: " + ssid);
    Serial.println("pass: " + pass);
  }

  void saveWifiSetup() {
    Preferences preferences;
    preferences.begin(WIFI_PREF_NAMESPACE, false);
    preferences.putString("ssid", ssid);
    preferences.putString("pass", pass);
    preferences.end();
    Serial.println("saved ssid: " + ssid + " pass: " + pass);
  }

  void resetWifiSetup() {
    ssid = defaultssid;
    pass = defaultpass;
    saveWifiSetup();
  }

  void beginAP() {
    Serial.println("Starting AP on this module");
    //enableSTA(false));//disable station mode
    WiFi.mode(WIFI_AP);
    // Serial.print("Configuring the network interface = ");
    // bool softAPConfigStatus = WiFi.softAPConfig(local, gateway, netmask);
    // Serial.println(softAPConfigStatus ? "OK" : "ERROR");
    Serial.print("Configuring AP = ");
    bool softAPStatus = WiFi.softAP(ssid.c_str(), pass.c_str(), 11, 0, 4);  // bool softAP(const String& ssid,const String& psk = emptyString,int channel = 1,int ssid_hidden = 0,int max_connection = 4);
    WiFi.begin();
    // WiFi.softAP(ssid);
    Serial.println(softAPStatus ? "OK" : "ERROR");
    // složitější nastavení např.:
    //    struct softap_config conf;
    //    wifi_softap_get_config(&conf);
    //    conf.authmode = AUTH_WPA_WPA2_PSK;
    //    conf.max_connection = 255;
    //    wifi_softap_set_config(&conf);
    currentIP = WiFi.softAPIP();
    WiFi.setSleep(false);  //disable power saving => it's causing delay and latency on UDP traffic, espicially in AP mode
    Serial.println("AP started");
  }

  void beginClient() {
    StatusManager::wifiConnecting();
    Serial.println("Connecting to existing AP...");
    WiFi.mode(WIFI_STA);

    //turn off wifi power saving - it causes stutters in AP mode
    //With it on I was seeing latencies between 200 and 800ms to a UDP ping, with it turned off I get 10-25ms.
    //https://stackoverflow.com/questions/68803924/streaming-udp-packets-with-esp32-access-point-cause-massive-packet-loss
    //https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/network/esp_wifi.html#_CPPv415esp_wifi_set_ps14wifi_ps_type_t
    //esp_wifi_set_ps(WIFI_PS_NONE); //DOES NOT COMPILE :-( missing fce? old lib?

    WiFi.begin(ssid.c_str(), pass.c_str());

    unsigned long startTime = millis();
    Serial.println("Waiting ");
    while (WiFi.status() != WL_CONNECTED) {
      unsigned long now = millis();
      if (now - startTime >= 15000) {  // if connecting too long, try connecting again
        Serial.println("Trying again ");
        startTime = millis();
        WiFi.disconnect(true);  //Disable STA
        delay(500);
        smartConnect();  //jump to scan networks again - the AP might dissapeared at this point
        return;
        // WiFi.begin(ssid, pass);
      }
      delay(500);
      Serial.print(".");
    }

    currentIP = WiFi.localIP();
    WiFi.setSleep(false);  //disable power saving => it's causing delay and latency on UDP traffic, espicially in AP mode

    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.println("Client connected");
    StatusManager::setIdle();
  }

  void checkConnection() {
    int status = WiFi.status();
    if (status == WL_CONNECT_FAILED || status == WL_CONNECTION_LOST || status == WL_DISCONNECTED) {
      Serial.println("Connection lost...");
      // Serial.println("Reconnecting...");
      smartConnect();
    }
  }

  bool isConnected() {
    return WiFi.status() == WL_CONNECTED;
  }
};

#endif
