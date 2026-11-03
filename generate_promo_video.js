const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const PROJECT_DIR = __dirname;
const ASSETS_DIR = path.join(PROJECT_DIR, 'assets');
const ARTIFACT_DIR = 'C:\\Users\\PC\\.gemini\\antigravity\\brain\\d1bcc683-775c-44a3-b7c0-2a036b060908';
const OUTPUT_MP4 = path.join(ARTIFACT_DIR, 'WobblyBottle_Reklam_1080p_60fps.mp4');
const TEMP_WAV = path.join(ARTIFACT_DIR, 'temp_promo_audio.wav');
const FFMPEG_PATH = 'C:\\Users\\PC\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-9.0-full_build\\bin\\ffmpeg.exe';
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const FPS = 60;
const DURATION = 16.0; // 16 seconds
const TOTAL_FRAMES = Math.round(FPS * DURATION); // 960 frames

// ============================================================================
// 1. SYNTHESIZE 128-BPM PARTY SOUNDTRACK + SYNCED SFX (44.1kHz Stereo WAV)
// ============================================================================
function generateAudioWav(wavPath) {
  const sampleRate = 44100;
  const numSamples = Math.floor(sampleRate * DURATION);
  const left = new Float32Array(numSamples);
  const right = new Float32Array(numSamples);

  const bpm = 128;
  const beatDur = 60 / bpm; // ~0.46875s

  function addSample(idx, lVal, rVal) {
    if (idx >= 0 && idx < numSamples) {
      left[idx] += lVal;
      right[idx] += rVal;
    }
  }

  // Helper: Kick drum at time t0
  function addKick(t0, vol = 0.55) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(0.22 * sampleRate);
    let phase = 0;
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const freq = 48 + 130 * Math.exp(-t * 32);
      phase += (2 * Math.PI * freq) / sampleRate;
      const env = Math.exp(-t * 14);
      const click = Math.exp(-t * 180) * 0.3;
      const s = (Math.sin(phase) * env + click) * vol;
      addSample(start + i, s, s);
    }
  }

  // Helper: Clap / Snare at time t0
  function addClap(t0, vol = 0.25) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(0.14 * sampleRate);
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const env = Math.exp(-t * 26);
      const noise = (Math.random() * 2 - 1) * env * vol;
      addSample(start + i, noise * 1.05, noise * 0.95);
    }
  }

  // Helper: Hi-hat at time t0
  function addHat(t0, vol = 0.12, open = false) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor((open ? 0.18 : 0.05) * sampleRate);
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const env = Math.exp(-t * (open ? 18 : 65));
      // High-frequency metallic noise
      const n = ((Math.random() * 2 - 1) - (Math.random() * 2 - 1)) * 0.5;
      const s = n * env * vol;
      addSample(start + i, s * 0.9, s * 1.1);
    }
  }

  // Helper: Pluck / Synth Bass note
  function addBassNote(t0, dur, freq, vol = 0.24) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(dur * sampleRate);
    let phase = 0;
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      phase += (2 * Math.PI * freq) / sampleRate;
      const env = Math.min(1, t * 80) * Math.exp(-t * 6.5);
      // Saw + Sub sine
      const saw = 2 * ((phase / (2 * Math.PI)) - Math.floor(0.5 + phase / (2 * Math.PI)));
      const sub = Math.sin(phase);
      const s = (sub * 0.7 + saw * 0.3) * env * vol;
      addSample(start + i, s, s);
    }
  }

  // Helper: Neon Lead Synth Chord/Arp
  function addSynthNote(t0, dur, freq, vol = 0.12, pan = 0) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(dur * sampleRate);
    let p1 = 0, p2 = 0;
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      p1 += (2 * Math.PI * freq) / sampleRate;
      p2 += (2 * Math.PI * (freq * 1.006)) / sampleRate;
      const env = Math.min(1, t * 45) * Math.exp(-t * 4.5);
      const val = (Math.sin(p1) + 0.5 * Math.sin(p2 * 2)) * env * vol;
      addSample(start + i, val * (1 - pan * 0.4), val * (1 + pan * 0.4));
    }
  }

  // Helper: Whoosh / Impact Slam
  function addSlam(t0, vol = 0.5) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(0.45 * sampleRate);
    let phase = 0;
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const freq = 160 * Math.exp(-t * 9) + 32;
      phase += (2 * Math.PI * freq) / sampleRate;
      const env = Math.exp(-t * 7);
      const noise = (Math.random() * 2 - 1) * Math.exp(-t * 16) * 0.35;
      const s = (Math.sin(phase) * 0.8 + noise) * env * vol;
      addSample(start + i, s, s);
    }
  }

  // Helper: Bottle Spin Tick
  function addTick(t0, pitch = 900, vol = 0.25) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(0.03 * sampleRate);
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const env = Math.exp(-t * 140);
      const s = Math.sin(2 * Math.PI * pitch * t) * env * vol;
      addSample(start + i, s, s);
    }
  }

  // Helper: Wobbly Boing / Bend Lock SFX
  function addWobbleBoing(t0, vol = 0.38) {
    const start = Math.floor(t0 * sampleRate);
    const len = Math.floor(0.55 * sampleRate);
    let phase = 0;
    for (let i = 0; i < len; i++) {
      const t = i / sampleRate;
      const wobble = Math.sin(2 * Math.PI * 18 * t) * 85 * Math.exp(-t * 3);
      const freq = 320 + t * 260 + wobble;
      phase += (2 * Math.PI * freq) / sampleRate;
      const env = Math.exp(-t * 4.5);
      const s = Math.sin(phase) * env * vol;
      addSample(start + i, s, s);
    }
  }

  // Helper: Pop Chime (for object morphs)
  function addPopChime(t0, baseFreq = 523.25, vol = 0.3) {
    addSynthNote(t0, 0.22, baseFreq, vol, -0.3);
    addSynthNote(t0 + 0.04, 0.28, baseFreq * 1.25, vol, 0.3);
    addSynthNote(t0 + 0.08, 0.35, baseFreq * 1.5, vol, 0.0);
  }

  // 1. Lay down 128 BPM Party Beat across 16 seconds
  const totalBeats = Math.floor(DURATION / beatDur);
  const bassNotes = [65.41, 65.41, 77.78, 87.31, 65.41, 65.41, 98.00, 87.31]; // C2, Eb2, F2, G2
  const arpNotes = [261.63, 311.13, 349.23, 392.00, 523.25, 392.00, 349.23, 311.13];

  for (let b = 0; b < totalBeats; b++) {
    const t = b * beatDur;
    addKick(t, 0.52);
    if (b % 2 === 1) {
      addClap(t, 0.26);
    }
    addHat(t + beatDur * 0.5, 0.14, true);
    addHat(t + beatDur * 0.25, 0.07, false);
    addHat(t + beatDur * 0.75, 0.07, false);

    // Offbeat bass + onbeat sub
    const bf = bassNotes[b % bassNotes.length];
    addBassNote(t, beatDur * 0.45, bf, 0.24);
    addBassNote(t + beatDur * 0.5, beatDur * 0.45, bf * 2, 0.18);

    // Melodic party arp every 1/2 beat
    const af1 = arpNotes[(b * 2) % arpNotes.length];
    const af2 = arpNotes[(b * 2 + 1) % arpNotes.length];
    addSynthNote(t, beatDur * 0.4, af1, 0.09, -0.4);
    addSynthNote(t + beatDur * 0.5, beatDur * 0.4, af2, 0.09, 0.4);
  }

  // 2. Synced Visual SFX!
  // Act 1 Hook Slams
  addSlam(0.15, 0.55);
  addSlam(1.25, 0.55);
  addSlam(2.50, 0.50);

  // Act 2 Bottle Spin Ticks (2.85s -> 5.10s)
  let spinT = 2.85;
  let interval = 0.045;
  let pitch = 1250;
  while (spinT < 5.05) {
    addTick(spinT, pitch, 0.28);
    spinT += interval;
    interval *= 1.095;
    pitch = Math.max(550, pitch - 22);
  }
  // Bottle Bends & Locks onto Selin at 5.15s!
  addWobbleBoing(5.15, 0.42);
  addPopChime(5.25, 587.33, 0.28);

  // Act 3 Object Morphs (6.2s, 6.85s, 7.5s, 8.15s) & Packs (8.8s)
  addPopChime(6.25, 523.25, 0.28);
  addPopChime(6.90, 587.33, 0.28);
  addPopChime(7.55, 659.25, 0.28);
  addPopChime(8.20, 783.99, 0.32);
  addSlam(8.85, 0.48);

  // Act 4 Spicy Card Flip & Slam (9.8s, 10.3s)
  addSlam(9.85, 0.55);
  addPopChime(10.25, 698.46, 0.32);

  // Act 5 Outro CTA Fanfare (13.0s, 13.8s)
  addSlam(13.00, 0.55);
  addPopChime(13.15, 523.25, 0.35);
  addPopChime(13.85, 659.25, 0.35);

  // Fade out last 0.4s
  const fadeSamples = Math.floor(0.4 * sampleRate);
  for (let i = 0; i < fadeSamples; i++) {
    const idx = numSamples - 1 - i;
    const f = i / fadeSamples;
    left[idx] *= f;
    right[idx] *= f;
  }

  // Encode 16-bit PCM Stereo WAV
  const buffer = Buffer.alloc(44 + numSamples * 4);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + numSamples * 4, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); // PCM
  buffer.writeUInt16LE(2, 22); // Stereo
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 4, 28);
  buffer.writeUInt16LE(4, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(numSamples * 4, 40);

  let offset = 44;
  for (let i = 0; i < numSamples; i++) {
    const l = Math.max(-0.98, Math.min(0.98, left[i]));
    const r = Math.max(-0.98, Math.min(0.98, right[i]));
    buffer.writeInt16LE(Math.floor(l * 32767), offset);
    buffer.writeInt16LE(Math.floor(r * 32767), offset + 2);
    offset += 4;
  }

  fs.writeFileSync(wavPath, buffer);
  console.log('Synthesized audio WAV:', wavPath);
}

