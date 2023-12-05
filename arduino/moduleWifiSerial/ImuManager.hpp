#ifndef IMUMANAGER_HPP
#define IMUMANAGER_HPP

#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps_V6_12.h"
#include <Preferences.h>

struct ImuData {
  long time;
  Quaternion q;
  VectorInt16 aa;
  VectorInt16 aaReal;
  VectorInt16 aaWorld;
  VectorFloat gravity;
  VectorInt16 gyro;
  float ypr[3];
};

enum BallState {
  IDLE,
  THROW,
  PEAK,
  CATCH
};

struct ProcessedData {
  Quaternion q;
  float angle;
  VectorFloat ypr;
  BallState state;
  double magnitude;
  int airTime;
};

#define SDA_PIN 40
#define SCL_PIN 38
#define IMU_PREF_NAMESPACE "IMU"
#define DEFAULT_THROWACCEL_THRESHOLD 4700

volatile bool mpuInterrupt = false;
void dmpDataReady() {
  mpuInterrupt = true;
}

class ImuManager {
public:
  ImuManager(StatusManager &statusman)
    : statusman(statusman){};

private:
  StatusManager &statusman;

  MPU6050 mpu;
  uint8_t fifoBuffer[64];

  bool freeFall = false;
  bool inAir = false;
  long int throwTime = 0;

  const int INTERRUPT_PIN = 6;

  volatile bool dmpReady = false;
  uint8_t mpuIntStatus;  // holds actual interrupt status byte from MPU
  int devStatus = -1;
  uint16_t packetSize;  // expected DMP packet size (default is 42 bytes)

  Quaternion worldQuat = Quaternion(1, 0, 0, 0);
  Quaternion zeroQuat = Quaternion(1, 0, 0, 0);

  void handleThrowUp() {
    if (!inAir) {
      //Serial.println("Throw event detected!");
      statusman.throwDetected();
      //StatusManager::throwDetected();
      processedData.state = BallState::THROW;
      throwTime = millis();
    }
  }
  void handleCatch() {
    //statusman.setIdle();
    //StatusManager::setIdle();
    ////Serial.println("Catch event detected!");
    processedData.state = BallState::CATCH;
    processedData.airTime = millis() - throwTime;
  }

  void setOffsets(int16_t *accel, int16_t *gyro) {
    mpu.setXGyroOffset(gyro[0]);
    mpu.setYGyroOffset(gyro[1]);
    mpu.setZGyroOffset(gyro[2]);
    mpu.setXAccelOffset(accel[0]);
    mpu.setYAccelOffset(accel[1]);
    mpu.setZAccelOffset(accel[2]);
  }
  // I need function quaternionToYawPitchRoll that will return yaw, pitch and roll in degrees
  VectorFloat quaternionToYawPitchRoll(Quaternion qq) {
    float q[] = { qq.x, qq.y, qq.z, qq.w };
    VectorFloat ypr = { 0, 0, 0 };
    float Bank, Pitch, Azimuth;  // estimated gravity direction
    Bank = 2 * (q[1] * q[3] - q[0] * q[2]);
    Pitch = 2 * (q[0] * q[1] + q[2] * q[3]);
    Azimuth = q[0] * q[0] - q[1] * q[1] - q[2] * q[2] + q[3] * q[3];

    ypr.x = atan2(2 * q[1] * q[2] - 2 * q[0] * q[3], 2 * q[0] * q[0] + 2 * q[1] * q[1] - 1);
    ypr.y = atan2(Pitch, sqrt(Bank * Bank + Azimuth * Azimuth));
    ypr.z = atan2(-Azimuth, Bank);

    // Fix the angle returned by atan2 (radians) to the range 0- TWO_PI
    // which is 0 - 360 degrees
    ypr.x = (ypr.x < 0) ? TWO_PI + ypr.x : ypr.x;
    ypr.y = (ypr.y < 0) ? TWO_PI + ypr.y : ypr.y;
    ypr.z = (ypr.z < 0) ? TWO_PI + ypr.z : ypr.z;

    // Convert radians to degrees
    ypr.x = ypr.x * 180.0 / M_PI;
    ypr.y = ypr.y * 180.0 / M_PI;
    ypr.z = ypr.z * 180.0 / M_PI;

    return ypr;
  }

public:
  volatile bool mpuInterrupt = false;  // indicates whether MPU interrupt pin has gone high
  double throwThreshold;
  ImuData data;
  float gyroScale;
  float accelScale;
  ProcessedData processedData;
  bool hasNewData = false;

