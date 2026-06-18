import serial
import serial.tools.list_ports
import vlc
import re
import time

# ==========================
# CONFIGURACIÓN
# ==========================

ARCHIVOS_AUDIO = [
    "Audio 0.mp3",
    "Audio 1.mp3",
    "Audio 2.mp3",
    "Audio 3.mp3"
]

VOLUMEN_ACTIVO = 100
VOLUMEN_INACTIVO = 0

# ==========================
# DETECCIÓN AUTOMÁTICA
# ==========================

def encontrar_arduino():

    puertos = serial.tools.list_ports.comports()

    for puerto in puertos:

        descripcion = puerto.description.lower()

if (
    "usb" in descripcion
    or "serial" in descripcion
    or "ch340" in descripcion
    or "cp210" in descripcion
    or "arduino" in descripcion
    or "esp32" in descripcion
):

            print(f"Arduino encontrado en {puerto.device}")
            return puerto.device

    return None

# ==========================
# AUDIO
# ==========================

players = []

for archivo in ARCHIVOS_AUDIO:

    media = vlc.MediaPlayer(archivo)

    media.play()

    time.sleep(0.2)

    media.audio_set_volume(0)

    players.append(media)

# audio0 siempre encendido
players[0].audio_set_volume(100)

# ==========================
# SERIAL
# ==========================

puerto = encontrar_arduino()

if puerto is None:
    print("No se encontró Arduino.")
    quit()

ser = serial.Serial(
    puerto,
    115200,
    timeout=1
)

print("Conectado.")
print()

estado_actual = -1

# ==========================
# FUNCIÓN DE CAPAS
# ==========================

def actualizar_capas(personas):

    for i, player in enumerate(players):

        if i <= personas:
            player.audio_set_volume(VOLUMEN_ACTIVO)
        else:
            player.audio_set_volume(VOLUMEN_INACTIVO)

# ==========================
# LOOP PRINCIPAL
# ==========================

while True:

    try:

        linea = ser.readline().decode(
            "utf-8",
            errors="ignore"
        ).strip()

        if not linea:
            continue

        print(linea)

        match = re.search(
            r"Personas en las placas:\s*(\d)",
            linea
        )

        if match:

            personas = int(match.group(1))

            if personas != estado_actual:

                estado_actual = personas

                print(
                    f"\nEstado cambiado -> {personas} personas\n"
                )

                actualizar_capas(personas)

    except KeyboardInterrupt:

        print("Programa finalizado.")

        break

    except Exception as e:

        print(e)