// ============================================================================
// 2. HTML5 CANVAS 1080x1920 60FPS DETERMINISTIC ANIMATION PAGE
// ============================================================================
function getAnimatorHtml() {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { margin: 0; background: #000; overflow: hidden; }
  canvas { width: 1080px; height: 1920px; display: block; }
</style>
</head>
<body>
<canvas id="c" width="1080" height="1920"></canvas>
<script>
const W = 1080, H = 1920;
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');

const assetList = {
  bg: '/assets/game_bg.png',
  icon: '/assets/app_icon.png',
  packs: '/assets/pack_sheet.png',
  b0_0: '/assets/bent_0_0.png',
  b0_l: '/assets/bent_0_l.png',
  b0_r: '/assets/bent_0_r.png',
  b1_0: '/assets/bent_1_0.png',
  b2_0: '/assets/bent_2_0.png',
  b3_0: '/assets/bent_3_0.png',
  b4_0: '/assets/bent_4_0.png',
};

const imgs = {};

function loadAllImages() {
  return Promise.all(Object.entries(assetList).map(([k, url]) => {
    return new Promise((resolve, reject) => {
      const im = new Image();
      im.onload = () => { imgs[k] = im; resolve(); };
      im.onerror = reject;
      im.src = url;
    });
  }));
}

// Easing functions
function easeOutBack(x) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
}
function easeOutCubic(x) {
  return 1 - Math.pow(1 - x, 3);
}
function easeInOutCubic(x) {
  return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
}
function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}

