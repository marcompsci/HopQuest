"""Synthesizes HopQuest's original sound effects and music loops (no samples, nothing licensed).

Usage: python3 make_audio.py <out_dir>
Writes sfx_*.wav (22.05 kHz mono) and music_*.wav (44.1 kHz) — music is converted to .m4a by the caller.
"""
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, sr=SR):
    """Simple ADSR-ish envelope of n samples (attack, decay to sustain, release at the end)."""
    t = np.arange(n) / sr
    e = np.ones(n)
    a_n = max(1, int(a * sr))
    e[:a_n] = np.linspace(0, 1, a_n)
    d_n = int(d * sr)
    if d_n > 0:
        end = min(n, a_n + d_n)
        e[a_n:end] = np.linspace(1, s if s > 0 else 0.0001, end - a_n) if s > 0 else np.exp(-np.linspace(0, 5, end - a_n))
        if s > 0:
            e[end:] = s
        else:
            e[end:] = 0
    r_n = int(r * sr)
    if r_n > 0 and s > 0:
        e[-r_n:] *= np.linspace(1, 0, r_n)
    return e


def sweep(f0, f1, dur, shape="sine", sr=SR, curve=1.0):
    n = int(dur * sr)
    k = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / sr
    return wave(ph, shape)


def wave(ph, shape):
    if shape == "sine":
        return np.sin(ph)
    if shape == "square":
        return np.sign(np.sin(ph)) * 0.6
    if shape == "pulse":
        return np.where((ph / (2 * np.pi)) % 1 < 0.25, 0.6, -0.6)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    raise ValueError(shape)


def tone(freq, dur, shape="sine", sr=SR, vib=0.0, vib_rate=6.0):
    n = int(dur * sr)
    t = np.arange(n) / sr
    f = freq * (1 + vib * np.sin(2 * np.pi * vib_rate * t))
    ph = 2 * np.pi * np.cumsum(f) / sr
    return wave(ph, shape)


def bell(freq, dur, sr=SR):
    n = int(dur * sr)
    t = np.arange(n) / sr
    s = (np.sin(2 * np.pi * freq * t) + 0.45 * np.sin(2 * np.pi * freq * 2.01 * t) * np.exp(-t * 9)
         + 0.25 * np.sin(2 * np.pi * freq * 3.02 * t) * np.exp(-t * 14))
    return s * np.exp(-t * 5.5) * np.clip(t * 400, 0, 1)


def noise(dur, sr=SR, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(dur * sr))


def bandpass(x, lo, hi, sr=SR):
    b, a = butter(2, [lo / (sr / 2), hi / (sr / 2)], btype="band")
    return lfilter(b, a, x)


def lowpass(x, f, sr=SR):
    b, a = butter(2, f / (sr / 2), btype="low")
    return lfilter(b, a, x)


def mix(*parts, offsets=None, sr=SR):
    offsets = offsets or [0] * len(parts)
    n = max(int(o * sr) + len(p) for p, o in zip(parts, offsets))
    out = np.zeros(n)
    for p, o in zip(parts, offsets):
        i = int(o * sr)
        out[i:i + len(p)] += p
    return out


def norm(x, peak=0.85):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


def fade(x, ms=6, sr=SR):
    n = int(ms / 1000 * sr)
    if n and len(x) > 2 * n:
        x[:n] *= np.linspace(0, 1, n)
        x[-n:] *= np.linspace(1, 0, n)
    return x


def save(path, x, sr=SR, peak=0.85):
    x = fade(norm(x.astype(np.float64), peak), sr=sr)
    wavfile.write(path, sr, (x * 32767).astype(np.int16))


# ------------------------------------------------------------------ sound effects

