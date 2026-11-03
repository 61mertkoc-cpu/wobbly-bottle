const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ARTIFACT_DIR = 'C:\\Users\\PC\\.gemini\\antigravity\\brain\\d1bcc683-775c-44a3-b7c0-2a036b060908';
const INPUT_MP4 = path.join(ARTIFACT_DIR, 'WobblyBottle_Reklam_2_Uzun_1080p_60fps.mp4');
const FFMPEG_PATH = 'C:\\Users\\PC\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-9.0-full_build\\bin\\ffmpeg.exe';

const DURATION = 26.0;
const SAMPLE_RATE = 44100;
const NUM_SAMPLES = Math.floor(SAMPLE_RATE * DURATION);

// Simple 1-pole & 2-pole filter helpers for warm analog sound
class LowPassFilter {
  constructor(cutoffHz) {
    const rc = 1.0 / (2 * Math.PI * cutoffHz);
    const dt = 1.0 / SAMPLE_RATE;
    this.alpha = dt / (rc + dt);
    this.y = 0;
  }
  process(x) {
    this.y = this.y + this.alpha * (x - this.y);
    return this.y;
  }
}

class HighPassFilter {
  constructor(cutoffHz) {
    const rc = 1.0 / (2 * Math.PI * cutoffHz);
    const dt = 1.0 / SAMPLE_RATE;
    this.alpha = rc / (rc + dt);
    this.y = 0;
    this.prevX = 0;
  }
  process(x) {
    this.y = this.alpha * (this.y + x - this.prevX);
    this.prevX = x;
    return this.y;
  }
}