// Pre-seeded deterministic particles
const particles = [];
for (let i = 0; i < 85; i++) {
  particles.push({
    x: (Math.sin(i * 78.233) * 0.5 + 0.5) * W,
    y: (Math.cos(i * 45.164) * 0.5 + 0.5) * H,
    r: 3 + (i % 7) * 2.2,
    vy: -60 - (i % 5) * 45,
    vx: Math.sin(i * 12.3) * 35,
    color: ['#00F2FE', '#FF0844', '#FFCC00', '#BF4FFF', '#34C759'][i % 5],
    phase: i * 0.7
  });
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function drawNeonText(text, x, y, size, color, glowColor, glowBlur = 28, align = 'center') {
  ctx.save();
  ctx.font = '900 ' + size + 'px "Segoe UI", Arial, sans-serif';
  ctx.textAlign = align;
  ctx.textBaseline = 'middle';
  ctx.shadowColor = glowColor || color;
  ctx.shadowBlur = glowBlur;
  ctx.lineWidth = Math.max(4, size * 0.11);
  ctx.strokeStyle = 'rgba(0,0,0,0.85)';
  ctx.strokeText(text, x, y);
  ctx.fillStyle = color;
  ctx.fillText(text, x, y);
  ctx.restore();
}

function drawTapRipple(x, y, progress) {
  if (progress <= 0 || progress >= 1) return;
  ctx.save();
  for (let k = 0; k < 2; k++) {
    const p = clamp(progress - k * 0.18, 0, 1);
    if (p <= 0) continue;
    ctx.beginPath();
    ctx.arc(x, y, 25 + p * 140, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255, 204, 0, ' + ((1 - p) * 0.9) + ')';
    ctx.lineWidth = 8 * (1 - p);
    ctx.stroke();
  }
  // Glowing pointer circle
  const tapScale = 1 - 0.25 * Math.sin(progress * Math.PI);
  ctx.beginPath();
  ctx.arc(x, y, 36 * tapScale, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(255, 255, 255, ' + ((1 - progress * 0.5) * 0.85) + ')';
  ctx.shadowColor = '#FFCC00';
  ctx.shadowBlur = 30;
  ctx.fill();
  ctx.restore();
}

function renderFrame(t) {
  ctx.save();
  ctx.clearRect(0, 0, W, H);

  // Beat pulse (128 BPM)
  const beatPos = (t * (128 / 60)) % 1;
  const beatPulse = Math.exp(-beatPos * 6);

  // Camera shake on major impacts
  let shakeX = 0, shakeY = 0;
  const impacts = [0.15, 1.25, 2.50, 5.15, 8.85, 9.85, 13.00];
  for (const imp of impacts) {
    const dt = t - imp;
    if (dt >= 0 && dt < 0.28) {
      const mag = (1 - dt / 0.28) * 22;
      shakeX += Math.sin(t * 190) * mag;
      shakeY += Math.cos(t * 230) * mag;
    }
  }
  ctx.translate(shakeX, shakeY);

  // 1. Animated Background with slow zoom & beat glow
  const bgScale = 1.06 + 0.04 * Math.sin(t * 0.8) + beatPulse * 0.015;
  ctx.save();
  ctx.translate(W / 2, H / 2);
  ctx.scale(bgScale, bgScale);
  ctx.drawImage(imgs.bg, -W / 2, -H / 2, W, H);
  ctx.restore();

  // Dark vignette & neon radial pulse
  const grad = ctx.createRadialGradient(W / 2, H / 2, 120, W / 2, H / 2, 1100);
  grad.addColorStop(0, 'rgba(5, 12, 28, 0.52)');
  grad.addColorStop(1, 'rgba(2, 4, 12, 0.88)');
  ctx.fillStyle = grad;
  ctx.fillRect(-40, -40, W + 80, H + 80);

  // Floating glowing particles
  for (const p of particles) {
    const py = ((p.y + p.vy * t) % H + H) % H;
    const px = ((p.x + p.vx * t + Math.sin(t * 2 + p.phase) * 30) % W + W) % W;
    ctx.save();
    ctx.beginPath();
    ctx.arc(px, py, p.r * (0.8 + 0.4 * beatPulse), 0, Math.PI * 2);
    ctx.fillStyle = p.color;
    ctx.shadowColor = p.color;
    ctx.shadowBlur = 18;
    ctx.globalAlpha = 0.55;
    ctx.fill();
    ctx.restore();
  }

  // ==========================================================================
  // ACT 1 (0.0s - 2.5s): HOOK ("ORTAM ÇOK MU SESSİZ? ŞİŞEYİ ÇEVİR, PARTİYİ ATEŞLE!")
  // ==========================================================================
  if (t < 2.55) {
    // Shockwave rings from center
    for (let r = 0; r < 3; r++) {
      const rp = ((t * 1.1 + r * 0.33) % 1);
      ctx.save();
      ctx.beginPath();
      ctx.arc(W / 2, H * 0.48, 80 + rp * 550, 0, Math.PI * 2);
      ctx.strokeStyle = r % 2 === 0
        ? 'rgba(0, 242, 254, ' + ((1 - rp) * 0.45) + ')'
        : 'rgba(255, 8, 68, ' + ((1 - rp) * 0.45) + ')';
      ctx.lineWidth = 6 * (1 - rp);
      ctx.stroke();
      ctx.restore();
    }

    // Center Wobbling Bottle bursting in
    const entryP = clamp((t - 0.05) / 0.45, 0, 1);
    const bScale = easeOutBack(entryP) * (1 + beatPulse * 0.06);
    const wobbleAng = Math.sin(t * 11) * 0.24;
    const bendImg = wobbleAng < -0.08 ? imgs.b0_l : (wobbleAng > 0.08 ? imgs.b0_r : imgs.b0_0);

    ctx.save();
    ctx.translate(W / 2, H * 0.48);
    ctx.scale(bScale, bScale);
    ctx.rotate(wobbleAng);
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 55;
    ctx.drawImage(bendImg, -260, -260, 520, 520);
    ctx.restore();

    // First Headline (0.1s - 1.25s)
    if (t < 1.25) {
      const p1 = easeOutBack(clamp((t - 0.1) / 0.3, 0, 1));
      ctx.save();
      ctx.translate(W / 2, H * 0.19);
      ctx.scale(p1, p1);
      drawNeonText('SIKICI ORTAMLARI', 0, -45, 76, '#FFFFFF', '#00F2FE', 35);
      drawNeonText('UNUT! 🔥', 0, 50, 96, '#FFCC00', '#FF0844', 40);
      ctx.restore();
    } else {
      // Second Headline (1.25s - 2.55s)
      const p2 = easeOutBack(clamp((t - 1.25) / 0.3, 0, 1));
      ctx.save();
      ctx.translate(W / 2, H * 0.19);
      ctx.scale(p2, p2);
      drawNeonText('ŞİŞEYİ ÇEVİR,', 0, -45, 80, '#00F2FE', '#00F2FE', 35);
      drawNeonText('PARTİYİ ATEŞLE! 🎉', 0, 50, 82, '#FF0844', '#FF0844', 40);
      ctx.restore();
    }

    // Bottom badge
    const bp = easeOutCubic(clamp((t - 0.3) / 0.4, 0, 1));
    ctx.save();
    ctx.globalAlpha = bp;
    roundRect(ctx, W / 2 - 360, H * 0.78, 720, 110, 55);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.9)';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = '#FFCC00';
    ctx.stroke();
    drawNeonText('WOBBLY BOTTLE: PARTY GAME', W / 2, H * 0.78 + 55, 42, '#FFCC00', '#FFCC00', 20);
    ctx.restore();
  }

  // ==========================================================================
  // ACT 2 (2.55s - 6.20s): LIVE ARENA SPIN & BEND TOWARDS PLAYER!
  // ==========================================================================
  else if (t >= 2.55 && t < 6.20) {
    const lt = t - 2.55;
    const isLocked = t >= 5.15;

    // Camera zoom in when bottle locks onto Selin!
    const camZoom = isLocked
      ? 1.0 + 0.12 * easeOutBack(clamp((t - 5.15) / 0.35, 0, 1))
      : 1.0;

    ctx.save();
    ctx.translate(W / 2, H * 0.46);
    ctx.scale(camZoom, camZoom);
    ctx.translate(-W / 2, -H * 0.46);

    // Top Header Banner
    drawNeonText('ŞİŞE KİME BÜKÜLECEK? 👀', W / 2, 165, 62, '#FFCC00', '#FFCC00', 28);

    const cx = W / 2, cy = H * 0.46;
    const radius = 355;

    // Glowing Arena Connecting Circle
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.strokeStyle = isLocked ? 'rgba(255, 8, 68, 0.65)' : 'rgba(0, 242, 254, 0.45)';
    ctx.lineWidth = 6;
    ctx.shadowColor = isLocked ? '#FF0844' : '#00F2FE';
    ctx.shadowBlur = 25;
    ctx.stroke();
    ctx.restore();

    // 6 Players around the ring
    // Index 1 (Top-Right: SELİN = Answerer), Index 4 (Bottom-Left: MERT = Questioner)
    const players = [
      { name: 'BURAK', color: '#00F2FE' },
      { name: 'SELİN', color: '#FF0844' },
      { name: 'ZEYNEP', color: '#FF9500' },
      { name: 'CAN', color: '#AF52DE' },
      { name: 'MERT', color: '#FFCC00' },
      { name: 'ELİF', color: '#34C759' },
    ];

    // If locked, draw glowing laser beam between MERT (idx 4) and SELİN (idx 1)
    if (isLocked) {
      const aQ = -Math.PI / 2 + (4 * 2 * Math.PI / 6);
      const aA = -Math.PI / 2 + (1 * 2 * Math.PI / 6);
      const qx = cx + radius * Math.cos(aQ), qy = cy + radius * Math.sin(aQ);
      const ax = cx + radius * Math.cos(aA), ay = cy + radius * Math.sin(aA);

      ctx.save();
      ctx.beginPath();
      ctx.moveTo(qx, qy);
      ctx.lineTo(cx, cy);
      ctx.lineTo(ax, ay);
      ctx.strokeStyle = '#FF0844';
      ctx.lineWidth = 10;
      ctx.shadowColor = '#FF0844';
      ctx.shadowBlur = 35;
      ctx.stroke();
      ctx.restore();
    }

    for (let i = 0; i < 6; i++) {
      const ang = -Math.PI / 2 + (i * 2 * Math.PI / 6);
      const px = cx + radius * Math.cos(ang);
      const py = cy + radius * Math.sin(ang);
      const isA = isLocked && i === 1;
      const isQ = isLocked && i === 4;
      const pScale = (isA || isQ) ? 1.25 + 0.08 * Math.sin(t * 16) : 1.0;

      ctx.save();
      ctx.translate(px, py);
      ctx.scale(pScale, pScale);

      // Avatar circle
      ctx.beginPath();
      ctx.arc(0, 0, 56, 0, Math.PI * 2);
      ctx.fillStyle = players[i].color;
      ctx.shadowColor = isA ? '#FF0844' : (isQ ? '#00F2FE' : players[i].color);
      ctx.shadowBlur = (isA || isQ) ? 40 : 15;
      ctx.fill();
      ctx.lineWidth = (isA || isQ) ? 7 : 4;
      ctx.strokeStyle = '#FFFFFF';
      ctx.stroke();

      // Smiley icon inside avatar
      ctx.fillStyle = '#050817';
      ctx.beginPath();
      ctx.arc(-16, -10, 6, 0, Math.PI * 2);
      ctx.arc(16, -10, 6, 0, Math.PI * 2);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(0, 4, 22, 0.15 * Math.PI, 0.85 * Math.PI);
      ctx.lineWidth = 5;
      ctx.strokeStyle = '#050817';
      ctx.stroke();

      // Player Name Pill
      roundRect(ctx, -85, 66, 170, 44, 14);
      ctx.fillStyle = isA ? '#FF0844' : (isQ ? '#00F2FE' : 'rgba(10, 24, 40, 0.9)');
      ctx.fill();
      drawNeonText(players[i].name, 0, 88, 28, (isQ ? '#000' : '#FFF'), '#000', 8);

      if (isA) {
        roundRect(ctx, -110, -110, 220, 42, 12);
        ctx.fillStyle = '#FF0844';
        ctx.fill();
        drawNeonText('🎯 HEDEF!', 0, -89, 26, '#FFFFFF', '#FF0844', 12);
      } else if (isQ) {
        roundRect(ctx, -100, -110, 200, 42, 12);
        ctx.fillStyle = '#00F2FE';
        ctx.fill();
        drawNeonText('🗣️ SORAN', 0, -89, 26, '#000000', '#00F2FE', 10);
      }
      ctx.restore();
    }

    // Center Bottle Spin Physics
    let bottleAngle = 0;
    let bottleImg = imgs.b0_0;
    const targetAngle = -Math.PI / 2 + (1 * 2 * Math.PI / 6) + Math.PI / 2 + 0.18;

    if (t < 2.85) {
      bottleAngle = 0;
    } else if (t < 5.15) {
      const sp = clamp((t - 2.85) / 2.30, 0, 1);
      const eased = 1 - Math.pow(1 - sp, 3.2);
      bottleAngle = eased * (Math.PI * 2 * 5 + targetAngle);
      const cyc = Math.sin(sp * 38);
      bottleImg = cyc < -0.25 ? imgs.b0_l : (cyc > 0.25 ? imgs.b0_r : imgs.b0_0);
    } else {
      bottleAngle = targetAngle;
      bottleImg = imgs.b0_r; // Bends visibly towards SELİN!
    }

    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(bottleAngle);
    ctx.shadowColor = isLocked ? '#FF0844' : '#00F2FE';
    ctx.shadowBlur = isLocked ? 55 : 35;
    const bBounce = isLocked ? 1 + 0.08 * Math.sin((t - 5.15) * 22) * Math.exp(-(t - 5.15) * 3) : 1;
    ctx.scale(bBounce, bBounce);
    ctx.drawImage(bottleImg, -210, -210, 420, 420);
    ctx.restore();

    ctx.restore(); // End Arena camZoom

    // Bottom Control Card
    ctx.save();
    roundRect(ctx, 70, 1430, W - 140, 340, 38);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.94)';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = isLocked ? '#FF0844' : '#00F2FE';
    ctx.stroke();

    if (!isLocked) {
      drawNeonText('PARMAĞINLA DOKUN VE ÇEVİR!', W / 2, 1520, 40, '#00F2FE', '#00F2FE', 18);
      roundRect(ctx, 130, 1590, W - 260, 125, 32);
      ctx.fillStyle = '#FFCC00';
      ctx.shadowColor = '#FFCC00';
      ctx.shadowBlur = 30;
      ctx.fill();
      ctx.shadowBlur = 0;
      drawNeonText(t < 2.85 ? 'ŞİŞEYİ ÇEVİR!' : 'ŞİŞE DÖNÜYOR...', W / 2, 1652, 52, '#000000', '#FFCC00', 0);

      // Tap animation at 2.65s - 3.05s
      drawTapRipple(W / 2 + 120, 1652, (t - 2.62) / 0.45);
    } else {
      drawNeonText('SORAN: MERT   ➔   CEVAPLAYAN: SELİN', W / 2, 1500, 36, '#FFCC00', '#000', 10);
      drawNeonText('ŞİŞE BÜKÜLDÜ! SEÇİMİNİ YAP:', W / 2, 1565, 44, '#FFFFFF', '#FF0844', 20);

      // Truth & Dare Buttons
      roundRect(ctx, 110, 1620, 400, 110, 26);
      ctx.fillStyle = '#00F2FE';
      ctx.fill();
      drawNeonText('DOĞRULUK', 310, 1675, 44, '#000000', '#00F2FE', 0);

      roundRect(ctx, 570, 1620, 400, 110, 26);
      ctx.fillStyle = '#FF0844';
      ctx.shadowColor = '#FF0844';
      ctx.shadowBlur = 30;
      ctx.fill();
      ctx.shadowBlur = 0;
      drawNeonText('CESARET 🔥', 770, 1675, 44, '#FFFFFF', '#000', 8);
    }
    ctx.restore();
  }

  // ==========================================================================
  // ACT 3 (6.20s - 9.80s): 5 WOBBLY OBJECTS & 6 PARTY PACKS SHOWCASE!
  // ==========================================================================
  else if (t >= 6.20 && t < 9.80) {
    if (t < 8.75) {
      // Rapid Object Morph Showcase (6.20s - 8.75s)
      const objects = [
        { img: imgs.b1_0, title: 'BİPLEYEN TAVUK 🐔', sub: 'KİLİTLERİ AÇ, KAHKAHAYI PATLAT!', col: '#FF9500' },
        { img: imgs.b2_0, title: 'SALLANAN MUZ 🍌', sub: '5 EFSANE BÜKÜLEN NESNE!', col: '#FFCC00' },
        { img: imgs.b3_0, title: 'UÇAN TERLİK 🩴', sub: 'HEDEFTEN KAÇIŞ YOK!', col: '#00F2FE' },
        { img: imgs.b4_0, title: 'ALTIN ŞAMPANYA 👑', sub: 'WOBBLY VIP ÖZEL ŞİŞESİ!', col: '#FFCC00' },
      ];
      const idx = clamp(Math.floor((t - 6.20) / 0.63), 0, 3);
      const localP = ((t - 6.20) % 0.63) / 0.63;
      const cur = objects[idx];

      drawNeonText('SIRADAN ŞİŞELERİ UNUT!', W / 2, 200, 64, '#00F2FE', '#00F2FE', 30);
      drawNeonText(cur.sub, W / 2, 290, 42, '#FFFFFF', cur.col, 20);

      // Glowing burst behind object
      const popScale = easeOutBack(clamp(localP * 2.4, 0, 1));
      ctx.save();
      ctx.translate(W / 2, H * 0.50);
      ctx.scale(popScale, popScale);

      ctx.beginPath();
      ctx.arc(0, 0, 290, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(10, 24, 40, 0.85)';
      ctx.shadowColor = cur.col;
      ctx.shadowBlur = 65;
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = cur.col;
      ctx.stroke();

      ctx.rotate(Math.sin(t * 14) * 0.22);
      ctx.drawImage(cur.img, -250, -250, 500, 500);
      ctx.restore();

      // Object Name Card
      ctx.save();
      roundRect(ctx, W / 2 - 390, H * 0.76, 780, 130, 35);
      ctx.fillStyle = 'rgba(15, 23, 42, 0.95)';
      ctx.fill();
      ctx.lineWidth = 5;
      ctx.strokeStyle = cur.col;
      ctx.stroke();
      drawNeonText(cur.title, W / 2, H * 0.76 + 65, 58, cur.col, cur.col, 25);
      ctx.restore();
    } else {
      // 6 Party Packs Grid Showcase (8.75s - 9.80s)
      const pt = t - 8.75;
      drawNeonText('6 FARKLI PARTİ PAKETİ! 🔥', W / 2, 175, 66, '#FFCC00', '#FF0844', 32);
      drawNeonText('PARTİ • İTİRAF • CESARET • FLÖRT • +18 VIP', W / 2, 255, 36, '#00F2FE', '#00F2FE', 18);

      const packNames = [
        'PARTİ & EĞLENCE', 'DERİN İTİRAFLAR',
        'CESUR GÖREVLER', 'FLÖRT & ÇİFTLER',
        '💋 +18 BAHARATLI', 'SERBEST MOD'
      ];
      const cellW = imgs.packs.width / 2;
      const cellH = imgs.packs.height / 3;

      for (let i = 0; i < 6; i++) {
        const col = i % 2;
        const row = Math.floor(i / 2);
        const cardW = 430, cardH = 420;
        const gx = col === 0 ? 85 : 565;
        const gy = 330 + row * 460;

        const entry = easeOutBack(clamp((pt - i * 0.06) / 0.35, 0, 1));
        const isSpicy = i === 4;

        ctx.save();
        ctx.translate(gx + cardW / 2, gy + cardH / 2);
        const scaleBoost = isSpicy ? entry * (1.06 + 0.04 * Math.sin(t * 20)) : entry;
        ctx.scale(scaleBoost, scaleBoost);
        ctx.translate(-cardW / 2, -cardH / 2);

        roundRect(ctx, 0, 0, cardW, cardH, 28);
        ctx.fillStyle = '#0A1828';
        ctx.shadowColor = isSpicy ? '#FF0844' : '#00F2FE';
        ctx.shadowBlur = isSpicy ? 40 : 18;
        ctx.fill();
        ctx.shadowBlur = 0;

        ctx.save();
        roundRect(ctx, 0, 0, cardW, cardH - 76, 28);
        ctx.clip();
        ctx.drawImage(imgs.packs, col * cellW, row * cellH, cellW, cellH, 0, 0, cardW, cardH - 76);
        ctx.restore();

        roundRect(ctx, 0, 0, cardW, cardH, 28);
        ctx.lineWidth = isSpicy ? 6 : 3.5;
        ctx.strokeStyle = isSpicy ? '#FF0844' : '#FFCC00';
        ctx.stroke();

        drawNeonText(packNames[i], cardW / 2, cardH - 38, 30, isSpicy ? '#FFCC00' : '#FFFFFF', '#000', 10);
        ctx.restore();
      }
    }
  }

  // ==========================================================================
  // ACT 4 (9.80s - 13.00s): SPICY QUESTION CARD REVEAL!
  // ==========================================================================
  else if (t >= 9.80 && t < 13.00) {
    const ct = t - 9.80;
    const cardScale = easeOutBack(clamp(ct / 0.42, 0, 1));

    drawNeonText('SIRLAR ORTAYA ÇIKIYOR! 😈', W / 2, 230, 66, '#FF0844', '#FF0844', 35);
    drawNeonText('CESARET Mİ, İTİRAF MI?', W / 2, 320, 48, '#FFCC00', '#FFCC00', 22);

    ctx.save();
    ctx.translate(W / 2, H * 0.54);
    ctx.scale(cardScale, cardScale);

    // Glowing 3D Question Card
    roundRect(ctx, -450, -430, 900, 860, 48);
    ctx.fillStyle = 'rgba(15, 20, 38, 0.96)';
    ctx.shadowColor = '#FF0844';
    ctx.shadowBlur = 65;
    ctx.fill();
    ctx.lineWidth = 8;
    ctx.strokeStyle = '#FF0844';
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Top Badge inside Card
    roundRect(ctx, -320, -360, 640, 86, 26);
    ctx.fillStyle = 'rgba(255, 8, 68, 0.22)';
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#FFCC00';
    ctx.stroke();
    drawNeonText('🔥 SELİN İÇİN CESARET (+18 VIP)', 0, -317, 36, '#FFCC00', '#FF0844', 15);

    // Inner Question Box
    roundRect(ctx, -390, -220, 780, 430, 34);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.55)';
    ctx.fill();

    const lines = [
      '"Masadaki birinin gözlerinin',
      'içine bakarak 15 saniye boyunca',
      'en büyük sırrını itiraf et...',
      'Ya da telefonundaki son mesajı',
      'herkese sesli oku! 🔥💋"'
    ];
    for (let l = 0; l < lines.length; l++) {
      drawNeonText(lines[l], 0, -135 + l * 72, 42, '#FFFFFF', '#00F2FE', 12);
    }

    // Bottom Next Round Button
    roundRect(ctx, -310, 265, 620, 110, 30);
    ctx.fillStyle = '#00F2FE';
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 30;
    ctx.fill();
    ctx.shadowBlur = 0;
    drawNeonText('TAMAM / SIRADAKİ TUR ➔', 0, 320, 40, '#000000', '#00F2FE', 0);

    ctx.restore();
  }

  // ==========================================================================
  // ACT 5 (13.00s - 16.00s): CALL TO ACTION OUTRO (APP STORE & GOOGLE PLAY)
  // ==========================================================================
  else {
    const ot = t - 13.00;
    const pop = easeOutBack(clamp(ot / 0.45, 0, 1));

    // App Icon + Wobbling Bottle
    ctx.save();
    ctx.translate(W / 2, 410);
    ctx.scale(pop, pop);

    ctx.beginPath();
    ctx.arc(0, 0, 195, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.9)';
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 60;
    ctx.fill();
    ctx.lineWidth = 7;
    ctx.strokeStyle = '#00F2FE';
    ctx.stroke();

    ctx.rotate(Math.sin(t * 9) * 0.16);
    ctx.drawImage(imgs.b0_0, -165, -165, 330, 330);
    ctx.restore();

    drawNeonText('WOBBLY BOTTLE', W / 2, 700, 92, '#FFCC00', '#FFCC00', 38);
    drawNeonText('DOĞRULUK MU CESARET Mİ PARTİ OYUNU', W / 2, 790, 40, '#00F2FE', '#00F2FE', 20);

    // CTA Headline
    const pulseScale = 1 + 0.04 * Math.sin(t * 14);
    ctx.save();
    ctx.translate(W / 2, 935);
    ctx.scale(pulseScale, pulseScale);
    drawNeonText('HEMEN ÜCRETSİZ İNDİR! 👇', 0, 0, 64, '#FFFFFF', '#FF0844', 35);
    ctx.restore();

    // App Store Button
    const b1 = easeOutBack(clamp((ot - 0.15) / 0.4, 0, 1));
    ctx.save();
    ctx.translate(W / 2, 1140);
    ctx.scale(b1, b1);
    roundRect(ctx, -410, -85, 820, 170, 38);
    ctx.fillStyle = '#0D1829';
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 35;
    ctx.fill();
    ctx.lineWidth = 6;
    ctx.strokeStyle = '#00F2FE';
    ctx.stroke();
    ctx.shadowBlur = 0;
    drawNeonText("🍎  App Store'dan İndir", 0, 0, 54, '#FFFFFF', '#00F2FE', 15);
    ctx.restore();

    // Google Play Button
    const b2 = easeOutBack(clamp((ot - 0.30) / 0.4, 0, 1));
    ctx.save();
    ctx.translate(W / 2, 1365);
    ctx.scale(b2, b2);
    roundRect(ctx, -410, -85, 820, 170, 38);
    ctx.fillStyle = '#190D24';
    ctx.shadowColor = '#FF0844';
    ctx.shadowBlur = 35;
    ctx.fill();
    ctx.lineWidth = 6;
    ctx.strokeStyle = '#FF0844';
    ctx.stroke();
    ctx.shadowBlur = 0;
    drawNeonText("▶️  Google Play'den İndir", 0, 0, 54, '#FFFFFF', '#FF0844', 15);
    ctx.restore();

    // Link in Bio pill
    const b3 = easeOutCubic(clamp((ot - 0.50) / 0.4, 0, 1));
    ctx.save();
    ctx.globalAlpha = b3;
    roundRect(ctx, W / 2 - 370, 1550, 740, 105, 52);
    ctx.fillStyle = '#FFCC00';
    ctx.shadowColor = '#FFCC00';
    ctx.shadowBlur = 30;
    ctx.fill();
    ctx.shadowBlur = 0;
    drawNeonText("🔗 LİNK PROFİLDE (BİO'DA)!", W / 2, 1602, 44, '#000000', '#FFCC00', 0);
    ctx.restore();

    drawTapRipple(W / 2 + 180, 1140, (ot - 0.85) / 0.5);
    drawTapRipple(W / 2 + 180, 1365, (ot - 1.45) / 0.5);
  }

  ctx.restore();
}

