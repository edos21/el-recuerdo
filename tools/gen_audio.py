# Genera todo el audio del juego (ambiente, capas musicales y SFX) como WAV
# mono 44.1 kHz, sintetizado con numpy. Reproducible: python3 tools/gen_audio.py
import numpy as np, wave, os
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "audio") + os.sep
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(3)

def save(name, x, peak=0.8):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    with wave.open(OUT + name + ".wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(name, round(len(x) / SR, 2), "s")

def t(sec): return np.arange(int(SR * sec)) / SR
def env(n, a, r):
    e = np.ones(n); a = int(a * SR); r = int(r * SR)
    e[:a] = np.linspace(0, 1, a); e[-r:] *= np.linspace(1, 0, r); return e
def loop_fade(x, ms=20):
    n = int(SR * ms / 1000); x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n); return x
def lowpass(x, cutoff):
    # filtro IIR de un polo, suficiente para dar cuerpo sin scipy
    rc = 1.0 / (2 * np.pi * cutoff); a = 1.0 / (1.0 + rc * SR)
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y
def note(freq, sec, amp=1.0, harmonics=(1.0, 0.35, 0.12)):
    tt = t(sec); x = np.zeros_like(tt)
    for i, h in enumerate(harmonics):
        x += h * np.sin(2 * np.pi * freq * (i + 1) * tt)
    return x * amp

# --- ambiente: viento (ruido filtrado con vaiven lento), 20 s loop ---
tt = t(20); n = rng.normal(0, 1, len(tt))
wind = lowpass(n, 380) * (0.55 + 0.45 * np.sin(2 * np.pi * 0.07 * tt + 1.0)) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.23 * tt))
save("amb_wind", loop_fade(wind), 0.5)

# --- hum: drone grave con batido, 16 s loop ---
tt = t(16)
hum = np.sin(2 * np.pi * 55 * tt) + 0.6 * np.sin(2 * np.pi * 55.6 * tt) + 0.25 * np.sin(2 * np.pi * 110 * tt)
hum *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.11 * tt)
save("amb_hum", loop_fade(hum), 0.45)

# --- pad: cuatro acordes menores, 32 s loop (8 s c/u) ---
chords = [(220.0, 261.63, 329.63), (174.61, 220.0, 261.63), (196.0, 246.94, 293.66), (164.81, 196.0, 246.94)]
pad = np.zeros(0)
for c in chords:
    seg = sum(note(f, 8.0, 0.33, (1.0, 0.3, 0.08, 0.04)) for f in c)
    seg *= env(len(seg), 1.2, 1.2)
    pad = np.concatenate([pad, seg])
save("music_pad", loop_fade(lowpass(pad, 1200)), 0.5)

# --- melodia: motivo lento sobre el pad, 32 s loop ---
seq = [(329.63, 2), (293.66, 1), (261.63, 3), (0, 2), (220.0, 2), (246.94, 1), (261.63, 3), (0, 2),
       (293.66, 2), (329.63, 1), (392.0, 3), (0, 2), (329.63, 2), (293.66, 1), (246.94, 3), (0, 2)]
mel = np.zeros(0)
for f, beats in seq:
    sec = beats * 1.0
    seg = note(f, sec, 0.5, (1.0, 0.2, 0.05)) if f else np.zeros(int(SR * sec))
    if f: seg *= env(len(seg), 0.08, 0.5)
    mel = np.concatenate([mel, seg])
save("music_melody", loop_fade(mel), 0.4)

# --- SFX ---
tt = t(0.18); save("sfx_jump", np.sin(2 * np.pi * (300 + 500 * tt / 0.18) * tt) * env(len(tt), 0.005, 0.1))
tt = t(0.12); save("sfx_land", lowpass(rng.normal(0, 1, len(tt)), 400) * env(len(tt), 0.002, 0.1))
tt = t(0.15); save("sfx_attack", lowpass(rng.normal(0, 1, len(tt)), 2500) * np.exp(-tt * 30) + 0.3 * np.sin(2 * np.pi * (900 - 600 * tt / 0.15) * tt) * env(len(tt), 0.002, 0.1))
tt = t(0.25); save("sfx_hit_take", np.sin(2 * np.pi * (180 - 100 * tt / 0.25) * tt) * env(len(tt), 0.003, 0.2) + 0.4 * lowpass(rng.normal(0, 1, len(tt)), 600) * np.exp(-tt * 25))
tt = t(0.35); save("sfx_enemy_die", lowpass(rng.normal(0, 1, len(tt)), 900) * np.exp(-tt * 9) * (1 + 0.5 * np.sin(2 * np.pi * 8 * tt)))
tt = t(0.5); ck = note(523.25, 0.5, 1.0, (1.0, 0.3)) * env(len(tt), 0.005, 0.4); ck[int(SR * 0.18):] += note(783.99, 0.5 - 0.18, 0.8, (1.0, 0.3)) * env(len(tt) - int(SR * 0.18), 0.005, 0.3)
save("sfx_checkpoint", ck)
tt = t(0.2); save("sfx_spike", np.sign(np.sin(2 * np.pi * 140 * tt)) * env(len(tt), 0.002, 0.15) * np.exp(-tt * 12))
# Rafaga de aire que sube: al final del archivo para no correr la semilla de `rng` de los demas.
tt = t(0.16); save("sfx_dash", lowpass(rng.normal(0, 1, len(tt)), 1800) * env(len(tt), 0.01, 0.12) * (0.4 + tt / 0.16) + 0.25 * np.sin(2 * np.pi * (400 + 700 * tt / 0.16) * tt) * env(len(tt), 0.005, 0.1))
