import processing.serial.*;
import processing.sound.*;
import java.nio.ByteBuffer;

/* ------- THEREMIN ------- */
SoundFile muestra;
LowPass filtro;

float distancia = -1;
float efecto = 0;
float VOLUMEN = 0.25;

float ampActual = 0;
float velocidadActual = 1;
float tMano = 0;

float DIST_MIN = 5;
float DIST_MAX = 50;

/* ------- GUITARRA ------- */
SoundFile sonidoBtn1;
SoundFile sonidoBtn2;
SoundFile sonidoBtn3;

// true  = el sonido se mantiene mientras se aprieta el botón (loop)
// false = el sonido se dispara una vez al presionar
boolean MODO_SOSTENIDO = true;

float estadoBtn1 = 0;
float estadoBtn2 = 0;
float estadoBtn3 = 0;

float prevBtn1 = 0;
float prevBtn2 = 0;
float prevBtn3 = 0;

float ampBtn1Actual = 0;
float ampBtn2Actual = 0;
float ampBtn3Actual = 0;

float VOL_BTN1 = 0.5;
float VOL_BTN2 = 0.5;
float VOL_BTN3 = 0.5;

float serialBtn1 = 0, serialBtn2 = 0, serialBtn3 = 0;
float tecladoBtn1 = 0, tecladoBtn2 = 0, tecladoBtn3 = 0;
boolean kPresionada = false;

/* ------- BOMBO ------- */
SoundFile[] kicks = new SoundFile[3];
int ultimoKick = -1;

SoundFile sonidoBomboFondo;
volatile boolean golpeBombo = false;
int timerFeedbackVib = 0;
float volumenBombo = 1.0;

float VOL_FONDO = 0.5;
float ampFondoActual = 0;
int VENTANA_FONDO_MS = 15000;
int ultimoGolpeBombo = -VENTANA_FONDO_MS;

/* ------- FONDO PERMANENTE ------- */
SoundFile fondoPermanente;
float VOL_FONDO_PERM = 0.3;   // VOLUMEN!! (0.0 a 1.0)

// --- DECODIFICACIÓN SLIP ---
Serial puerto;
final int END = 0xC0, ESC = 0xDB, ESC_END = 0xDC, ESC_ESC = 0xDD;
byte[] buf = new byte[128];
int len = 0;
boolean escapado = false;

void setup() {
  size(900, 400);

  println(Serial.list());
  try {
    puerto = new Serial(this, "COM7", 115200);
  }
  catch (Exception e) {
    println("Error al abrir el puerto COM. Verifica que el Monitor Serie de Arduino este cerrado.");
  }

  /* ------- FONDO PERMANENTE ------- */
  fondoPermanente = new SoundFile(this, "audio0.mp3");
  fondoPermanente.loop();
  fondoPermanente.amp(VOL_FONDO_PERM);

  /* ------- THEREMIN ------- */
  muestra = new SoundFile(this, "fanwei.mp3");
  filtro = new LowPass(this);
  filtro.process(muestra, 8000);
  muestra.loop();
  muestra.amp(0);

  /* ------- GUITARRA ------- */
  sonidoBtn1 = new SoundFile(this, "NotaGuitarra1.wav");
  sonidoBtn2 = new SoundFile(this, "NotaGuitarra2.wav");
  sonidoBtn3 = new SoundFile(this, "NotaGuitarra3.wav");

  /* ------- BOMBO ------- */
  
  String[] archivosKick = { "kick1.wav", "kick2.wav", "kick3.wav" };
  for (int i = 0; i < kicks.length; i++) {
    kicks[i] = new SoundFile(this, archivosKick[i]);
    kicks[i].amp(volumenBombo);
  }

  sonidoBomboFondo = new SoundFile(this, "percusionFinal.wav");
  sonidoBomboFondo.amp(0);
}

