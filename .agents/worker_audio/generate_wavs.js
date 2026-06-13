const fs = require('fs');
const path = require('path');

function createDummyWav(filePath) {
    // 44-byte WAV header for minimal 8-bit PCM silence
    const header = Buffer.alloc(44);
    
    // "RIFF" chunk descriptor
    header.write('RIFF', 0);
    header.writeUInt32LE(36 + 100, 4); // ChunkSize (36 + Subchunk2Size)
    header.write('WAVE', 8);

    // "fmt " sub-chunk
    header.write('fmt ', 12);
    header.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
    header.writeUInt16LE(1, 20);  // AudioFormat (1 for PCM)
    header.writeUInt16LE(1, 22);  // NumChannels (1)
    header.writeUInt32LE(8000, 24); // SampleRate (8000)
    header.writeUInt32LE(8000, 28); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    header.writeUInt16LE(1, 32);  // BlockAlign (NumChannels * BitsPerSample/8)
    header.writeUInt16LE(8, 34);  // BitsPerSample (8)

    // "data" sub-chunk
    header.write('data', 36);
    header.writeUInt32LE(100, 40); // Subchunk2Size (NumSamples * NumChannels * BitsPerSample/8)

    // Data - 100 bytes of silence (128 is center for 8-bit)
    const data = Buffer.alloc(100, 128);

    const wavBuffer = Buffer.concat([header, data]);

    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, wavBuffer);
    console.log('Created dummy WAV at', filePath);
}

const basePath = path.join(__dirname, '../../public/sounds');
createDummyWav(path.join(basePath, 'footstep.wav'));
createDummyWav(path.join(basePath, 'sword_swing.wav'));
createDummyWav(path.join(basePath, 'enemy_hit.wav'));
