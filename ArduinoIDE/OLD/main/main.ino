#include <Arduino.h>
#include <Wire.h>

#define DEBUG 1

String ID = "0";                // id is set based on MAC later on
#define ID_PREF_NAMESPACE "ID"  // preferences namespace reserved for ID value (something like EEPROM)
String defaultMsgPrefix = "/motion";
String msgPrefix = defaultMsgPrefix;

#include "StatusManager.hpp"
#include "WifiManager.hpp"
#include "ImuManager.hpp"
#include "OscManager.hpp"

WifiManager wifiman;
ImuManager imuman;
OSCManager oscman(wifiman, imuman);

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  delay(1000);
#ifdef DEBUG
  Serial.print("Setup running on core ");
  Serial.println(xPortGetCoreID());
#endif
  wifiman.begin();
  imuman.begin();
  oscman.begin();
}

void loop() {

  if (imuman.isReady()) {
    imuman.getSample();
    imuman.proccesData();
  }
  if (wifiman.directConnection && imuman.hasNewData) {
    imuman.hasNewData = false;
    OSCBundle bundle;

    String quatMsgName = msgPrefix + "/" + ID + "/quat";

    OSCMessage quatMsg(quatMsgName.c_str());
    //replace with rotation with applied offset
    quatMsg.add(imuman.processedData.q.w);
    quatMsg.add(imuman.processedData.q.x);
    quatMsg.add(imuman.processedData.q.y);
    quatMsg.add(imuman.processedData.q.z);
    /*
    quatMsg.add(imuman.data.q.w);
    quatMsg.add(imuman.data.q.x);
    quatMsg.add(imuman.data.q.y);
    quatMsg.add(imuman.data.q.z);
    */
    bundle.add(quatMsg);

    String accMsgName = msgPrefix + "/" + ID + "/aaWorld";
    OSCMessage accMsg(accMsgName.c_str());
    accMsg.add(imuman.data.aaWorld.x);
    accMsg.add(imuman.data.aaWorld.y);
    accMsg.add(imuman.data.aaWorld.z);
    bundle.add(accMsg);

    // send aaWorld as separate values - good for some basic DAW-----
    String aaWXMsgNameX = msgPrefix + "/" + ID + "/aaWorld/x";
    OSCMessage aaWXMsgX(aaWXMsgNameX.c_str());
    aaWXMsgX.add(imuman.data.aaWorld.x);

    String aaWXMsgNameY = msgPrefix + "/" + ID + "/aaWorld/y";
    OSCMessage aaWXMsgY(aaWXMsgNameY.c_str());
    aaWXMsgY.add(imuman.data.aaWorld.y);

    String aaWXMsgNameZ = msgPrefix + "/" + ID + "/aaWorld/z";
    OSCMessage aaWXMsgZ(aaWXMsgNameZ.c_str());
    aaWXMsgZ.add(imuman.data.aaWorld.z);

    bundle.add(aaWXMsgX);
    bundle.add(aaWXMsgY);
    bundle.add(aaWXMsgZ);
    //-------------------------------------------------------------------
    // send aaReal
    String aaRealMsgName = msgPrefix + "/" + ID + "/aaReal";
    OSCMessage aaRealMsg(aaRealMsgName.c_str());
    aaRealMsg.add(imuman.data.aaReal.x);
    aaRealMsg.add(imuman.data.aaReal.y);
    aaRealMsg.add(imuman.data.aaReal.z);
    bundle.add(aaRealMsg);

    // send aa
    String aaMsgName = msgPrefix + "/" + ID + "/aa";
    OSCMessage aaMsg(aaMsgName.c_str());
    aaMsg.add(imuman.data.aa.x);
    aaMsg.add(imuman.data.aa.y);
    aaMsg.add(imuman.data.aa.z);
    bundle.add(aaMsg);

    // send ypr
    String yprMsgName = msgPrefix + "/" + ID + "/ypr";
    OSCMessage yprMsg(yprMsgName.c_str());
    /*
    yprMsg.add(imuman.data.ypr[0]);
    yprMsg.add(imuman.data.ypr[1]);
    yprMsg.add(imuman.data.ypr[2]);
    */
    //replace with rotation with applied offset
    yprMsg.add(imuman.processedData.ypr.x);
    yprMsg.add(imuman.processedData.ypr.y);
    yprMsg.add(imuman.processedData.ypr.z);
    bundle.add(yprMsg);

    // send raw accel+gyro data
    OSCMessage rawMsg((msgPrefix + "/" + ID + "/raw").c_str());
    // warning: time will wrap around after 2^31 microseconds = 36 minutes!!
    // TODO: fix this
    rawMsg.add((float)(imuman.data.time / 1000000.0));
    rawMsg.add((float)(imuman.data.aa.x / imuman.accelScale));
    rawMsg.add((float)(imuman.data.aa.y / imuman.accelScale));
    rawMsg.add((float)(imuman.data.aa.z / imuman.accelScale));
    rawMsg.add((float)(imuman.data.gyro.x / imuman.gyroScale));
    rawMsg.add((float)(imuman.data.gyro.y / imuman.gyroScale));
    rawMsg.add((float)(imuman.data.gyro.z / imuman.gyroScale));
    bundle.add(rawMsg);

    // send YPR as separate values - good for some basic DAW-----
    String yMsgName = msgPrefix + "/" + ID + "/ypr/y";
    OSCMessage yRawMsg(yMsgName.c_str());
    yRawMsg.add(imuman.processedData.ypr.x);
    String pMsgName = msgPrefix + "/" + ID + "/ypr/p";
    OSCMessage pRawMsg(pMsgName.c_str());
    pRawMsg.add(imuman.processedData.ypr.y);
    String rMsgName = msgPrefix + "/" + ID + "/ypr/r";
    OSCMessage rRawMsg(rMsgName.c_str());
    rRawMsg.add(imuman.processedData.ypr.z);
    bundle.add(yRawMsg);
    bundle.add(pRawMsg);
    bundle.add(rRawMsg);
    //---------------------------------------------------------------

    if (imuman.processedData.state == BallState::THROW) {
      String throwMsg = msgPrefix + "/" + ID + "/throw";
      OSCMessage stateMsg(throwMsg.c_str());
      stateMsg.add(true);
      bundle.add(stateMsg);
    } else if (imuman.processedData.state == BallState::CATCH) {
      String catchMsg = msgPrefix + "/" + ID + "/catch";
      OSCMessage stateCatchMsg(catchMsg.c_str());
      stateCatchMsg.add(imuman.processedData.airTime);
      bundle.add(stateCatchMsg);
      /*
      String airtimeAddress = msgPrefix + "/" + ID + "/airtime";
      OSCMessage stateMsg(airtimeAddress.c_str());
      stateMsg.add(imuman.processedData.airTime);
      bundle.add(stateMsg);
      */
    }

    oscman.sendOSC(bundle);
  }
  oscman.receiveOSC();
}
