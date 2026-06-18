import vlc
import time

archivos = [
    "Audio 0.mp3",
    "Audio 1.mp3",
    "Audio 2.mp3",
    "Audio 3.mp3"
]

players = []

for archivo in archivos:

    p = vlc.MediaPlayer(archivo)

    p.play()

    time.sleep(0.3)

    p.audio_set_volume(0)

    players.append(p)

players[0].audio_set_volume(100)

print("Solo Audio 0")
time.sleep(5)

players[1].audio_set_volume(20)

print("Audio 0 + Audio 1")
time.sleep(5)

players[2].audio_set_volume(20)

print("Audio 0 + Audio 1 + Audio 2")
time.sleep(5)

players[3].audio_set_volume(20)

print("Audio 0 + Audio 1 + Audio 2 + Audio 3")
time.sleep(5)

for p in players:
    p.stop()