void draw() {
  background(25);
  
  fondoPermanente.amp(VOL_FONDO_PERM);

  /* ------- THEREMIN ------- */
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

  /* ------- GUITARRA ------- */
  estadoBtn1 = max(serialBtn1, tecladoBtn1);
  estadoBtn2 = max(serialBtn2, tecladoBtn2);
  estadoBtn3 = max(serialBtn3, tecladoBtn3);


  if (MODO_SOSTENIDO) {
    ampBtn1Actual = actualizarCuerda(sonidoBtn1, estadoBtn1, prevBtn1, VOL_BTN1, ampBtn1Actual);
    ampBtn2Actual = actualizarCuerda(sonidoBtn2, estadoBtn2, prevBtn2, VOL_BTN2, ampBtn2Actual);
    ampBtn3Actual = actualizarCuerda(sonidoBtn3, estadoBtn3, prevBtn3, VOL_BTN3, ampBtn3Actual);
  } else {
    if (estadoBtn1 > 0.5 && prevBtn1 <= 0.5) {
      sonidoBtn1.stop();
      sonidoBtn1.amp(VOL_BTN1);
      sonidoBtn1.play();
    }
    if (estadoBtn2 > 0.5 && prevBtn2 <= 0.5) {
      sonidoBtn2.stop();
      sonidoBtn2.amp(VOL_BTN2);
      sonidoBtn2.play();
    }
    if (estadoBtn3 > 0.5 && prevBtn3 <= 0.5) {
      sonidoBtn3.stop();
      sonidoBtn3.amp(VOL_BTN3);
      sonidoBtn3.play();
    }
  }
  prevBtn1 = estadoBtn1;
  prevBtn2 = estadoBtn2;
  prevBtn3 = estadoBtn3;

  /* ------- BOMBO ------- */
  if (golpeBombo) {
    golpeBombo = false;
    ultimoGolpeBombo = millis();

    int elegido = int(random(kicks.length));
    while (elegido == ultimoKick) {
      elegido = int(random(kicks.length));
    }
    ultimoKick = elegido;

    kicks[elegido].stop();
    kicks[elegido].amp(volumenBombo);
    kicks[elegido].play();
  }

  boolean fondoActivo = (millis() - ultimoGolpeBombo) < VENTANA_FONDO_MS;

  if (fondoActivo && !sonidoBomboFondo.isPlaying()) {
    sonidoBomboFondo.amp(0);
    sonidoBomboFondo.loop();
    ampFondoActual = 0;
  }

  ampFondoActual = lerp(ampFondoActual, fondoActivo ? VOL_FONDO : 0, 0.1);

  if (sonidoBomboFondo.isPlaying()) {
    sonidoBomboFondo.amp(ampFondoActual);
    if (!fondoActivo && ampFondoActual < 0.01) sonidoBomboFondo.stop();
  }

  float segRestantes = fondoActivo
    ? (VENTANA_FONDO_MS - (millis() - ultimoGolpeBombo)) / 1000.0
    : 0;

  /* ------- INTERFAZ ------- */
  stroke(100);
  fill(35);
  rect(20, 20, 260, 350, 10);

  fill(0, 200, 255);
  textSize(16);
  text("1. THEREMIN", 35, 50);
  textSize(13);
  fill(220);
  text("Distancia: " + (distancia < 0 ? "Sin mano" : nf(distancia, 0, 1) + " cm"), 35, 90);
  text("Velocidad: " + nf(velocidadActual, 0, 2) + "x", 35, 120);
  text("Filtro: " + nf(corte, 0, 0) + " Hz", 35, 150);

  text("Efecto: " + nf(efecto, 0, 2), 35, 180);
  noFill();
  stroke(100);
  rect(35, 190, 220, 14, 4);
  noStroke();
  fill(0, 200, 255);
  rect(35, 190, 220 * efecto, 14, 4);
  stroke(100);

  fill(35);
  rect(300, 20, 380, 350, 10);

  fill(255, 150, 0);
  textSize(16);
  text("2. TECLAS DE LUZ", 315, 50);
  textSize(13);

  fill(estadoBtn1 > 0.5 ? color(0, 255, 100) : color(60));
  rect(315, 90, 105, 80, 8);
  fill(255);
  text("TECLA 1", 340, 125);
  textSize(11);
  text((estadoBtn1 > 0.5) ? "[ ON ]" : "[ OFF ]", 345, 145);
  textSize(13);

  fill(estadoBtn2 > 0.5 ? color(0, 255, 100) : color(60));
  rect(435, 90, 105, 80, 8);
  fill(255);
  text("TECLA 2", 460, 125);
  textSize(11);
  text((estadoBtn2 > 0.5) ? "[ ON ]" : "[ OFF ]", 465, 145);
  textSize(13);

  fill(estadoBtn3 > 0.5 ? color(0, 255, 100) : color(60));
  rect(555, 90, 105, 80, 8);
  fill(255);
  text("TECLA 3", 580, 125);
  textSize(11);
  text((estadoBtn3 > 0.5) ? "[ ON ]" : "[ OFF ]", 585, 145);
  textSize(13);

  fill(35);
  rect(700, 20, 180, 350, 10);

  fill(255, 50, 100);
  textSize(16);
  text("3. KY-002", 715, 50);
  textSize(13);

  if (timerFeedbackVib > 0) {
    fill(255, 50, 100);
    timerFeedbackVib--;
  } else {
    fill(60);
  }
  rect(715, 90, 150, 80, 8);
  fill(255);
  text("IMPACTO", 760, 135);

  fill(220);
  textSize(12);
  text("Fondo: " + (segRestantes > 0 ? nf(segRestantes, 0, 1) + " s" : "apagado"), 715, 200);
  text("Teclas: D F G / K", 715, 350);
  textSize(13);
}

float actualizarCuerda(SoundFile s, float estado, float prev, float vol, float ampAct) {
  boolean on = estado > 0.5;

  if (on && prev <= 0.5) {
    s.stop();
    s.amp(0);
    s.loop();
    ampAct = 0;
  }

  ampAct = lerp(ampAct, on ? vol : 0, on ? 0.6 : 0.2);

  if (s.isPlaying()) {
    s.amp(ampAct);
    if (!on && ampAct < 0.01) s.stop();
  }
  return ampAct;
}

/* ------- SERIAL / OSC ------- */
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
  } else if (direccion.equals("/botones/1")) {
      serialBtn1 = valor;
  } else if (direccion.equals("/botones/2")) {
      serialBtn2 = valor;
  } else if (direccion.equals("/botones/3")) {
      serialBtn3 = valor;
  } else if (direccion.equals("/vibracion")) {
    golpeBombo = true;
    timerFeedbackVib = 8;
  }
}

void keyPressed() {
  char k = Character.toLowerCase(key);

  if (k == 'd') tecladoBtn1 = 1;
  else if (k == 'f') tecladoBtn2 = 1;
  else if (k == 'g') tecladoBtn3 = 1;
  else if (k == 'k' && !kPresionada) {
    kPresionada = true;
    golpeBombo = true;
    timerFeedbackVib = 8;
  }
}

void keyReleased() {
  char k = Character.toLowerCase(key);

  if (k == 'd') tecladoBtn1 = 0;
  else if (k == 'f') tecladoBtn2 = 0;
  else if (k == 'g') tecladoBtn3 = 0;
  else if (k == 'k') kPresionada = false;
}
