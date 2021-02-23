#include <Wire.h>

#define F_CPU 800000UL  // Define the microcontroller clock speed (16 MHz)

volatile bool BLUETOOTH_INTERRUPT_FLAG;


//int rx = 2;  // software serial RX pin
//int tx = 3;  // software serial TX pin
//SoftwareSerial Bluetooth(rx, tx);       // create bluetooth object



const int MPU_addr = 0x68;
int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ;

int minVal = 265;
int maxVal = 402;

long xoutput, youtput, zoutput = 0;


double x;
double y;
double z;

void setup() {

  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);


  Serial.begin(38400);
  
  /*Bluetooth.begin(38400);  // Begin the bluetooth serial and set data rate

  Bluetooth.println("Bluetooth connected");
*/
  //attachInterrupt(0,bluetoothISR,  RISING); // setup interrupt for INT0 (UNO pin 2) //TODO: Change this to real interrupt

}
void loop() {

  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true);

  AcX = Wire.read() << 8 | Wire.read();
  AcY = Wire.read() << 8 | Wire.read();
  AcZ = Wire.read() << 8 | Wire.read();

  xoutput = long(0.9896 * (float)xoutput + 0.01042 * (float)AcX);
  youtput = long(0.9896 * (float)youtput + 0.01042 * (float)AcY);
  zoutput = long(0.9896 * (float)zoutput + 0.01042 * (float)AcZ);


  int xAng = map(xoutput, minVal, maxVal, -90, 90);
  int yAng = map(youtput, minVal, maxVal, -90, 90);
  int zAng = map(zoutput, minVal, maxVal, -90, 90);

  x = RAD_TO_DEG * (atan2(-yAng, -zAng) + PI);
  y = RAD_TO_DEG * (atan2(-xAng, -zAng) + PI);
  z = RAD_TO_DEG * (atan2(-yAng, -xAng) + PI);

  /*
    Serial.print("AngleX= ");
    Serial.print(x);

    Serial.print(" | AngleY= ");
    Serial.print(y);

    Serial.print(" | AngleZ= ");
    Serial.println(z);
    //Serial.println("-----------------------------------------");
    //delay(400);
  */

  int xangle = x;
  byte xangleDecimal = (byte) ((x - (double)xangle) * 100);
  int yangle = y;
  byte yangleDecimal = (byte) ((y - (double)yangle) * 100);

  byte xAngleHigh = (byte) ((xangle & 0xFF00) >> 8) ;
  byte xAngleLow = (byte) (xangle & 0x00FF);

  byte yAngleHigh = (byte) ((yangle & 0xFF00) >> 8) ;
  byte yAngleLow = (byte) (yangle & 0x00FF);

  byte checksum = xAngleHigh ^ xAngleLow ^ xangleDecimal ^ yAngleHigh ^ yAngleLow ^ yangleDecimal;

/*
  Bluetooth.write(xAngleHigh);
  Bluetooth.write(xAngleLow);
  Bluetooth.write(xangleDecimal);

  Bluetooth.write(yAngleHigh);
  Bluetooth.write(yAngleLow);
  Bluetooth.write(yangleDecimal);

  Bluetooth.write(checksum);
  */

  Serial.write(xAngleHigh);
  Serial.write(xAngleLow);
  Serial.write(xangleDecimal);

  Serial.write(yAngleHigh);
  Serial.write(yAngleLow);
  Serial.write(yangleDecimal);

  Serial.write(checksum);

  delay(50);

}


int combine(byte b1, byte b2)
{
  int combined = b1 << 8 | b2;
  return combined;
}
