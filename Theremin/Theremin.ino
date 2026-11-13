#include <dummy.h>

#include <OSCMessage.h>
#include <SLIPEncodedSerial.h>

SLIPEncodedSerial SLIPSerial(Serial);

const int TRIG = 5;
const int ECHO = 18;

const float DIST_MAX = 50.0;
float suavizado = -1;

const int POT = 34;
float potSuavizado = 0;

float leerDistanciaCm() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);

  long duracion = pulseIn(ECHO, HIGH, 30000); 
  if (duracion == 0) return -1;
  float cm = duracion * 0.0343 / 2.0;
  return (cm > DIST_MAX) ? -1 : cm;
}

void setup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  SLIPSerial.begin(115200);
}

void loop() {
  float d = leerDistanciaCm();

  if (d < 0) {
    suavizado = -1;
  } else if (suavizado < 0) {
    suavizado = d;
  } else {
    suavizado = 0.6 * suavizado + 0.4 * d;
  }

  OSCMessage msg("/theremin/distancia");
  msg.add(suavizado);

  SLIPSerial.beginPacket();
  msg.send(SLIPSerial);
  SLIPSerial.endPacket();
  msg.empty();

  float pot = analogRead(POT) / 4095.0;
  potSuavizado = 0.8 * potSuavizado + 0.2 * pot; 

  OSCMessage msgPot("/theremin/efecto");
  msgPot.add(potSuavizado);

  SLIPSerial.beginPacket();
  msgPot.send(SLIPSerial);
  SLIPSerial.endPacket();
  msgPot.empty();

  delay(30);
}