async function startRenderLoop() {
  await loadAllImages();
  for (let f = 0; f < ${TOTAL_FRAMES}; f++) {
    const t = f / ${FPS};
    renderFrame(t);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.94);
    await fetch('/frame?i=' + f, {
      method: 'POST',
      body: dataUrl
    });
  }
  await fetch('/done', { method: 'POST' });
}

startRenderLoop().catch(err => {
  fetch('/error?msg=' + encodeURIComponent(err.toString()), { method: 'POST' });
});
</script>
</body>
</html>`;
}

// ============================================================================
// 3. ORCHESTRATE LOCAL SERVER + HEADLESS CHROME + FFMPEG MP4 PIPELINE
// ============================================================================
async function main() {
  generateAudioWav(TEMP_WAV);

  // Start FFmpeg reading raw JPEG frames from stdin and mixing with TEMP_WAV
  const ffmpegArgs = [
    '-y',
    '-f', 'image2pipe',
    '-vcodec', 'mjpeg',
    '-framerate', String(FPS),
    '-i', '-',
    '-i', TEMP_WAV,
    '-c:v', 'libx264',
    '-preset', 'medium',
    '-crf', '18',
    '-pix_fmt', 'yuv420p',
    '-c:a', 'aac',
    '-b:a', '192k',
    '-shortest',
    '-movflags', '+faststart',
    OUTPUT_MP4
  ];

  const ffmpegProc = spawn(FFMPEG_PATH, ffmpegArgs, { stdio: ['pipe', 'ignore', 'pipe'] });
  ffmpegProc.stderr.on('data', () => {});

  let chromeProc = null;

  const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/') {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(getAnimatorHtml());
    } else if (req.method === 'GET' && req.url.startsWith('/assets/')) {
      const fileName = req.url.replace('/assets/', '');
      const filePath = path.join(ASSETS_DIR, fileName);
      if (fs.existsSync(filePath)) {
        res.writeHead(200, { 'Content-Type': 'image/png' });
        fs.createReadStream(filePath).pipe(res);
      } else {
        res.writeHead(404);
        res.end();
      }
    } else if (req.method === 'POST' && req.url.startsWith('/frame')) {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        const base64Data = body.replace(/^data:image\/jpeg;base64,/, '');
        const buf = Buffer.from(base64Data, 'base64');
        const idx = parseInt(req.url.split('=')[1], 10);
        if (idx % 120 === 0) {
          console.log('Rendered frame', idx, '/', TOTAL_FRAMES);
        }
        const ok = ffmpegProc.stdin.write(buf);
        if (!ok) {
          ffmpegProc.stdin.once('drain', () => {
            res.writeHead(200);
            res.end('ok');
          });
        } else {
          res.writeHead(200);
          res.end('ok');
        }
      });
    } else if (req.method === 'POST' && req.url === '/done') {
      console.log('All frames rendered! Finalizing MP4...');
      res.writeHead(200);
      res.end('done');
      ffmpegProc.stdin.end();
    } else if (req.method === 'POST' && req.url.startsWith('/error')) {
      console.error('Browser error:', req.url);
      res.writeHead(200);
      res.end();
      process.exit(1);
    } else {
      res.writeHead(404);
      res.end();
    }
  });

  server.listen(0, '127.0.0.1', () => {
    const port = server.address().port;
    const url = 'http://127.0.0.1:' + port + '/';
    console.log('Renderer server listening at', url);

    const profileDir = path.join(ARTIFACT_DIR, 'scratch', 'chrome_profile');
    fs.mkdirSync(profileDir, { recursive: true });
    chromeProc = spawn(CHROME_PATH, [
      '--headless=new',
      '--disable-gpu',
      '--no-sandbox',
      '--user-data-dir=' + profileDir,
      '--window-size=1080,1920',
      url
    ]);
  });

  ffmpegProc.on('close', (code) => {
    console.log('FFmpeg exited with code', code);
    try {
      fs.copyFileSync(OUTPUT_MP4, 'C:\\Users\\PC\\Desktop\\WobblyBottle_Reklam_1080p_60fps.mp4');
      console.log('Copied MP4 to Desktop!');
    } catch (_) {}
    if (chromeProc) {
      try { chromeProc.kill(); } catch (_) {}
    }
    try { fs.unlinkSync(TEMP_WAV); } catch (_) {}
    server.close();
    process.exit(code);
  });
}

main();
