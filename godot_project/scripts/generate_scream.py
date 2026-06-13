import wave
import struct
import math
import random

sample_rate = 44100
duration = 0.8
num_samples = int(sample_rate * duration)

with wave.open(r"D:\src\fabled kingdoms\godot_project\assets\sounds\scream.wav", 'w') as wav_file:
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(sample_rate)
    
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency starts high and drops quickly (classic scream pitch drop)
        freq = 800 - (t * 600)
        
        # Add some noise for the "roughness" of a scream
        roughness = random.uniform(-1.0, 1.0) * 0.3
        
        # Add a bit of tremolo (vibrato)
        tremolo = math.sin(2.0 * math.pi * 15.0 * t) * 50.0
        
        # Envelope: quick attack, slow decay
        env = 1.0
        if t < 0.05:
            env = t / 0.05
        elif t > 0.4:
            env = max(0, 1.0 - (t - 0.4) / 0.4)
            
        value = math.sin(2.0 * math.pi * (freq + tremolo) * t) + roughness
        
        # Convert to 16-bit PCM
        sample = int(value * env * 16000)
        # Clamp
        sample = max(-32768, min(32767, sample))
        
        wav_file.writeframes(struct.pack('h', sample))

print("Scream WAV generated.")