function writeWav(wavPath, left, right) {
  const buffer = Buffer.alloc(44 + NUM_SAMPLES * 4);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + NUM_SAMPLES * 4, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(2, 22);
  buffer.writeUInt32LE(SAMPLE_RATE, 24);
  buffer.writeUInt32LE(SAMPLE_RATE * 4, 28);
  buffer.writeUInt16LE(4, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(NUM_SAMPLES * 4, 40);

  let offset = 44;
  for (let i = 0; i < NUM_SAMPLES; i++) {
    // Soft analog tanh limiter
    const l = Math.tanh(left[i] * 0.95);
    const r = Math.tanh(right[i] * 0.95);
    buffer.writeInt16LE(Math.floor(l * 32000), offset);
    buffer.writeInt16LE(Math.floor(r * 32000), offset + 2);
    offset += 4;
  }
  fs.writeFileSync(wavPath, buffer);
}

function buildAudioTrack({ includeMusic }) {
  const left = new Float32Array(NUM_SAMPLES);
  const right = new Float32Array(NUM_SAMPLES);

  function addSample(idx, l, r) {
    if (idx >= 0 && idx < NUM_SAMPLES) {
      left[idx] += l;
      right[idx] += r;
    }
  }

  // ==========================================================================
  // 1. REALISTIC CINEMATIC SFX (NO HIGH-PITCHED BEEPS OR HARSH CLICKS!)
  // ==========================================================================

  // A) Cinematic Air Whoosh (for text & card transitions)
  function addCinematicWhoosh(tCenter, duration = 0.55, vol = 0.32, panDir = 1) {
    const start = Math.floor((tCenter - duration * 0.5) * SAMPLE_RATE);
    const len = Math.floor(duration * SAMPLE_RATE);
    const hp = new HighPassFilter(140);
    let lpState = 0;

    for (let i = 0; i < len; i++) {
      const p = i / len; // 0 -> 1
      const env = Math.sin(p * Math.PI); // Smooth bell curve
      // Dynamic filter cutoff sweep (200Hz -> 1100Hz -> 200Hz)
      const cutoff = 180 + 950 * Math.pow(env, 1.6);
      const rc = 1.0 / (2 * Math.PI * cutoff);
      const dt = 1.0 / SAMPLE_RATE;
      const alpha = dt / (rc + dt);

      const white = (Math.random() * 2 - 1);
      lpState = lpState + alpha * (white - lpState);
      const filtered = hp.process(lpState);

      // Subtle low sub-thud at peak of whoosh
      const subEnv = Math.exp(-Math.pow((p - 0.52) * 6, 2));
      const sub = Math.sin(2 * Math.PI * 58 * (i / SAMPLE_RATE)) * subEnv * 0.45;

      const sig = (filtered * 1.4 + sub) * env * vol;
      const pan = (p * 2 - 1) * 0.45 * panDir;
      addSample(start + i, sig * (1 - pan), sig * (1 + pan));
    }
  }

  // B) Realistic Glass Bottle Spinning on Wooden Table (5.30s -> 8.20s)
  // Soft rolling resonance + gentle damped wood/glass pulses (NO sine beeps!)
  function addRealisticBottleSpin(tStart, tEnd, vol = 0.34) {
    const start = Math.floor(tStart * SAMPLE_RATE);
    const len = Math.floor((tEnd - tStart) * SAMPLE_RATE);
    const lp = new LowPassFilter(480);
    const hp = new HighPassFilter(110);

    for (let i = 0; i < len; i++) {
      const p = i / len; // 0 -> 1
      const t = i / SAMPLE_RATE;
      const speed = Math.pow(1 - p, 1.8); // Fast at start, slows down smoothly to 0
      // Rolling modulation (bottle neck passing over table grain)
      const angle = (1 - Math.pow(1 - p, 2.8)) * Math.PI * 2 * 7.5;
      const grainMod = 0.55 + 0.45 * Math.sin(angle * 2);

      const raw = (Math.random() * 2 - 1) * grainMod;
      const body = hp.process(lp.process(raw));

      // Gentle low glass-table resonance around 220Hz-290Hz
      const resFreq = 210 + 90 * speed;
      const res = Math.sin(2 * Math.PI * resFreq * t) * 0.08 * grainMod;

      const env = Math.min(1, t * 8) * Math.pow(1 - p, 0.85);
      const sig = (body * 1.5 + res) * env * vol;
      const pan = Math.sin(angle) * 0.35;
      addSample(start + i, sig * (1 - pan), sig * (1 + pan));
    }
  }

  // C) Soft Warm Chord Swell (when bottle locks or card opens — warm pad, not 8-bit beep)
  function addWarmSwell(t0, dur, freqs, vol = 0.16) {
    const start = Math.floor(t0 * SAMPLE_RATE);
    const len = Math.floor(dur * SAMPLE_RATE);
    const lp = new LowPassFilter(1400);

    for (let i = 0; i < len; i++) {
      const t = i / SAMPLE_RATE;
      const p = i / len;
      const env = Math.sin(Math.min(1, p * 3.5) * (Math.PI / 2)) * Math.exp(-t * 2.2);
      let sum = 0;
      for (let k = 0; k < freqs.length; k++) {
        const f = freqs[k];
        sum += Math.sin(2 * Math.PI * f * t) * 0.65;
        sum += Math.sin(2 * Math.PI * (f * 1.003) * t) * 0.35;
      }
      const sig = lp.process(sum / freqs.length) * env * vol;
      addSample(start + i, sig * 0.95, sig * 1.05);
    }
  }

  // D) Subtle Soft UI Touch (low-mid muted pop, not a sharp click)
  function addSoftTouch(t0, vol = 0.22) {
    const start = Math.floor(t0 * SAMPLE_RATE);
    const len = Math.floor(0.06 * SAMPLE_RATE);
    let phase = 0;
    for (let i = 0; i < len; i++) {
      const t = i / SAMPLE_RATE;
      const freq = 180 + 220 * Math.exp(-t * 95);
      phase += (2 * Math.PI * freq) / SAMPLE_RATE;
      const env = Math.exp(-t * 65);
      const s = Math.sin(phase) * env * vol;
      addSample(start + i, s, s);
    }
  }

  // Place Synced Cinematic SFX across the 26s timeline:
  // Act 1: Headlines
  addCinematicWhoosh(0.20, 0.50, 0.30, 1);
  addCinematicWhoosh(1.40, 0.55, 0.32, -1);

  // Act 2: Arena transition, soft touch on Spin, realistic bottle roll, warm lock swell
  addCinematicWhoosh(4.50, 0.50, 0.28, 1);
  addSoftTouch(5.20, 0.22);
  addRealisticBottleSpin(5.30, 8.20, 0.36);
  addCinematicWhoosh(8.20, 0.45, 0.30, -1);
  addWarmSwell(8.20, 1.40, [261.63, 311.13, 392.00, 466.16], 0.20); // Cm7 warm chord
  addSoftTouch(10.35, 0.22);

  // Act 3: Dare Card Whoosh + Warm Swell
  addCinematicWhoosh(11.00, 0.55, 0.34, 1);
  addWarmSwell(11.05, 1.80, [233.08, 293.66, 349.23, 466.16], 0.20); // Bbmaj7

  // Act 4: 5 Objects & 6 Packs Whooshes
  addCinematicWhoosh(16.00, 0.55, 0.30, -1);
  addCinematicWhoosh(19.00, 0.55, 0.30, 1);

  // Act 5: Outro Store CTA
  addCinematicWhoosh(22.00, 0.60, 0.34, -1);
  addWarmSwell(22.05, 2.50, [261.63, 311.13, 392.00, 523.25], 0.22);

  // ==========================================================================
  // 2. WARM DEEP-HOUSE / LOUNGE CLUB GROOVE (IF includeMusic == true)
  // ==========================================================================
  if (includeMusic) {
    const bpm = 120; // Smooth 120 BPM Deep House tempo
    const beatDur = 60 / bpm; // 0.50s per beat
    const barDur = beatDur * 4; // 2.0s per bar

    // 4-Bar Deep House Chord Progression (Cm9 -> Fm9 -> Abmaj7 -> G7alt)
    const chordProg = [
      [130.81, 155.56, 196.00, 233.08, 293.66], // Cm9
      [174.61, 207.65, 261.63, 311.13, 392.00], // Fm9
      [103.83, 155.56, 196.00, 246.94, 311.13], // Abmaj7
      [98.00,  146.83, 174.61, 233.08, 293.66], // Gm7
    ];

    const bassProg = [65.41, 87.31, 51.91, 49.00]; // Deep sub roots (C2, F2, Ab1, G1)

    const padLP = new LowPassFilter(920); // Silky warm analog pad filter
    const bassLP = new LowPassFilter(240); // Deep round sub-bass filter

    for (let i = 0; i < NUM_SAMPLES; i++) {
      const t = i / SAMPLE_RATE;
      const beatIndex = Math.floor(t / beatDur);
      const beatFrac = (t % beatDur) / beatDur; // 0 -> 1 within each beat
      const barIndex = Math.floor(t / barDur);
      const chord = chordProg[barIndex % chordProg.length];
      const bassRoot = bassProg[barIndex % bassProg.length];

      // Sidechain ducking envelope (pumps smoothly on every kick!)
      const sidechain = 0.25 + 0.75 * (1 - Math.exp(-beatFrac * 5.5));

      // 1) Warm Deep-House Pad Chords (Filtered Triangle/Sine Detuned Stack)
      let padSum = 0;
      for (let c = 0; c < chord.length; c++) {
        const f = chord[c];
        padSum += Math.sin(2 * Math.PI * f * t);
        padSum += 0.5 * Math.sin(2 * Math.PI * (f * 1.004) * t + 0.8);
      }
      const warmPad = padLP.process(padSum / chord.length) * sidechain * 0.20;

      // 2) Deep Off-Beat Club Sub-Bass (Groovy pluck on offbeats + syncopation)
      const subFrac = (beatFrac * 2) % 1;
      const isOffbeat = beatFrac >= 0.5;
      const bassEnv = isOffbeat
        ? Math.exp(-subFrac * 4.2)
        : Math.exp(-subFrac * 7.5) * 0.45;
      const bassFreq = isOffbeat ? bassRoot : bassRoot * 0.5;
      // Rich harmonic bass passed through 240Hz low-pass filter
      const rawBass = Math.sin(2 * Math.PI * bassFreq * t) +
                      0.45 * Math.sin(2 * Math.PI * bassFreq * 2 * t) +
                      0.20 * Math.sin(2 * Math.PI * bassFreq * 3 * t);
      const deepBass = bassLP.process(rawBass) * bassEnv * sidechain * 0.34;

      // 3) Warm 909 Club Kick Drum on every beat
      const kickTime = t % beatDur;
      let kick = 0;
      if (kickTime < 0.22) {
        const kFreq = 46 + 110 * Math.exp(-kickTime * 38);
        const kEnv = Math.exp(-kickTime * 15);
        kick = Math.sin(2 * Math.PI * kFreq * kickTime) * kEnv * 0.48;
      }

      // 4) Soft Brushed Shaker on off-beats (high-passed & smoothed, not harsh)
      let shaker = 0;
      if (beatFrac >= 0.48 && beatFrac < 0.68) {
        const sTime = (beatFrac - 0.48) / 0.20;
        const sEnv = Math.sin(sTime * Math.PI) * Math.exp(-sTime * 3);
        shaker = (Math.random() * 2 - 1) * sEnv * 0.035;
      }

      // Stereo widening on warm pad
      const stereoWobble = Math.sin(t * 1.5) * 0.04;
      left[i] += kick + deepBass + warmPad * (1 + stereoWobble) + shaker * 0.9;
      right[i] += kick + deepBass + warmPad * (1 - stereoWobble) + shaker * 1.1;
    }
  }

  // Smooth fade-in (0.3s) and fade-out (0.8s)
  const fadeIn = Math.floor(0.3 * SAMPLE_RATE);
  for (let i = 0; i < fadeIn; i++) {
    const f = i / fadeIn;
    left[i] *= f;
    right[i] *= f;
  }
  const fadeOut = Math.floor(0.8 * SAMPLE_RATE);
  for (let i = 0; i < fadeOut; i++) {
    const idx = NUM_SAMPLES - 1 - i;
    const f = i / fadeOut;
    left[idx] *= f;
    right[idx] *= f;
  }

  return { left, right };
}

function main() {
  // 1. Generate Warm Deep-House + Realistic SFX version
  const wavWithMusic = path.join(ARTIFACT_DIR, 'temp_warm_music.wav');
  const outWithMusic = path.join(ARTIFACT_DIR, 'WobblyBottle_Reklam_2_YeniSes_1080p_60fps.mp4');
  const track1 = buildAudioTrack({ includeMusic: true });
  writeWav(wavWithMusic, track1.left, track1.right);

  execFileSync(FFMPEG_PATH, [
    '-y',
    '-i', INPUT_MP4,
    '-i', wavWithMusic,
    '-map', '0:v:0',
    '-map', '1:a:0',
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-movflags', '+faststart',
    outWithMusic
  ]);

  // 2. Generate SFX-Only version (for adding trending Reels/TikTok songs if desired)
  const wavSfxOnly = path.join(ARTIFACT_DIR, 'temp_sfx_only.wav');
  const outSfxOnly = path.join(ARTIFACT_DIR, 'WobblyBottle_Reklam_2_SadeceEfekt_1080p_60fps.mp4');
  const track2 = buildAudioTrack({ includeMusic: false });
  writeWav(wavSfxOnly, track2.left, track2.right);

  execFileSync(FFMPEG_PATH, [
    '-y',
    '-i', INPUT_MP4,
    '-i', wavSfxOnly,
    '-map', '0:v:0',
    '-map', '1:a:0',
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-movflags', '+faststart',
    outSfxOnly
  ]);

  try {
    fs.copyFileSync(outWithMusic, 'C:\\Users\\PC\\Desktop\\WobblyBottle_Reklam_2_YeniSes_1080p_60fps.mp4');
    fs.copyFileSync(outWithMusic, 'C:\\Users\\PC\\Desktop\\WobblyBottle_Reklam_2_Uzun_1080p_60fps.mp4');
    fs.copyFileSync(outSfxOnly, 'C:\\Users\\PC\\Desktop\\WobblyBottle_Reklam_2_SadeceEfekt_1080p_60fps.mp4');
    console.log('Copied to Desktop!');
  } catch (e) {
    console.log('Desktop copy note:', e.message);
  }

  try { fs.unlinkSync(wavWithMusic); } catch (_) {}
  try { fs.unlinkSync(wavSfxOnly); } catch (_) {}
  console.log('Successfully generated both new audio versions!');
}

main();
