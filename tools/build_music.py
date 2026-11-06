"""Rebuild original MIT-licensed Sword Ablaze loops (Python + NumPy)."""
from pathlib import Path
import wave
import numpy as np

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets/audio"

def render(combat):
    # Eight bars in D minor; identical harmony links the sanctuary and courtyard.
    bpm = 112 if combat else 72
    beat = 60 / bpm
    seconds = 32 * beat
    count = round(seconds * RATE)
    mix = np.zeros(count)

    def note(midi, start, duration, gain, bell=False):
        n = round(duration * RATE)
        t = np.arange(n) / RATE
        frequency = 440 * 2 ** ((midi - 69) / 12)
        envelope = np.minimum(t / 0.035, 1) * np.minimum((duration - t) / 0.18, 1)
        tone = np.sin(2 * np.pi * frequency * t)
        tone += (0.25 if bell else 0.12) * np.sin(2 * np.pi * frequency * 2 * t)
        if bell:
            envelope *= np.exp(-t * 2.2)
        values = tone * envelope * gain
        # Wrap releases at loop boundary for sample-continuous looping.
        indices = (round(start * RATE) + np.arange(n)) % count
        np.add.at(mix, indices, values)

    chords = [(50, 57, 65), (46, 53, 62), (53, 60, 69), (48, 55, 64)] * 2
    for bar, chord in enumerate(chords):
        for pitch in chord:
            note(pitch, bar * 4 * beat, 4.3 * beat, 0.055)
        melody = [chord[2] + 12, chord[1] + 12, chord[2] + 7, chord[1] + 12]
        for step, pitch in enumerate(melody):
            note(pitch, (bar * 4 + step) * beat, beat * 1.4, 0.065, True)
        if combat:
            for step in range(8):
                note(chord[0] - 12, (bar * 4 + step / 2) * beat, beat * 0.4, 0.12, True)
            for step in range(4):
                start = round((bar * 4 + step) * beat * RATE)
                t = np.arange(round(0.18 * RATE)) / RATE
                kick = np.sin(2 * np.pi * (48 * t + 7 * (1 - np.exp(-t * 35)))) * np.exp(-t * 28) * 0.12
                mix[(start + np.arange(len(t))) % count] += kick
    assert np.isfinite(mix).all() and np.max(np.abs(mix)) < 0.95
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / ("courtyard.wav" if combat else "sanctuary.wav")), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((mix * 32767).astype("<i2").tobytes())

if __name__ == "__main__":
    render(False)
    render(True)
