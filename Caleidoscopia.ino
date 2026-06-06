#include <Adafruit_NeoPixel.h>

const int PIN_NEOPIXEL = 6;
const int PIN_MOTOR_IN1 = 9;
const int PIN_MOTOR_IN2 = 10;

const int NUM_LEDS = 24;

Adafruit_NeoPixel leds(NUM_LEDS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800);

int cantidadPersonas = 0;

float brilloActual = 20;
float brilloObjetivo = 20;

float velocidadMotorActual = 50;
float velocidadMotorObjetivo = 50;

float suavizado = 0.08;


void setup(){
  Serial.begin(115200);

  pinMode(PIN_MOTOR_IN1, OUTPUT);
  pinMode(PIN_MOTOR_IN2, OUTPUT);

  leds.begin();
  leds.show();
}

void loop(){
  leerSensores();

  actualizarEstados();

  controlarMotor();

  controlarLuces();

  delay(30);
}

void leerSensores(){

  cantidadPersonas = (sin(millis() / 4000.0) + 1)*2;
  Serial.print("Personas detectadas: ");
  Serial.println(cantidadPersonas);
}

void actualizarEstados(){
  brilloObjetivo = map(cantidadPersonas, 0, 4, 20, 255);

  velocidadMotorObjetivo = map(cantidadPersonas, 0, 4, 50, 255);
}


void controlarMotor(){
  velocidadMotorActual += (velocidadMotorObjetivo - velocidadMotorActual)*suavizado;

  analogWrite(PIN_MOTOR_IN1, velocidadMotorActual);

  digitalWrite(PIN_MOTOR_IN2, LOW);
}


void controlarLuces(){
  brilloActual += (brilloObjetivo - brilloActual)*suavizado;

  for(int i=0; i<NUM_LEDS; i++){
    leds.setPixelColor(i, leds.Color((255 * brilloActual) / 255, (197 * brilloActual) / 255, (110 * brilloActual) / 255));
  }

  leds.show();
}