def sfx(out):
    # hop: springy rising blip
    s = sweep(360, 760, 0.11, curve=0.6) * env(int(0.11 * SR), 0.003, 0.11)
    s += 0.3 * sweep(720, 1520, 0.11, curve=0.6) * env(int(0.11 * SR), 0.003, 0.06)
    save(f"{out}/sfx_hop.wav", s, peak=0.6)

    # coin: classic two-tone ding
    a = tone(988, 0.07, "square") * env(int(0.07 * SR), 0.002, 0.07, 0.6, 0.01)
    b = tone(1319, 0.28, "square") * env(int(0.28 * SR), 0.002, 0.28)
    save(f"{out}/sfx_coin.wav", lowpass(mix(a, b, offsets=[0, 0.07]), 6000), peak=0.55)

    # star: sparkly bell arpeggio
    notes = [1047, 1319, 1568, 2093]
    parts = [bell(f, 0.6) for f in notes]
    save(f"{out}/sfx_star.wav", mix(*parts, offsets=[0, 0.07, 0.14, 0.21]), peak=0.7)

    # correct: two rising bells
    save(f"{out}/sfx_correct.wav", mix(bell(784, 0.5), bell(1047, 0.7), offsets=[0, 0.11]), peak=0.75)

    # try again: gentle low "bwoo" (never harsh)
    w = sweep(420, 300, 0.32, "tri") * env(int(0.32 * SR), 0.01, 0.32)
    save(f"{out}/sfx_tryagain.wav", lowpass(w, 2000), peak=0.5)

    # boing: cartoon spring
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    f = 190 + 90 * np.sin(2 * np.pi * 16 * t) * np.exp(-t * 5) + 140 * np.exp(-t * 7)
    ph = 2 * np.pi * np.cumsum(f) / SR
    save(f"{out}/sfx_boing.wav", np.sin(ph) * np.exp(-t * 4.5) * np.clip(t * 300, 0, 1), peak=0.7)

    # splash: filtered noise + bubbles
    nz = bandpass(noise(0.45, seed=3), 500, 4000) * np.exp(-np.linspace(0, 6, int(0.45 * SR)))
    bubbles = [sweep(500 + i * 180, 1100 + i * 220, 0.05) * env(int(0.05 * SR), 0.002, 0.05) * 0.4 for i in range(4)]
    save(f"{out}/sfx_splash.wav", mix(nz, *bubbles, offsets=[0, 0.12, 0.2, 0.27, 0.33]), peak=0.6)

    # whoosh: swept noise (balloon / boost)
    d = 0.9
    nz = noise(d, seed=5)
    n = len(nz)
    outb = np.zeros(n)
    chunk = 512
    for i in range(0, n, chunk):
        k = i / n
        center = 400 + 2200 * np.sin(np.pi * k)
        seg = bandpass(nz[max(0, i - 2048):i + chunk], max(80, center * 0.6), min(10000, center * 1.4))
        outb[i:i + chunk] = seg[-min(chunk, n - i):]
    outb *= np.sin(np.linspace(0, np.pi, n)) ** 1.5
    save(f"{out}/sfx_whoosh.wav", outb, peak=0.55)

    # countdown beeps
    save(f"{out}/sfx_beep.wav", lowpass(tone(660, 0.16, "square") * env(int(0.16 * SR), 0.003, 0.16, 0.7, 0.03), 5000), peak=0.5)
    save(f"{out}/sfx_go.wav", lowpass(tone(988, 0.45, "square", vib=0.01) * env(int(0.45 * SR), 0.003, 0.45, 0.7, 0.1), 5000), peak=0.55)

    # blinker tick / tock
    for name, f in (("tick", 2200), ("tock", 1700)):
        c = tone(f, 0.018) * np.exp(-np.linspace(0, 8, int(0.018 * SR)))
        c = mix(c, bandpass(noise(0.012, seed=9), 2000, 6000) * 0.4)
        save(f"{out}/sfx_{name}.wav", c, peak=0.45)

    # pop (item / UI)
    save(f"{out}/sfx_pop.wav", sweep(500, 1300, 0.06, curve=0.5) * env(int(0.06 * SR), 0.002, 0.06), peak=0.5)

    # tap (soft UI click)
    save(f"{out}/sfx_tap.wav", tone(1200, 0.03, "tri") * np.exp(-np.linspace(0, 7, int(0.03 * SR))), peak=0.35)

    # fanfare (level complete)
    seq = [(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.6)]
    parts, offs, t0 = [], [], 0.0
    for f, d in seq:
        p = tone(f, d, "pulse", vib=0.006) * env(int(d * SR), 0.004, d, 0.8, 0.05)
        p += 0.5 * tone(f * 2, d, "tri") * env(int(d * SR), 0.004, d, 0.6, 0.05)
        parts.append(lowpass(p, 5000))
        offs.append(t0)
        t0 += d * 0.9
    sparkle = [bell(2093 + i * 260, 0.4) * 0.35 for i in range(3)]
    save(f"{out}/sfx_fanfare.wav", mix(*parts, *sparkle, offsets=offs + [0.42, 0.5, 0.58]), peak=0.7)

    # engine loop: exactly 1 second, whole cycles, so it loops seamlessly
    n = SR
    t = np.arange(n) / SR
    e = (wave(2 * np.pi * 55 * t, "saw") * 0.6 + wave(2 * np.pi * 110 * t, "saw") * 0.3
         + np.sin(2 * np.pi * 27.5 * t) * 0.4)
    e *= 0.8 + 0.2 * np.sin(2 * np.pi * 11 * t)
    e = lowpass(np.tile(e, 3), 900)[n:2 * n]      # filter with wrap-around so the loop has no click
    wavfile.write(f"{out}/sfx_engine.wav", SR, (norm(e, 0.5) * 32767).astype(np.int16))