  void begin() {
    mpu.initialize();
    pinMode(INTERRUPT_PIN, INPUT);

    Serial.println(F("Testing device connections"));
    Serial.println(mpu.testConnection() ? F("MPU6050 connection successful") : F("MPU6050 connection failed"));

    int mpuConnectAttempts = 0;
    while (!mpu.testConnection()) {
      
      if (mpuConnectAttempts > 5) {  //try then give up
        ESP.restart();
      }
      Serial.print(".");
      mpu.initialize();
      delay(500);
      mpuConnectAttempts++;
    }

    devStatus = mpu.dmpInitialize();

    if (devStatus == 0) {
      calibrate();
      Serial.println(F("Enabling DMP..."));
      mpu.setDMPEnabled(true);

      // see page 13 in https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Register-Map1.pdf
      mpu.setDLPFMode(1);  // low-pass filter, 0 = off, 7 = max

      // enable Arduino interrupt detection
      //Serial.print(F("Enabling interrupt detection (Arduino external interrupt "));
      //Serial.print(digitalPinToInterrupt(INTERRUPT_PIN));
      ////Serial.println(F(")..."));
      attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), dmpDataReady, RISING);
      mpuIntStatus = mpu.getIntStatus();
      // set our DMP Ready flag so the main loop() function knows it's okay to use it
      ////Serial.println(F("DMP ready! Waiting for first interrupt..."));
      dmpReady = true;
      // get expected DMP packet size for later comparison
      packetSize = mpu.dmpGetFIFOPacketSize();
    } else {
      // ERROR!
      // 1 = initial memory load failed
      // 2 = DMP configuration updates failed
      // (if it's going to break, usually the code will be 1)
      Serial.print(F("DMP Initialization failed (code "));
      Serial.print(devStatus);
      Serial.println(F(")"));
    }
    // check preferences for threshold and load
    Preferences preferences;
    preferences.begin(IMU_PREF_NAMESPACE, false);
    if (!preferences.isKey("throwThreshold")) {
      preferences.putDouble("throwThreshold", DEFAULT_THROWACCEL_THRESHOLD);
    }
    throwThreshold = preferences.getDouble("throwThreshold", DEFAULT_THROWACCEL_THRESHOLD);
    preferences.end();

    Serial.print("Throw threshold: ");
    Serial.println(throwThreshold);

    // see https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Register-Map1.pdf
    // page 29 and 31
    accelScale = 2048.0 * pow(2, 3 - mpu.getFullScaleAccelRange());
    gyroScale = 16.4 * pow(2, 3 - mpu.getFullScaleGyroRange());
  }

  void calibrate(bool force = false) {
    Serial.println("Calibrating IMU");

    Preferences preferences;
    preferences.begin(IMU_PREF_NAMESPACE, false);
    dmpReady = false;
    mpu.setDMPEnabled(false);

    //Serial.print("Accel offsets length: ");
    //Serial.println(preferences.getBytesLength("accelOffsets"));
    //Serial.print("Gyro offsets length: ");
    //Serial.println(preferences.getBytesLength("gyroOffsets"));

    if ((preferences.getBytesLength("accelOffsets") == 0 && preferences.getBytesLength("gyroOffsets") == 0) || force) {

      Serial.println("No offsets found, calibrating");

      mpu.CalibrateAccel(7);
      mpu.CalibrateGyro(7);
      int16_t aceelOffsets[3] = { mpu.getXAccelOffset(), mpu.getYAccelOffset(), mpu.getZAccelOffset() };
      int16_t gyroOffsets[3] = { mpu.getXGyroOffset(), mpu.getYGyroOffset(), mpu.getZGyroOffset() };
      preferences.putBytes("accelOffsets", (uint8_t *)aceelOffsets, sizeof(aceelOffsets));
      preferences.putBytes("gyroOffsets", (uint8_t *)gyroOffsets, sizeof(gyroOffsets));
      setOffsets(aceelOffsets, gyroOffsets);
    } else {
      Serial.println("Found offsets, setting");

      int16_t aceelOffsets[3];
      int16_t gyroOffsets[3];
      preferences.getBytes("accelOffsets", (uint8_t *)aceelOffsets, sizeof(aceelOffsets));
      preferences.getBytes("gyroOffsets", (uint8_t *)gyroOffsets, sizeof(gyroOffsets));
      setOffsets(aceelOffsets, gyroOffsets);
    }
    preferences.end();

    Serial.println("Calibration done");

    mpu.setDMPEnabled(true);
    dmpReady = true;
  }

  void zeroPosition() {
    // quatDifference(rot, worldUnit);
    // Quaternion quatDifference(Quaternion q1, Quaternion q2) {
    //   //inverse(q1) = conjugate(q1) / abs(q1)
    //   //Quaternion inversed = divideQuat( q1.getConjugate(), absQuat(q1)  );
    //   Quaternion inversed = q1.getConjugate(); //inverseQuat(q1);
    //   return inversed.multiply(q2);
    // }
    Quaternion inversed = data.q.getConjugate();
    zeroQuat = inversed.getProduct(worldQuat);
  }
  void getZeroPosition() {
    //Serial.print("Zero position: ");
    //Serial.print(zeroQuat.w);
    //Serial.print(" ");
    //Serial.print(zeroQuat.x);
    //Serial.print(" ");
    //Serial.print(zeroQuat.y);
    //Serial.print(" ");
    ////Serial.println(zeroQuat.z);
  }

  void getLinearAccel(VectorInt16 *v, VectorInt16 *vRaw, VectorFloat *gravity) {
    // the gravity direction is in gravity vector
    // the gravity magnitude in raw LSB units is accelScale
    // therefore we subtract gravity*accelScale from the raw acceleration vector
    float gravitySize = accelScale;
    v->x = vRaw->x - gravity->x * gravitySize;
    v->y = vRaw->y - gravity->y * gravitySize;
    v->z = vRaw->z - gravity->z * gravitySize;
  }

  void deletePreferences() {
    Preferences preferences;
    preferences.begin(IMU_PREF_NAMESPACE, false);
    preferences.clear();  // Remove all preferences under the opened namespace - this will also delete calibration!
    preferences.end();
  }


  ImuData getSample() {
    if (!dmpReady) {
      data = {};
      return data;
    }
    // read a packet from FIFO
    if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) {
      long time = micros();
      data.time = time;
      // Also read raw accelgyro values
      int16_t ax, ay, az;
      int16_t gx, gy, gz;
      mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
      // interestingly, ax,ay,az != data.aa.x,aa.y,aa.z
      // presumably, the values from FIFO buffer are measured in
      // a different moment or postprocessed somehow

      data.gyro.x = gx;
      data.gyro.y = gy;
      data.gyro.z = gz;

      mpu.dmpGetQuaternion(&data.q, fifoBuffer);
      mpu.dmpGetAccel(&data.aa, fifoBuffer);
      mpu.dmpGetGravity(&data.gravity, &data.q);

      // Replace with getLinearAccel, the library seems to have a bug
      // mpu.dmpGetLinearAccel(&data.aaReal, &data.aa, &data.gravity);
      getLinearAccel(&data.aaReal, &data.aa, &data.gravity);
      mpu.dmpGetLinearAccelInWorld(&data.aaWorld, &data.aaReal, &data.q);
      mpu.dmpGetYawPitchRoll(data.ypr, &data.q, &data.gravity);

      hasNewData = true;
    }
    return data;
  }

  bool isReady() {
    return dmpReady;
  }

  void setThrowThreshold(double threshold) {
    throwThreshold = threshold;
    Preferences preferences;
    preferences.begin(IMU_PREF_NAMESPACE, false);
    preferences.putDouble("throwThreshold", throwThreshold);
    preferences.end();
  }

  double getThrowThreshold() {
    return throwThreshold;
  }

  void proccesData() {
    processedData.q = data.q.getProduct(zeroQuat);
    processedData.ypr = quaternionToYawPitchRoll(processedData.q);

    double aMag = data.aa.getMagnitude();
    if (processedData.state == BallState::CATCH || processedData.state == BallState::THROW) {
      processedData.state = BallState::IDLE;
    }
    if (aMag < throwThreshold) {
      handleThrowUp();
      inAir = true;
    } else {
      if (inAir) {
        handleCatch();
      }
      inAir = false;
    }
  }
};

#endif
