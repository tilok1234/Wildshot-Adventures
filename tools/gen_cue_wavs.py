"""Generate the seven Law-7 placeholder cue WAVs (mono 22050 Hz 16-bit).

Each key threat class gets a DISTINCT contour so classes are
distinguishable eyes-closed (Law 7 / CORE-50). Deterministic output:
same script, same bytes. Amplitudes are conservative (0.38 peak) with
5 ms fade-in/out envelopes so nothing clicks.
"""

import math
import os
import struct
import wave

RATE = 22050
OUT = r"C:\Users\headc\Documents\Wildshot-Adventures\audio\placeholder"


def env(i, n, fade=0.005):
    f = int(RATE * fade)
    a = 1.0
    if i < f:
        a = i / f
    if n - i < f:
        a = min(a, (n - i) / f)
    return a


def tone(samples, freq_fn, amp=0.38, noise=0.0):
    n = len(samples)
    phase = 0.0
    out = []
    for i in range(n):
        f = freq_fn(i / n)
        phase += 2.0 * math.pi * f / RATE
        s = math.sin(phase)
        if noise > 0.0:
            # Deterministic pseudo-noise: high-frequency triangle fold.
            s = (1.0 - noise) * s + noise * (2.0 * abs(2.0 * ((i * 0.113) % 1.0) - 1.0) - 1.0)
        out.append(s * amp * env(i, n) * samples[i])
    return out


def silence(ms):
    return [0.0] * int(RATE * ms / 1000.0)


def flat(ms, gain=1.0):
    return [gain] * int(RATE * ms / 1000.0)


def write(name, chunks):
    data = [s for c in chunks for s in c]
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in data))
    print(name, len(data), "samples")


os.makedirs(OUT, exist_ok=True)

# telegraph_ranged: short rising two-step blip (600 -> 900 Hz).
write(
    "telegraph_ranged.wav",
    [
        tone(flat(70), lambda t: 600.0),
        silence(25),
        tone(flat(70), lambda t: 900.0),
    ],
)

# telegraph_melee: sharp high double tick (1250 Hz).
write(
    "telegraph_melee.wav",
    [
        tone(flat(45), lambda t: 1250.0),
        silence(35),
        tone(flat(45), lambda t: 1250.0),
    ],
)

# hazard_cast: descending sweep (750 -> 380 Hz) - "something thrown down".
write("hazard_cast.wav", [tone(flat(150), lambda t: 750.0 - 370.0 * t)])

# hazard_armed: low thump with a noise edge (170 Hz).
write("hazard_armed.wav", [tone(flat(160), lambda t: 170.0 - 40.0 * t, amp=0.42, noise=0.15)])

# phase_change: three ascending notes (420/630/840 Hz) - the boss shifted.
write(
    "phase_change.wav",
    [
        tone(flat(90), lambda t: 420.0),
        silence(20),
        tone(flat(90), lambda t: 630.0),
        silence(20),
        tone(flat(130), lambda t: 840.0),
    ],
)

# player_hit: mid thud (290 -> 210 Hz, noisy).
write("player_hit.wav", [tone(flat(100), lambda t: 290.0 - 80.0 * t, amp=0.42, noise=0.25)])

# player_death: long fall (520 -> 140 Hz).
write("player_death.wav", [tone(flat(520), lambda t: 520.0 - 380.0 * t)])

print("done ->", OUT)