# ------------------------------------------------------------------ music

MSR = 44100


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


CHORD_ROOTS = {"C": 48, "Am": 45, "F": 41, "G": 43, "Em": 40, "D": 50 - 12, "Bm": 47 - 12, "Dm": 38}
CHORD_TONES = {"C": [0, 4, 7], "Am": [0, 3, 7], "F": [0, 4, 7], "G": [0, 4, 7], "Em": [0, 3, 7],
               "D": [0, 4, 7], "Bm": [0, 3, 7], "Dm": [0, 3, 7]}


def song(melody, chords, bpm, out_path, drive=False):
    eighth = 60 / bpm / 2
    total = len(chords) * 8 * eighth
    n = int(total * MSR) + MSR
    track = np.zeros(n)

    def place(sig, t):
        i = int(t * MSR)
        j = min(n, i + len(sig))
        track[i:j] += sig[: j - i]

    # lead melody: '-' holds the previous note
    flat = [x for bar in melody for x in bar]
    i = 0
    while i < len(flat):
        note = flat[i]
        length = 1
        while i + length < len(flat) and flat[i + length] == "-":
            length += 1
        if isinstance(note, int):
            d = length * eighth
            sig = tone(midi(note), d * 0.95, "pulse", sr=MSR, vib=0.004, vib_rate=5.5)
            sig += 0.35 * tone(midi(note), d * 0.95, "tri", sr=MSR)
            sig *= env(len(sig), 0.006, d, 0.55, 0.04, sr=MSR)
            place(lowpass(sig, 4200, MSR) * 0.32, i * eighth)
        i += length

    # bass + soft chord pad + drums
    for b, ch in enumerate(chords):
        root = CHORD_ROOTS[ch]
        bar_t = b * 8 * eighth
        pattern = [0, 12, 0, 12, 0, 12, 7, 12] if not drive else [0, 0, 12, 0, 0, 12, 7, 12]
        for k, off in enumerate(pattern):
            d = eighth * 0.9
            s = tone(midi(root + off), d, "tri", sr=MSR) * env(int(d * MSR), 0.004, d, 0.6, 0.02, sr=MSR)
            place(s * 0.42, bar_t + k * eighth)
        # pad: chord tones, quiet, whole bar
        d = 8 * eighth
        pad = sum(tone(midi(root + 24 + iv), d, "sine", sr=MSR, vib=0.002) for iv in CHORD_TONES[ch])
        pad *= env(len(pad), 0.05, d, 0.7, 0.2, sr=MSR)
        place(pad * 0.06, bar_t)
        # drums
        for k in range(8):
            t = bar_t + k * eighth
            if k in (0, 4) or (drive and k == 3):
                kick = sweep(150, 45, 0.16, sr=MSR, curve=0.4) * np.exp(-np.linspace(0, 6, int(0.16 * MSR)))
                place(kick * 0.55, t)
            if k in (2, 6):
                sn = bandpass(noise(0.14, sr=MSR, seed=b * 8 + k), 1200, 7000, MSR) * np.exp(-np.linspace(0, 9, int(0.14 * MSR)))
                body = 0.3 * tone(190, 0.08, sr=MSR) * np.exp(-np.linspace(0, 10, int(0.08 * MSR)))
                sn[: len(body)] += body
                place(sn * 0.22, t)
            hat = bandpass(noise(0.04, sr=MSR, seed=1000 + b * 8 + k), 6000, 12000, MSR) * np.exp(-np.linspace(0, 12, int(0.04 * MSR)))
            place(hat * (0.1 if k % 2 == 0 else 0.06), t)

    # wrap the tail into the start so the loop is seamless
    loop_n = int(total * MSR)
    tail = track[loop_n:]
    track = track[:loop_n]
    track[: len(tail)] += tail
    track = norm(track, 0.8)
    wavfile.write(out_path, MSR, (track * 32767).astype(np.int16))


