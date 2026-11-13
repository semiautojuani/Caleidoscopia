import processing.serial.*;
import processing.sound.*;
import java.nio.ByteBuffer;

SoundFile muestra;
LowPass filtro;

Serial puerto;

float efecto = 0;
float VOLUMEN = 0.25;

// Decodificación SLIP
final int END = 0xC0, ESC = 0xDB, ESC_END = 0xDC, ESC_ESC = 0xDD;
byte[] buf = new byte[128];
int len = 0;
boolean escapado = false;

float distancia = -1;
float freqActual = 200;
float ampActual = 0;

float velocidadActual = 1;
float tMano = 0;

float DIST_MIN = 5;
float DIST_MAX = 50;
float FREQ_MIN = 200;
float FREQ_MAX = 1000;

void setup() {
  size(600, 300);
  puerto = new Serial(this, "COM5", 115200);
  
 muestra = new SoundFile(this, "fanwei.mp3");
  filtro = new LowPass(this);
  filtro.process(muestra, 8000);
  muestra.loop();
  muestra.amp(0);


}

void draw() {
  background(20);

  float ampObjetivo;

  if (distancia < 0) {
    ampObjetivo = 0;
  } else {
    float d = constrain(distancia, DIST_MIN, DIST_MAX);
    float t = map(d, DIST_MIN, DIST_MAX, 1, 0);
    tMano = lerp(tMano, t, 0.2);
    ampObjetivo = VOLUMEN;
  }

  ampActual = lerp(ampActual, ampObjetivo, 0.15);
  muestra.amp(ampActual);

  float velocidadObjetivo = 0.5 * pow(4, efecto);
  velocidadActual = lerp(velocidadActual, velocidadObjetivo, 0.2);
  muestra.rate(velocidadActual);

  float corte = 300 * pow(8000.0 / 300.0, tMano);
  filtro.freq(corte);

  fill(255);
  text("Distancia: " + nf(distancia, 0, 1) + " cm", 20, 40);
  text("Velocidad: " + nf(velocidadActual, 0, 2) + "x", 20, 70);
  text("Filtro: " + nf(corte, 0, 0) + " Hz", 20, 100);
}

void serialEvent(Serial p) {
  while (p.available() > 0) {
    int b = p.read();
    if (b == END) {
      if (len > 0) procesarOSC(buf, len);
      len = 0;
      escapado = false;
    } else if (b == ESC) {
      escapado = true;
    } else {
      if (escapado) {
        if (b == ESC_END) b = END;
        else if (b == ESC_ESC) b = ESC;
        escapado = false;
      }
      if (len < buf.length) buf[len++] = (byte) b;
    }
  }
}

void procesarOSC(byte[] data, int n) {
  int i = 0;
  while (i < n && data[i] != 0) i++;
  String direccion = new String(data, 0, i);
  i = (i + 4) & ~3;

  if (i >= n || data[i] != ',') return;
  int j = i;
  while (j < n && data[j] != 0) j++;
  j = (j + 4) & ~3;

  if (j + 4 > n) return;
  float valor = ByteBuffer.wrap(data, j, 4).getFloat();

  if (direccion.equals("/theremin/distancia")) {
    distancia = valor;
  } else if (direccion.equals("/theremin/efecto")) {
    efecto = constrain(valor, 0, 1);
  }
}
