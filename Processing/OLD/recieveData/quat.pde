/*
//some utility functions - might come in handy

//QUATERNION OPERATIONS
//norm of Quaternion is the dot product of itself
float normQuat(Quaternion q) {
  return q.dot(q);
}

Quaternion inverseQuat(Quaternion q) {
  float norm = normQuat(q);
  float invNorm = 1.0 / norm;
  return new Quaternion( q.w*invNorm, -q.x*invNorm, -q.y*invNorm, -q.z*invNorm );
}


Quaternion divideQuat(Quaternion q1, Quaternion q2) {
  // return a / b
  // we use the definition a * b^-1 (as opposed to b^-1 a)
  return q1.multiply( q2.getConjugate() );
}


Quaternion divideQuatScalar(Quaternion q, float s) {
  return new Quaternion ( q.w/s, q.x/s, q.y/s, q.z/s );
}

Quaternion quatDifference(Quaternion q1, Quaternion q2) {
  //inverse(q1) = conjugate(q1) / abs(q1)
  //Quaternion inversed = divideQuat( q1.getConjugate(), absQuat(q1)  );
  Quaternion inversed = q1.getConjugate(); //inverseQuat(q1);
  return inversed.multiply(q2);
}

//this should not work but it does - it somehow compress the 4D quat into 1D(signed) number representing orientation/direction
float quatDiff(Quaternion q1, Quaternion q2) {
  //inverse(q1) = conjugate(q1) / abs(q1)
  Quaternion inversed = q1.getConjugate(); //this should not work but someho works quite well
  //Quaternion inversed = inverseQuat(q1); //this should be the proper way
  //float diff= abs(inversed.dot(q2) ); //simplify by gettng rid of the sign?
  float diff= inversed.dot(q2);
  return diff;
}

//OPERATIONS WITH VECTORS------------------------------------------------------
public static PVector rotateVectorCC(PVector vec, PVector axis, double theta) {
  double x, y, z;
  double u, v, w;
  x=vec.x;
  y=vec.y;
  z=vec.z;
  u=axis.x;
  v=axis.y;
  w=axis.z;
  double xPrime = u*(u*x + v*y + w*z)*(1d - Math.cos(theta)) + x*Math.cos(theta)+ (-w*y + v*z)*Math.sin(theta);
  double yPrime = v*(u*x + v*y + w*z)*(1d - Math.cos(theta))+ y*Math.cos(theta)+ (w*x - u*z)*Math.sin(theta);
  double zPrime = w*(u*x + v*y + w*z)*(1d - Math.cos(theta))+ z*Math.cos(theta)+ (-v*x + u*y)*Math.sin(theta);
  return new PVector( (float)xPrime, (float)yPrime, (float)zPrime );
}


PVector quatToEuler(Quaternion qq) {
  // calculate Euler angles
  float[] q = {qq.x, qq.y, qq.z, qq.w};
  float x = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
  float y = -asin(2*q[1]*q[3] + 2*q[0]*q[2]);
  float z = atan2(2*q[2]*q[3] - 2*q[0]*q[1], 2*q[0]*q[0] + 2*q[3]*q[3] - 1);
  return new PVector(x, y, z);
}

Vec3D quatToEulerVec3D(Quaternion qq) {
  // calculate Euler angles
  float[] q = {qq.x, qq.y, qq.z, qq.w};
  float x = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
  float y = -asin(2*q[1]*q[3] + 2*q[0]*q[2]);
  float z = atan2(2*q[2]*q[3] - 2*q[0]*q[1], 2*q[0]*q[0] + 2*q[3]*q[3] - 1);
  return new Vec3D(x, y, z);
}

// calculate gravity vector
PVector quatToGravity(Quaternion qq) {
  float[] q = {qq.x, qq.y, qq.z, qq.w};
  float x = 2 * (q[1]*q[3] - q[0]*q[2]);
  float y = 2 * (q[0]*q[1] + q[2]*q[3]);
  float z = q[0]*q[0] - q[1]*q[1] - q[2]*q[2] + q[3]*q[3];
  return new PVector(x, y, z);
}

// calculate yaw/pitch/roll angles
PVector quatToYPR(Quaternion qq, PVector gravity) {
  float[] q = {qq.x, qq.y, qq.z, qq.w};
  float x = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
  float y = atan(gravity.x / sqrt(gravity.y*gravity.y + gravity.z*gravity.z));
  float z = atan(gravity.y / sqrt(gravity.x*gravity.x + gravity.z*gravity.z));
  return new PVector(x, y, z);
}

PVector quaternionToYawPitchRoll(Quaternion qq) {
  float [] q = {qq.x, qq.y, qq.z, qq.w};
  PVector ypr = new PVector(0, 0, 0);
  float Bank, Pitch, Azimuth; // estimated gravity direction
  //float Azimuth;
  Bank = 2 * (q[1]*q[3] - q[0]*q[2]);
  Pitch = 2 * (q[0]*q[1] + q[2]*q[3]);
  Azimuth = q[0]*q[0] - q[1]*q[1] - q[2]*q[2] + q[3]*q[3];

  ypr.x = atan2(2 * q[1] * q[2] - 2 * q[0] * q[3], 2 * q[0]*q[0] + 2 * q[1] * q[1] - 1);
  ypr.y = atan2(Pitch, sqrt(Bank*Bank + Azimuth*Azimuth));
  ypr.z = atan2(-Azimuth, Bank);

  // Fix the angle returned by atan2 (radians) to the range 0- TWO_PI
  // which is 0 - 360 degrees
  ypr.x = (ypr.x < 0) ? TWO_PI + ypr.x : ypr.x;
  ypr.y = (ypr.y < 0) ? TWO_PI + ypr.y : ypr.y;
  ypr.z = (ypr.z < 0) ? TWO_PI + ypr.z : ypr.z;

  //ypr.x = (ypr.x < 0) ? PI/2 + ypr.x : ypr.x;
  //ypr.y = (ypr.y < 0) ? PI/2 + ypr.y : ypr.y;
  //ypr.z = (ypr.z < 0) ? PI/2 + ypr.z : ypr.z;

  return ypr;
}
*/