ADVENTURE_MELODY = [
    [72, "-", 76, 79, "-", 76, 72, "-"], [74, 76, 72, "-", 69, "-", "-", "-"],
    [77, 76, 74, "-", 72, "-", 69, "-"], [71, 74, 79, "-", 77, "-", 74, "-"],
    [72, "-", 76, 79, "-", 84, 79, "-"], [81, 79, 76, "-", 72, "-", 76, "-"],
    [77, 79, 81, "-", 79, 77, 76, 74], [74, "-", 76, "-", 74, "-", 71, "-"],
    [77, "-", 81, "-", 84, "-", 81, "-"], [83, "-", 79, "-", 74, "-", 79, "-"],
    [79, "-", 76, "-", 71, "-", 76, "-"], [72, "-", 76, "-", 81, "-", 76, "-"],
    [77, 79, 81, 77, 72, 74, 77, "-"], [79, 81, 83, 79, 74, 77, 79, "-"],
    [84, "-", 79, "-", 76, "-", 72, "-"], [74, "-", 71, "-", 67, "-", "-", "-"],
]
ADVENTURE_CHORDS = ["C", "Am", "F", "G", "C", "Am", "F", "G", "F", "G", "Em", "Am", "F", "G", "C", "G"]

RACE_MELODY = [
    [79, "-", 74, "-", 79, 81, 83, "-"], [79, "-", 76, "-", 71, "-", 76, "-"],
    [72, 76, 79, "-", 76, "-", 72, "-"], [74, 78, 81, "-", 78, "-", 74, "-"],
    [79, 81, 83, "-", 86, "-", 83, "-"], [83, 81, 79, "-", 76, "-", 79, "-"],
    [76, 79, 84, "-", 83, 81, 79, 76], [78, "-", 81, "-", 78, "-", 74, "-"],
    [84, "-", 83, "-", 81, "-", 79, "-"], [78, "-", 81, "-", 86, "-", 81, "-"],
    [83, "-", 78, "-", 74, "-", 78, "-"], [79, "-", 83, "-", 88, "-", 83, "-"],
    [84, 83, 81, 79, 76, 79, 81, "-"], [83, 81, 78, 81, 86, "-", 81, "-"],
    [79, "-", 83, "-", 86, "-", 91, "-"], [86, "-", 81, "-", 78, "-", 74, "-"],
]
RACE_CHORDS = ["G", "Em", "C", "D", "G", "Em", "C", "D", "C", "D", "Bm", "Em", "C", "D", "G", "D"]
CHORD_ROOTS["G"] = 43


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    sfx(out)
    song(ADVENTURE_MELODY, ADVENTURE_CHORDS, 112, f"{out}/music_adventure.wav")
    song(RACE_MELODY, RACE_CHORDS, 138, f"{out}/music_race.wav", drive=True)
    print("ok")
