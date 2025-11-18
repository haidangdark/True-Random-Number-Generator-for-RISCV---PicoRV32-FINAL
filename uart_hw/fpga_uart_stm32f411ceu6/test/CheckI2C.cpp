#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>

#define WIRE Wire

#define TXD_1 (PA9)
#define RXD_1 (PA10)
#define SDA_1 (PB7)
#define SCL_1 (PB6)

//HardwareSerial Serial(RXD_1, TXD_1);

void setup() {
  // USB CDC Serial (cần cấu hình build_flags trong platformio.ini)
  Serial.begin(115200);
  while (!Serial) { delay(10); }   // chờ PC nhận COM
  Serial.println("\nI2C Scanner (USB CDC)");

  // I2C
  Wire.setSDA(SDA_1);
  Wire.setSCL(SCL_1);
  Wire.begin();
  Wire.setClock(100000);           // nên bắt đầu 100 kHz để ổn định
  delay(10);
}


void loop() {
  byte error, address;
  int nDevices;

  Serial.println("Scanning...");

  nDevices = 0;
  for(address = 1; address < 127; address++ )
  {
    // The i2c_scanner uses the return value of
    // the Write.endTransmisstion to see if
    // a device did acknowledge to the address.
    WIRE.beginTransmission(address);
    error = WIRE.endTransmission();

    if (error == 0)
    {
      Serial.print("I2C device found at address 0x");
      if (address<16) Serial.print("0");
      Serial.print(address,HEX);
      Serial.println("  !");

      nDevices++;
    }
    else if (error==4)
    {
      Serial.print("Unknown error at address 0x");
      if (address<16) Serial.print("0");
      Serial.println(address,HEX);
    }
  }
  if (nDevices == 0) Serial.println("No I2C devices found\n");
  else Serial.println("done\n");

  delay(5000);           // wait 5 seconds for next scan
}