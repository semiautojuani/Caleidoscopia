#include <OSCMessage.h>
#include <SLIPEncodedSerial.h>

SLIPEncodedSerial SLIPSerial(Serial);

/* ----- THEREMIN 1 ----- */
const int TRIG = 27;
const int ECHO = 16;
const float DIST_MAX = 50.0;
float suavizado = -1;

/* ----- THEREMIN 2 ----- */
const int TRIG2 = 18;
const int ECHO2 = 19;
const float EFECTO_DIST_MIN = 5.0;
const float EFECTO_DIST_MAX = 30.0;
float efectoSuavizado = 0;

/* ----- GUITARRA ----- */
const int BTN1_PIN = 25;
const int BTN2_PIN = 26;
const int BTN3_PIN = 17;

/* ----- BOMBO ----- */
const int PIN_SENSOR_VIB = 14;
const int PIN_LED = 2;
unsigned long ultimoImpacto = 0;
const unsigned long TIEMPO_ANTIRREBOTE = 100;

volatile bool impactoDetectado = false;

void IRAM_ATTR detectarVibracion() {
  impactoDetectado = true;
}

float leerDistanciaCm(int trigPin, int echoPin, float distMax) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duracion = pulseIn(echoPin, HIGH, 6000);
  if (duracion == 0) return -1;
  float cm = duracion * 0.0343 / 2.0;
  return (cm > distMax) ? -1 : cm;
}

void enviarOSC(const char* direccion, float valor) {
  OSCMessage msg(direccion);
  msg.add(valor);
  SLIPSerial.beginPacket();
  msg.send(SLIPSerial);
  SLIPSerial.endPacket();
  msg.empty();
}

void setup() {
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  pinMode(TRIG2, OUTPUT);
  pinMode(ECHO2, INPUT);

  pinMode(BTN1_PIN, INPUT_PULLUP);
  pinMode(BTN2_PIN, INPUT_PULLUP);
  pinMode(BTN3_PIN, INPUT_PULLUP);

  pinMode(PIN_SENSOR_VIB, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_SENSOR_VIB), detectarVibracion, FALLING);

  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);

  SLIPSerial.begin(115200);
}

void loop() {
  /* ----------------------- THEREMIN: DISTANCIA ----------------------- */
  float d = leerDistanciaCm(TRIG, ECHO, DIST_MAX);

  if (d < 0) {
    suavizado = -1;
  } else if (suavizado < 0) {
    suavizado = d;
  } else {
    suavizado = 0.6 * suavizado + 0.4 * d;
  }

  enviarOSC("/theremin/distancia", suavizado);

  delay(10);

  /* ----------------------- THEREMIN: EFECTO ----------------------- */
  float d2 = leerDistanciaCm(TRIG2, ECHO2, EFECTO_DIST_MAX);

  if (d2 >= 0) {
    float efecto = (d2 - EFECTO_DIST_MIN) / (EFECTO_DIST_MAX - EFECTO_DIST_MIN);
    efecto = constrain(efecto, 0.0, 1.0);
    efectoSuavizado = 0.8 * efectoSuavizado + 0.2 * efecto;
  }

  enviarOSC("/theremin/efecto", efectoSuavizado);

  /* ----------------------- GUITARRA ----------------------- */
  enviarOSC("/botones/1", (digitalRead(BTN1_PIN) == LOW) ? 1.0 : 0.0);
  enviarOSC("/botones/2", (digitalRead(BTN2_PIN) == LOW) ? 1.0 : 0.0);
  enviarOSC("/botones/3", (digitalRead(BTN3_PIN) == LOW) ? 1.0 : 0.0);

  /* ----------------------- BOMBO ----------------------- */
  if (impactoDetectado) {
    if (millis() - ultimoImpacto > TIEMPO_ANTIRREBOTE) {
      ultimoImpacto = millis();
      enviarOSC("/vibracion", 1.0);
      digitalWrite(PIN_LED, HIGH);
    }
    impactoDetectado = false;
  }

  if (millis() - ultimoImpacto > TIEMPO_ANTIRREBOTE) {
    digitalWrite(PIN_LED, LOW);
  }

  delay(20);
}