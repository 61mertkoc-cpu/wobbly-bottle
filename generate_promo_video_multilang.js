const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn, execFileSync } = require('child_process');

const PROJECT_DIR = __dirname;
const ASSETS_DIR = path.join(PROJECT_DIR, 'assets');
const ARTIFACT_DIR = 'C:\\Users\\PC\\.gemini\\antigravity\\brain\\d1bcc683-775c-44a3-b7c0-2a036b060908';
const CLOUD_DANCER_MP3 = path.join(ARTIFACT_DIR, 'cloud_dancer.mp3');
const SFX_WAV = path.join(ARTIFACT_DIR, 'temp_sfx_multilang.wav');

const FFMPEG_PATH = 'C:\\Users\\PC\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-9.0-full_build\\bin\\ffmpeg.exe';
const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const FPS = 60;
const DURATION = 26.0;
const TOTAL_FRAMES = Math.round(FPS * DURATION); // 1560 frames
const SAMPLE_RATE = 44100;
const NUM_SAMPLES = Math.floor(SAMPLE_RATE * DURATION);

// ============================================================================
// LANGUAGE CONFIGURATIONS (EN, DE, ES)
// ============================================================================
const LANG_CONFIGS = {
  EN: {
    code: 'EN',
    fileName: 'WobblyBottle_Reklam_EN_1080p_60fps.mp4',
    act1_top1: 'FORGET BORING NIGHTS!',
    act1_top1_size: 68,
    act1_top2: 'PARTY TIME! 🔥',
    act1_top2_size: 86,
    act1_box1: 'SPIN THE BOTTLE,',
    act1_box1_size: 68,
    act1_box2: 'IGNITE THE PARTY! 🎉',
    act1_box2_size: 70,
    act1_badge: 'WOBBLY BOTTLE: PARTY GAME',

    act2_title_unlocked: 'WHO WILL IT PICK? 👀',
    act2_title_locked: 'TARGET: ALEX! 🎯',
    act2_title_size: 62,
    players: ['JAKE', 'CHLOE', 'MIA', 'ALEX', 'RYAN', 'EMMA'],
    role_answerer: '🎯 ANSWERER',
    role_asker: '🗣️ ASKER',
    act2_sub_unlocked: 'ADD YOUR FRIENDS & SPIN!',
    act2_sub_unlocked_size: 38,
    act2_btn_spin: '🐔 SPIN NOW!',
    act2_btn_spinning: '🐔 SPINNING...',
    act2_btn_size: 48,
    act2_pair_line: 'ASKER: EMMA   ➔   ANSWERER: ALEX',
    act2_pair_size: 36,
    act2_tod_title: 'TRUTH OR DARE?',
    act2_tod_size: 46,
    act2_truth_btn: 'TRUTH 💡',
    act2_dare_btn: 'DARE 🔥',
    act2_tod_btn_size: 42,

    act3_top1: 'SECRETS COME OUT! 😈',
    act3_top1_size: 64,
    act3_top2: 'HUNDREDS OF FUN & SPICY DARES!',
    act3_top2_size: 42,
    act3_badge: '🔥 DARE FOR ALEX (+18 VIP)',
    act3_badge_size: 36,
    act3_lines: [
      '"Look deeply into someone\'s',
      'eyes for 15 seconds and',
      'confess your biggest secret...',
      'Or read your last text',
      'message out loud! 🔥💋"'
    ],
    act3_line_size: 43,
    act3_next_btn: 'DONE / NEXT ROUND ➔',
    act3_next_size: 38,

    act4_obj_top1: '5 CRAZY SPINNING OBJECTS! 🍾',
    act4_obj_top1_size: 60,
    act4_obj_top2: 'SPIN A BOTTLE, CHICKEN OR SLIPPER!',
    act4_obj_top2_size: 36,
    objs: [
      { name: 'Funny Soda Bottle', tag: '✨ FREE', col: '#00F2FE' },
      { name: 'Squeaky Chicken 🐔', tag: '🔥 HILARIOUS', col: '#FF9500' },
      { name: 'Wobbly Pickle 🥒', tag: '😂 FUNNY', col: '#34C759' },
      { name: 'Flying Slipper 🩴', tag: '🎯 NO ESCAPE', col: '#BF4FFF' },
      { name: 'Golden Champagne 👑', tag: '👑 WOBBLY VIP', col: '#FFCC00' },
    ],
    act4_obj_name_size: 44,
    act4_obj_tag_size: 27,

    act4_pack_top1: '6 EPIC PARTY PACKS! 🔥',
    act4_pack_top1_size: 64,
    act4_pack_top2: 'HUNDREDS OF QUESTIONS FOR ANY VIBE',
    act4_pack_top2_size: 36,
    packNames: [
      'PARTY & FUN', 'DEEP CONFESSIONS',
      'BOLD DARES', 'FLIRT & COUPLES',
      '💋 +18 SPICY', 'FREE MODE'
    ],
    act4_pack_name_size: 29,

    act5_sub: 'TRUTH OR DARE PARTY GAME',
    act5_sub_size: 42,
    act5_cta: 'DOWNLOAD FREE NOW! 👇',
    act5_cta_size: 62,
    act5_ios: '🍎  Download on the App Store',
    act5_android: '▶️  Get it on Google Play',
    act5_store_size: 48
  },

  DE: {
    code: 'DE',
    fileName: 'WobblyBottle_Reklam_DE_1080p_60fps.mp4',
    act1_top1: 'VERGISS LANGWEILIGE',
    act1_top1_size: 66,
    act1_top2: 'ABENDE! 🔥',
    act1_top2_size: 86,
    act1_box1: 'DREH DIE FLASCHE,',
    act1_box1_size: 64,
    act1_box2: 'START DIE PARTY! 🎉',
    act1_box2_size: 68,
    act1_badge: 'WOBBLY BOTTLE: PARTY GAME',

    act2_title_unlocked: 'WEN TRIFFT ES? 👀',
    act2_title_locked: 'ZIEL: LEON! 🎯',
    act2_title_size: 62,
    players: ['LUKAS', 'HANNA', 'MIA', 'LEON', 'FINN', 'LENA'],
    role_answerer: '🎯 ANTWORTET',
    role_asker: '🗣️ FRAGT',
    act2_sub_unlocked: 'FREUNDE HINZUFÜGEN & DREHEN!',
    act2_sub_unlocked_size: 36,
    act2_btn_spin: '🐔 JETZT DREHEN!',
    act2_btn_spinning: '🐔 DREHT SICH...',
    act2_btn_size: 46,
    act2_pair_line: 'FRAGT: LENA   ➔   ANTWORT: LEON',
    act2_pair_size: 35,
    act2_tod_title: 'WAHRHEIT ODER PFLICHT?',
    act2_tod_size: 44,
    act2_truth_btn: 'WAHRHEIT 💡',
    act2_dare_btn: 'PFLICHT 🔥',
    act2_tod_btn_size: 40,

    act3_top1: 'GEHEIMNISSE KOMMEN RAUS! 😈',
    act3_top1_size: 56,
    act3_top2: 'HUNDERTE WITZIGE & MUTIGE AUFGABEN!',
    act3_top2_size: 38,
    act3_badge: '🔥 PFLICHT FÜR LEON (+18 VIP)',
    act3_badge_size: 35,
    act3_lines: [
      '"Schau jemandem am Tisch 15',
      'Sekunden tief in die Augen und',
      'gestehe dein größtes Geheimnis...',
      'Oder lies deine letzte Nachricht',
      'laut vor allen vor! 🔥💋"'
    ],
    act3_line_size: 41,
    act3_next_btn: 'FERTIG / NÄCHSTE RUNDE ➔',
    act3_next_size: 36,

    act4_obj_top1: '5 VERRÜCKTE OBJEKTE! 🍾',
    act4_obj_top1_size: 60,
    act4_obj_top2: 'FLASCHE, HUHN ODER HAUSSCHUH DREHEN!',
    act4_obj_top2_size: 34,
    objs: [
      { name: 'Lustige Limo-Flasche', tag: '✨ GRATIS', col: '#00F2FE' },
      { name: 'Quietsche-Huhn 🐔', tag: '🔥 WITZIG', col: '#FF9500' },
      { name: 'Wackel-Gurke 🥒', tag: '😂 LUSTIG', col: '#34C759' },
      { name: 'Fliegender Latschen 🩴', tag: '🎯 KEIN ENTKOMMEN', col: '#BF4FFF' },
      { name: 'Gold-Champagner 👑', tag: '👑 WOBBLY VIP', col: '#FFCC00' },
    ],
    act4_obj_name_size: 42,
    act4_obj_tag_size: 25,

    act4_pack_top1: '6 PARTY-PAKETE! 🔥',
    act4_pack_top1_size: 64,
    act4_pack_top2: 'HUNDERTE FRAGEN FÜR JEDE RUNDE',
    act4_pack_top2_size: 36,
    packNames: [
      'PARTY & SPASS', 'TIEFE BEICHTEN',
      'MUTIGE PFLICHTEN', 'FLIRT & PAARE',
      '💋 +18 SCHARF', 'FREIER MODUS'
    ],
    act4_pack_name_size: 28,

    act5_sub: 'WAHRHEIT ODER PFLICHT PARTYSPIEL',
    act5_sub_size: 40,
    act5_cta: 'JETZT GRATIS LADEN! 👇',
    act5_cta_size: 60,
    act5_ios: '🍎  Laden im App Store',
    act5_android: '▶️  Jetzt bei Google Play',
    act5_store_size: 52
  },

  ES: {
    code: 'ES',
    fileName: 'WobblyBottle_Reklam_ES_1080p_60fps.mp4',
    act1_top1: '¡OLVIDA LAS NOCHES',
    act1_top1_size: 66,
    act1_top2: 'ABURRIDAS! 🔥',
    act1_top2_size: 84,
    act1_box1: '¡GIRA LA BOTELLA,',
    act1_box1_size: 64,
    act1_box2: 'ENCIENDE LA FIESTA! 🎉',
    act1_box2_size: 64,
    act1_badge: 'WOBBLY BOTTLE: PARTY GAME',

    act2_title_unlocked: '¿A QUIÉN ELEGIRÁ? 👀',
    act2_title_locked: '¡OBJETIVO: MATEO! 🎯',
    act2_title_size: 60,
    players: ['LUCAS', 'SOFÍA', 'VALERIA', 'MATEO', 'DIEGO', 'CAMILA'],
    role_answerer: '🎯 RESPONDE',
    role_asker: '🗣️ PREGUNTA',
    act2_sub_unlocked: '¡AÑADE A TUS AMIGOS Y GIRA!',
    act2_sub_unlocked_size: 36,
    act2_btn_spin: '🐔 ¡GIRAR AHORA!',
    act2_btn_spinning: '🐔 GIRANDO...',
    act2_btn_size: 46,
    act2_pair_line: 'PREGUNTA: CAMILA  ➔  RESPONDE: MATEO',
    act2_pair_size: 33,
    act2_tod_title: '¿VERDAD O RETO?',
    act2_tod_size: 46,
    act2_truth_btn: 'VERDAD 💡',
    act2_dare_btn: 'RETO 🔥',
    act2_tod_btn_size: 42,

    act3_top1: '¡SALEN LOS SECRETOS! 😈',
    act3_top1_size: 60,
    act3_top2: '¡CIENTOS DE RETOS Y PREGUNTAS!',
    act3_top2_size: 40,
    act3_badge: '🔥 RETO PARA MATEO (+18 VIP)',
    act3_badge_size: 35,
    act3_lines: [
      '"Mira a los ojos de alguien',
      'del grupo por 15 segundos y',
      'confiesa tu mayor secreto...',
      '¡O lee en voz alta tu último',
      'mensaje del móvil! 🔥💋"'
    ],
    act3_line_size: 42,
    act3_next_btn: 'LISTO / SIGUIENTE TURNO ➔',
    act3_next_size: 36,

    act4_obj_top1: '¡5 OBJETOS LOCOS! 🍾',
    act4_obj_top1_size: 62,
    act4_obj_top2: '¡GIRA BOTELLA, POLLO O CHANCLA!',
    act4_obj_top2_size: 36,
    objs: [
      { name: 'Botella de Refresco', tag: '✨ GRATIS', col: '#00F2FE' },
      { name: 'Pollo Chillón 🐔', tag: '🔥 DIVERTIDO', col: '#FF9500' },
      { name: 'Pepinillo Loco 🥒', tag: '😂 GRACIOSO', col: '#34C759' },
      { name: 'Chancla Voladora 🩴', tag: '🎯 SIN ESCAPE', col: '#BF4FFF' },
      { name: 'Champán Dorado 👑', tag: '👑 WOBBLY VIP', col: '#FFCC00' },
    ],
    act4_obj_name_size: 42,
    act4_obj_tag_size: 26,

    act4_pack_top1: '¡6 PAQUETES DE FIESTA! 🔥',
    act4_pack_top1_size: 60,
    act4_pack_top2: 'CIENTOS DE PREGUNTAS PARA TODOS',
    act4_pack_top2_size: 36,
    packNames: [
      'FIESTA Y DIVERSIÓN', 'CONFESIONES',
      'RETOS ATREVIDOS', 'LIGUE Y PAREJAS',
      '💋 +18 PICANTE', 'MODO LIBRE'
    ],
    act4_pack_name_size: 28,

    act5_sub: 'JUEGO DE FIESTA VERDAD O RETO',
    act5_sub_size: 40,
    act5_cta: '¡DESCÁRGALO GRATIS YA! 👇',
    act5_cta_size: 58,
    act5_ios: '🍎  Consíguelo en el App Store',
    act5_android: '▶️  Disponible en Google Play',
    act5_store_size: 48
  }
};

// ============================================================================
// 1. GENERATE CLEAN CINEMATIC SFX WAV
// ============================================================================
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

function generateSfxWav(wavPath) {
  const left = new Float32Array(NUM_SAMPLES);
  const right = new Float32Array(NUM_SAMPLES);

  function addSample(idx, l, r) {
    if (idx >= 0 && idx < NUM_SAMPLES) {
      left[idx] += l;
      right[idx] += r;
    }
  }

  function addCinematicWhoosh(tCenter, duration = 0.55, vol = 0.34, panDir = 1) {
    const start = Math.floor((tCenter - duration * 0.5) * SAMPLE_RATE);
    const len = Math.floor(duration * SAMPLE_RATE);
    const hp = new HighPassFilter(140);
    let lpState = 0;

    for (let i = 0; i < len; i++) {
      const p = i / len;
      const env = Math.sin(p * Math.PI);
      const cutoff = 180 + 950 * Math.pow(env, 1.6);
      const rc = 1.0 / (2 * Math.PI * cutoff);
      const dt = 1.0 / SAMPLE_RATE;
      const alpha = dt / (rc + dt);

      const white = (Math.random() * 2 - 1);
      lpState = lpState + alpha * (white - lpState);
      const filtered = hp.process(lpState);

      const subEnv = Math.exp(-Math.pow((p - 0.52) * 6, 2));
      const sub = Math.sin(2 * Math.PI * 58 * (i / SAMPLE_RATE)) * subEnv * 0.45;

      const sig = (filtered * 1.4 + sub) * env * vol;
      const pan = (p * 2 - 1) * 0.45 * panDir;
      addSample(start + i, sig * (1 - pan), sig * (1 + pan));
    }
  }

  function addRealisticSpin(tStart, tEnd, vol = 0.36) {
    const start = Math.floor(tStart * SAMPLE_RATE);
    const len = Math.floor((tEnd - tStart) * SAMPLE_RATE);
    const lp = new LowPassFilter(480);
    const hp = new HighPassFilter(110);

    for (let i = 0; i < len; i++) {
      const p = i / len;
      const t = i / SAMPLE_RATE;
      const speed = Math.pow(1 - p, 1.8);
      const angle = (1 - Math.pow(1 - p, 2.8)) * Math.PI * 2 * 7.5;
      const grainMod = 0.55 + 0.45 * Math.sin(angle * 2);

      const raw = (Math.random() * 2 - 1) * grainMod;
      const body = hp.process(lp.process(raw));
      const resFreq = 210 + 90 * speed;
      const res = Math.sin(2 * Math.PI * resFreq * t) * 0.08 * grainMod;

      const env = Math.min(1, t * 8) * Math.pow(1 - p, 0.85);
      const sig = (body * 1.5 + res) * env * vol;
      const pan = Math.sin(angle) * 0.35;
      addSample(start + i, sig * (1 - pan), sig * (1 + pan));
    }
  }

  function addWarmSwell(t0, dur, freqs, vol = 0.20) {
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

  function addSoftTouch(t0, vol = 0.24) {
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

  addCinematicWhoosh(0.20, 0.50, 0.30, 1);
  addCinematicWhoosh(1.40, 0.55, 0.32, -1);
  addCinematicWhoosh(4.50, 0.50, 0.28, 1);
  addSoftTouch(5.20, 0.24);
  addRealisticSpin(5.30, 8.20, 0.38);
  addCinematicWhoosh(8.20, 0.45, 0.32, -1);
  addWarmSwell(8.20, 1.40, [261.63, 311.13, 392.00, 466.16], 0.22);
  addSoftTouch(10.35, 0.24);
  addCinematicWhoosh(11.00, 0.55, 0.35, 1);
  addWarmSwell(11.05, 1.80, [233.08, 293.66, 349.23, 466.16], 0.22);
  addCinematicWhoosh(16.00, 0.55, 0.30, -1);
  addCinematicWhoosh(19.00, 0.55, 0.30, 1);
  addCinematicWhoosh(22.00, 0.60, 0.35, -1);
  addWarmSwell(22.05, 2.50, [261.63, 311.13, 392.00, 523.25], 0.22);

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
    const l = Math.tanh(left[i] * 0.95);
    const r = Math.tanh(right[i] * 0.95);
    buffer.writeInt16LE(Math.floor(l * 32000), offset);
    buffer.writeInt16LE(Math.floor(r * 32000), offset + 2);
    offset += 4;
  }
  fs.writeFileSync(wavPath, buffer);
}

// ============================================================================
// 2. HTML5 CANVAS 1080x1920 60FPS ANIMATION FOR GIVEN LANGUAGE
// ============================================================================
function getAnimatorHtml(cfg) {
  const cfgJson = JSON.stringify(cfg);
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
const CFG = ${cfgJson};

const assetList = {
  bg: '/assets/game_bg.png',
  icon: '/assets/app_icon.png',
  packs: '/assets/pack_sheet.png',
  b0_0: '/assets/bent_0_0.png',
  b0_l: '/assets/bent_0_l.png',
  b0_r: '/assets/bent_0_r.png',
  b1_0: '/assets/bent_1_0.png',
  b1_l: '/assets/bent_1_l.png',
  b1_r: '/assets/bent_1_r.png',
  b2_0: '/assets/bent_2_0.png',
  b2_l: '/assets/bent_2_l.png',
  b2_r: '/assets/bent_2_r.png',
  b3_0: '/assets/bent_3_0.png',
  b3_l: '/assets/bent_3_l.png',
  b3_r: '/assets/bent_3_r.png',
  b4_0: '/assets/bent_4_0.png',
  b4_l: '/assets/bent_4_l.png',
  b4_r: '/assets/bent_4_r.png',
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

function easeOutBack(x) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
}
function easeOutCubic(x) {
  return 1 - Math.pow(1 - x, 3);
}
function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}

const particles = [];
for (let i = 0; i < 85; i++) {
  particles.push({
    x: (Math.sin(i * 78.233) * 0.5 + 0.5) * W,
    y: (Math.cos(i * 45.164) * 0.5 + 0.5) * H,
    r: 3 + (i % 7) * 2.2,
    vy: -50 - (i % 5) * 35,
    vx: Math.sin(i * 12.3) * 30,
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
  ctx.strokeStyle = 'rgba(0,0,0,0.88)';
  ctx.strokeText(text, x, y);
  ctx.fillStyle = color;
  ctx.fillText(text, x, y);
  ctx.restore();
}

function drawCleanText(text, x, y, size, color = '#FFFFFF', weight = '700', align = 'center') {
  ctx.save();
  ctx.font = weight + ' ' + size + 'px "Segoe UI", Helvetica, Arial, sans-serif';
  ctx.textAlign = align;
  ctx.textBaseline = 'middle';
  ctx.shadowColor = 'rgba(0, 0, 0, 0.35)';
  ctx.shadowBlur = 6;
  ctx.shadowOffsetY = 2;
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
  const tapScale = 1 - 0.25 * Math.sin(progress * Math.PI);
  ctx.beginPath();
  ctx.arc(x, y, 36 * tapScale, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(255, 255, 255, ' + ((1 - progress * 0.5) * 0.85) + ')';
  ctx.shadowColor = '#FFCC00';
  ctx.shadowBlur = 30;
  ctx.fill();
  ctx.restore();
}

function getCyclingWobbleSprite(t, speed = 7.2) {
  const cycleOrder = [0, 2, 3, 4]; // Soda, Pickle, Slipper, Champagne
  const halfCycles = Math.floor((t * speed) / Math.PI);
  const objIdx = cycleOrder[halfCycles % cycleOrder.length];
  const wobbleAng = Math.sin(t * speed) * 0.25;
  const suffix = wobbleAng < -0.08 ? 'l' : (wobbleAng > 0.08 ? 'r' : '0');
  const switchPhase = ((t * speed) % Math.PI) / Math.PI;
  const switchPop = 1 + 0.08 * Math.sin(switchPhase * Math.PI);
  return {
    img: imgs['b' + objIdx + '_' + suffix],
    wobbleAng,
    switchPop,
    objIdx
  };
}

function renderFrame(t) {
  ctx.save();
  ctx.clearRect(0, 0, W, H);

  const beatPos = (t * (124 / 60)) % 1;
  const beatPulse = Math.exp(-beatPos * 6);

  let shakeX = 0, shakeY = 0;
  const impacts = [0.15, 1.35, 4.50, 8.20, 11.00, 16.00, 19.00, 22.00];
  for (const imp of impacts) {
    const dt = t - imp;
    if (dt >= 0 && dt < 0.26) {
      const mag = (1 - dt / 0.26) * 20;
      shakeX += Math.sin(t * 190) * mag;
      shakeY += Math.cos(t * 230) * mag;
    }
  }
  ctx.translate(shakeX, shakeY);

  const bgScale = 1.06 + 0.04 * Math.sin(t * 0.7) + beatPulse * 0.014;
  ctx.save();
  ctx.translate(W / 2, H / 2);
  ctx.scale(bgScale, bgScale);
  ctx.drawImage(imgs.bg, -W / 2, -H / 2, W, H);
  ctx.restore();

  const grad = ctx.createRadialGradient(W / 2, H / 2, 120, W / 2, H / 2, 1100);
  grad.addColorStop(0, 'rgba(5, 12, 28, 0.52)');
  grad.addColorStop(1, 'rgba(2, 4, 12, 0.88)');
  ctx.fillStyle = grad;
  ctx.fillRect(-40, -40, W + 80, H + 80);

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
  // ACT 1 (0.0s - 4.5s): HOOK
  // ==========================================================================
  if (t < 4.50) {
    const bottleY = H * 0.525;

    for (let r = 0; r < 3; r++) {
      const rp = ((t * 0.85 + r * 0.33) % 1);
      ctx.save();
      ctx.beginPath();
      ctx.arc(W / 2, bottleY, 90 + rp * 540, 0, Math.PI * 2);
      ctx.strokeStyle = r % 2 === 0
        ? 'rgba(0, 242, 254, ' + ((1 - rp) * 0.45) + ')'
        : 'rgba(255, 8, 68, ' + ((1 - rp) * 0.45) + ')';
      ctx.lineWidth = 6 * (1 - rp);
      ctx.stroke();
      ctx.restore();
    }

    const entryP = clamp((t - 0.05) / 0.5, 0, 1);
    const cyc = getCyclingWobbleSprite(t, 6.2);
    const bScale = easeOutBack(entryP) * cyc.switchPop * (1 + beatPulse * 0.05);
    const glowColors = { 0: '#00F2FE', 2: '#34C759', 3: '#BF4FFF', 4: '#FFCC00' };
    const introSize = 760;

    ctx.save();
    ctx.translate(W / 2, bottleY);
    ctx.scale(bScale, bScale);
    ctx.rotate(cyc.wobbleAng);
    ctx.shadowColor = glowColors[cyc.objIdx] || '#00F2FE';
    ctx.shadowBlur = 65;
    ctx.drawImage(cyc.img, -introSize * 0.5, -introSize * 0.63, introSize, introSize);
    ctx.restore();

    const p1 = easeOutBack(clamp((t - 0.10) / 0.38, 0, 1));
    ctx.save();
    ctx.translate(W / 2, 185);
    ctx.scale(p1, p1);
    drawNeonText(CFG.act1_top1, 0, -42, CFG.act1_top1_size, '#FFFFFF', '#00F2FE', 32);
    drawNeonText(CFG.act1_top2, 0, 46, CFG.act1_top2_size, '#FFCC00', '#FF0844', 38);
    ctx.restore();

    if (t >= 1.35) {
      const p2 = easeOutBack(clamp((t - 1.35) / 0.40, 0, 1));
      ctx.save();
      ctx.translate(W / 2, 420);
      ctx.scale(p2, p2);

      roundRect(ctx, -460, -100, 920, 200, 36);
      ctx.fillStyle = 'rgba(15, 10, 30, 0.86)';
      ctx.shadowColor = '#FF0844';
      ctx.shadowBlur = 30;
      ctx.fill();
      ctx.lineWidth = 4;
      ctx.strokeStyle = '#FF0844';
      ctx.stroke();
      ctx.shadowBlur = 0;

      drawNeonText(CFG.act1_box1, 0, -38, CFG.act1_box1_size, '#00F2FE', '#00F2FE', 28);
      drawNeonText(CFG.act1_box2, 0, 44, CFG.act1_box2_size, '#FF0844', '#FF0844', 32);
      ctx.restore();
    }

    const bp = easeOutCubic(clamp((t - 0.3) / 0.45, 0, 1));
    ctx.save();
    ctx.globalAlpha = bp;
    roundRect(ctx, W / 2 - 380, H * 0.83, 760, 115, 58);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.92)';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = '#FFCC00';
    ctx.stroke();
    drawNeonText(CFG.act1_badge, W / 2, H * 0.83 + 57, 42, '#FFCC00', '#FFCC00', 20);
    ctx.restore();
  }

  // ==========================================================================
  // ACT 2 (4.50s - 11.00s): LIVE ARENA WITH SQUEAKY CHICKEN
  // ==========================================================================
  else if (t >= 4.50 && t < 11.00) {
    const isLocked = t >= 8.20;

    const camZoom = isLocked
      ? 1.0 + 0.10 * easeOutBack(clamp((t - 8.20) / 0.45, 0, 1))
      : 1.0;

    ctx.save();
    ctx.translate(W / 2, H * 0.45);
    ctx.scale(camZoom, camZoom);
    ctx.translate(-W / 2, -H * 0.45);

    drawNeonText(
      isLocked ? CFG.act2_title_locked : CFG.act2_title_unlocked,
      W / 2, 160, CFG.act2_title_size, '#FFCC00', '#FFCC00', 28
    );

    const cx = W / 2, cy = H * 0.45;
    const radius = 355;

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.strokeStyle = isLocked ? 'rgba(255, 8, 68, 0.65)' : 'rgba(0, 242, 254, 0.45)';
    ctx.lineWidth = 6;
    ctx.shadowColor = isLocked ? '#FF0844' : '#00F2FE';
    ctx.shadowBlur = 25;
    ctx.stroke();
    ctx.restore();

    const pColors = ['#00F2FE', '#FF0844', '#FF9500', '#AF52DE', '#FFCC00', '#34C759'];

    if (isLocked) {
      const aQ = -Math.PI / 2 + (5 * 2 * Math.PI / 6);
      const aA = -Math.PI / 2 + (3 * 2 * Math.PI / 6);
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
      const isA = isLocked && i === 3;
      const isQ = isLocked && i === 5;
      const pScale = (isA || isQ) ? 1.25 + 0.06 * Math.sin(t * 14) : 1.0;

      ctx.save();
      ctx.translate(px, py);
      ctx.scale(pScale, pScale);

      ctx.beginPath();
      ctx.arc(0, 0, 56, 0, Math.PI * 2);
      ctx.fillStyle = pColors[i];
      ctx.shadowColor = isA ? '#FF0844' : (isQ ? '#00F2FE' : pColors[i]);
      ctx.shadowBlur = (isA || isQ) ? 40 : 15;
      ctx.fill();
      ctx.lineWidth = (isA || isQ) ? 7 : 4;
      ctx.strokeStyle = '#FFFFFF';
      ctx.stroke();

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

      roundRect(ctx, -85, 66, 170, 44, 14);
      ctx.fillStyle = isA ? '#FF0844' : (isQ ? '#082038' : 'rgba(10, 24, 40, 0.92)');
      ctx.fill();
      if (isQ) {
        ctx.lineWidth = 2.5;
        ctx.strokeStyle = '#00F2FE';
        ctx.stroke();
      }
      drawCleanText(CFG.players[i], 0, 88, 26, '#FFFFFF', '700');

      if (isA) {
        roundRect(ctx, -125, -112, 250, 44, 14);
        ctx.fillStyle = '#FF0844';
        ctx.fill();
        drawCleanText(CFG.role_answerer, 0, -90, 23, '#FFFFFF', '700');
      } else if (isQ) {
        roundRect(ctx, -105, -112, 210, 44, 14);
        ctx.fillStyle = '#07223B';
        ctx.fill();
        ctx.lineWidth = 3;
        ctx.strokeStyle = '#00F2FE';
        ctx.stroke();
        drawCleanText(CFG.role_asker, 0, -90, 23, '#00F2FE', '700');
      }
      ctx.restore();
    }

    let bottleAngle = 0;
    let bottleImg = imgs.b1_0;
    const targetAngle = -Math.PI / 2 + (1 * 2 * Math.PI / 6) + Math.PI / 2 + 0.18;

    if (t < 5.30) {
      bottleAngle = Math.sin(t * 4) * 0.08;
    } else if (t < 8.20) {
      const sp = clamp((t - 5.30) / 2.90, 0, 1);
      const eased = 1 - Math.pow(1 - sp, 3.1);
      bottleAngle = eased * (Math.PI * 2 * 6 + targetAngle);
      const cyc = Math.sin(sp * 42);
      bottleImg = cyc < -0.25 ? imgs.b1_l : (cyc > 0.25 ? imgs.b1_r : imgs.b1_0);
    } else {
      bottleAngle = targetAngle;
      bottleImg = imgs.b1_r;
    }

    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(bottleAngle);
    ctx.shadowColor = isLocked ? '#FF0844' : '#FF9500';
    ctx.shadowBlur = isLocked ? 55 : 40;
    const bBounce = isLocked ? 1 + 0.08 * Math.sin((t - 8.20) * 18) * Math.exp(-(t - 8.20) * 2.5) : 1;
    ctx.scale(bBounce, bBounce);
    ctx.drawImage(bottleImg, -225, -225, 450, 450);
    ctx.restore();

    ctx.restore();

    ctx.save();
    roundRect(ctx, 70, 1410, W - 140, 360, 38);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.94)';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = isLocked ? '#FF0844' : '#00F2FE';
    ctx.stroke();

    if (!isLocked) {
      drawNeonText(CFG.act2_sub_unlocked, W / 2, 1500, CFG.act2_sub_unlocked_size, '#00F2FE', '#00F2FE', 18);

      roundRect(ctx, 130, 1575, W - 260, 130, 32);
      const btnGrad = ctx.createLinearGradient(130, 1575, W - 130, 1705);
      btnGrad.addColorStop(0, '#FF9500');
      btnGrad.addColorStop(1, '#FF5E00');
      ctx.fillStyle = btnGrad;
      ctx.shadowColor = '#FF9500';
      ctx.shadowBlur = 30;
      ctx.fill();
      ctx.lineWidth = 4;
      ctx.strokeStyle = '#FFCC00';
      ctx.stroke();
      ctx.shadowBlur = 0;

      drawCleanText(
        t < 5.30 ? CFG.act2_btn_spin : CFG.act2_btn_spinning,
        W / 2, 1640, CFG.act2_btn_size, '#FFFFFF', '800'
      );

      drawTapRipple(W / 2 + 120, 1640, (t - 5.05) / 0.50);
    } else {
      drawNeonText(CFG.act2_pair_line, W / 2, 1480, CFG.act2_pair_size, '#FFCC00', '#000', 10);
      drawNeonText(CFG.act2_tod_title, W / 2, 1550, CFG.act2_tod_size, '#FFFFFF', '#FF0844', 20);

      roundRect(ctx, 110, 1615, 400, 115, 26);
      const truthGrad = ctx.createLinearGradient(110, 1615, 510, 1730);
      truthGrad.addColorStop(0, '#0072FF');
      truthGrad.addColorStop(1, '#00C6FF');
      ctx.fillStyle = truthGrad;
      ctx.shadowColor = '#00F2FE';
      ctx.shadowBlur = 25;
      ctx.fill();
      ctx.lineWidth = 3.5;
      ctx.strokeStyle = '#00F2FE';
      ctx.stroke();
      ctx.shadowBlur = 0;
      drawCleanText(CFG.act2_truth_btn, 310, 1672, CFG.act2_tod_btn_size, '#FFFFFF', '800');

      roundRect(ctx, 570, 1615, 400, 115, 26);
      const dareGrad = ctx.createLinearGradient(570, 1615, 970, 1730);
      dareGrad.addColorStop(0, '#FF0844');
      dareGrad.addColorStop(1, '#FF4E50');
      ctx.fillStyle = dareGrad;
      ctx.shadowColor = '#FF0844';
      ctx.shadowBlur = 30;
      ctx.fill();
      ctx.lineWidth = 3.5;
      ctx.strokeStyle = '#FF9500';
      ctx.stroke();
      ctx.shadowBlur = 0;
      drawCleanText(CFG.act2_dare_btn, 770, 1672, CFG.act2_tod_btn_size, '#FFFFFF', '800');

      drawTapRipple(770, 1672, (t - 10.25) / 0.55);
    }
    ctx.restore();
  }

  // ==========================================================================
  // ACT 3 (11.00s - 16.00s): SPICY QUESTION CARD REVEAL
  // ==========================================================================
  else if (t >= 11.00 && t < 16.00) {
    const ct = t - 11.00;
    const cardScale = easeOutBack(clamp(ct / 0.50, 0, 1));

    drawNeonText(CFG.act3_top1, W / 2, 220, CFG.act3_top1_size, '#FF0844', '#FF0844', 35);
    drawNeonText(CFG.act3_top2, W / 2, 310, CFG.act3_top2_size, '#FFCC00', '#FFCC00', 22);

    ctx.save();
    ctx.translate(W / 2, H * 0.55);
    ctx.scale(cardScale, cardScale);

    roundRect(ctx, -455, -450, 910, 900, 48);
    ctx.fillStyle = 'rgba(15, 20, 38, 0.96)';
    ctx.shadowColor = '#FF0844';
    ctx.shadowBlur = 65;
    ctx.fill();
    ctx.lineWidth = 8;
    ctx.strokeStyle = '#FF0844';
    ctx.stroke();
    ctx.shadowBlur = 0;

    roundRect(ctx, -355, -375, 710, 90, 26);
    ctx.fillStyle = 'rgba(255, 8, 68, 0.24)';
    ctx.fill();
    ctx.lineWidth = 3.5;
    ctx.strokeStyle = '#FFCC00';
    ctx.stroke();
    drawNeonText(CFG.act3_badge, 0, -330, CFG.act3_badge_size, '#FFCC00', '#FF0844', 15);

    roundRect(ctx, -395, -230, 790, 450, 34);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.58)';
    ctx.fill();

    for (let l = 0; l < CFG.act3_lines.length; l++) {
      drawNeonText(CFG.act3_lines[l], 0, -145 + l * 74, CFG.act3_line_size, '#FFFFFF', '#00F2FE', 12);
    }

    roundRect(ctx, -340, 275, 680, 115, 30);
    const nextGrad = ctx.createLinearGradient(-340, 275, 340, 390);
    nextGrad.addColorStop(0, '#0066FF');
    nextGrad.addColorStop(1, '#00D2FF');
    ctx.fillStyle = nextGrad;
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 30;
    ctx.fill();
    ctx.lineWidth = 3.5;
    ctx.strokeStyle = '#FFFFFF';
    ctx.stroke();
    ctx.shadowBlur = 0;
    drawCleanText(CFG.act3_next_btn, 0, 332, CFG.act3_next_size, '#FFFFFF', '800');

    ctx.restore();
  }

  // ==========================================================================
  // ACT 4 (16.00s - 22.00s): 5 OBJECTS SHOWCASE (3s) + 6 PARTY PACKS (3s)
  // ==========================================================================
  else if (t >= 16.00 && t < 22.00) {
    if (t < 19.00) {
      const ot = t - 16.00;
      drawNeonText(CFG.act4_obj_top1, W / 2, 165, CFG.act4_obj_top1_size, '#FFCC00', '#FFCC00', 30);
      drawNeonText(CFG.act4_obj_top2, W / 2, 245, CFG.act4_obj_top2_size, '#00F2FE', '#00F2FE', 18);

      const objImgs = [imgs.b0_0, imgs.b1_0, imgs.b2_0, imgs.b3_0, imgs.b4_0];

      for (let i = 0; i < 5; i++) {
        const entry = easeOutBack(clamp((ot - i * 0.08) / 0.42, 0, 1));
        const y = 325 + i * 285;
        const isVip = i === 4;
        const item = CFG.objs[i];

        ctx.save();
        ctx.translate(W / 2, y + 120);
        ctx.scale(entry, entry);
        ctx.translate(-W / 2, -(y + 120));

        roundRect(ctx, 80, y, W - 160, 245, 34);
        ctx.fillStyle = isVip ? 'rgba(30, 22, 10, 0.94)' : 'rgba(10, 24, 40, 0.92)';
        ctx.shadowColor = item.col;
        ctx.shadowBlur = isVip ? 35 : 20;
        ctx.fill();
        ctx.lineWidth = isVip ? 6 : 4;
        ctx.strokeStyle = item.col;
        ctx.stroke();
        ctx.shadowBlur = 0;

        const cardIconSize = 350;
        ctx.save();
        ctx.translate(225, y + 122);
        ctx.rotate(-0.22 + Math.sin(t * 8 + i) * 0.12);
        ctx.shadowColor = item.col;
        ctx.shadowBlur = 22;
        ctx.drawImage(objImgs[i], -cardIconSize * 0.5, -cardIconSize * 0.63, cardIconSize, cardIconSize);
        ctx.restore();

        drawCleanText(item.name, 375, y + 92, CFG.act4_obj_name_size, '#FFFFFF', '800', 'left');

        roundRect(ctx, 375, y + 138, 325, 60, 18);
        ctx.fillStyle = 'rgba(5, 12, 24, 0.92)';
        ctx.fill();
        ctx.lineWidth = 3;
        ctx.strokeStyle = item.col;
        ctx.stroke();
        drawCleanText(item.tag, 537, y + 168, CFG.act4_obj_tag_size, item.col, '700', 'center');

        ctx.restore();
      }
    } else {
      const pt = t - 19.00;
      drawNeonText(CFG.act4_pack_top1, W / 2, 165, CFG.act4_pack_top1_size, '#FFCC00', '#FF0844', 32);
      drawNeonText(CFG.act4_pack_top2, W / 2, 245, CFG.act4_pack_top2_size, '#00F2FE', '#00F2FE', 18);

      const cellW = imgs.packs.width / 2;
      const cellH = imgs.packs.height / 3;

      for (let i = 0; i < 6; i++) {
        const col = i % 2;
        const row = Math.floor(i / 2);
        const cardW = 430, cardH = 420;
        const gx = col === 0 ? 85 : 565;
        const gy = 325 + row * 460;

        const entry = easeOutBack(clamp((pt - i * 0.06) / 0.40, 0, 1));
        const isSpicy = i === 4;

        ctx.save();
        ctx.translate(gx + cardW / 2, gy + cardH / 2);
        const scaleBoost = isSpicy ? entry * (1.05 + 0.03 * Math.sin(t * 15)) : entry;
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

        drawCleanText(CFG.packNames[i], cardW / 2, cardH - 38, CFG.act4_pack_name_size, isSpicy ? '#FFCC00' : '#FFFFFF', '800');
        ctx.restore();
      }
    }
  }

  // ==========================================================================
  // ACT 5 (22.00s - 26.00s): CLEAN OUTRO WITH CYCLING WOBBLY OBJECTS
  // ==========================================================================
  else {
    const ot = t - 22.00;
    const pop = easeOutBack(clamp(ot / 0.50, 0, 1));
    const cyc = getCyclingWobbleSprite(t, 6.2);
    const glowColors = { 0: '#00F2FE', 2: '#34C759', 3: '#BF4FFF', 4: '#FFCC00' };
    const ringCol = glowColors[cyc.objIdx] || '#00F2FE';

    const outroSize = 570;
    ctx.save();
    ctx.translate(W / 2, 455);
    ctx.scale(pop * cyc.switchPop, pop * cyc.switchPop);

    ctx.beginPath();
    ctx.arc(0, 0, 240, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(10, 24, 40, 0.92)';
    ctx.shadowColor = ringCol;
    ctx.shadowBlur = 65;
    ctx.fill();
    ctx.lineWidth = 8;
    ctx.strokeStyle = ringCol;
    ctx.stroke();

    ctx.rotate(cyc.wobbleAng);
    ctx.drawImage(cyc.img, -outroSize * 0.5, -outroSize * 0.63, outroSize, outroSize);
    ctx.restore();

    drawNeonText('WOBBLY BOTTLE', W / 2, 785, 96, '#FFCC00', '#FFCC00', 40);
    drawNeonText(CFG.act5_sub, W / 2, 880, CFG.act5_sub_size, '#00F2FE', '#00F2FE', 22);

    const pulseScale = 1 + 0.04 * Math.sin(t * 12);
    ctx.save();
    ctx.translate(W / 2, 1045);
    ctx.scale(pulseScale, pulseScale);
    drawNeonText(CFG.act5_cta, 0, 0, CFG.act5_cta_size, '#FFFFFF', '#FF0844', 35);
    ctx.restore();

    const b1 = easeOutBack(clamp((ot - 0.18) / 0.45, 0, 1));
    ctx.save();
    ctx.translate(W / 2, 1270);
    ctx.scale(b1, b1);
    roundRect(ctx, -420, -92, 840, 184, 42);
    ctx.fillStyle = '#0D1829';
    ctx.shadowColor = '#00F2FE';
    ctx.shadowBlur = 38;
    ctx.fill();
    ctx.lineWidth = 6;
    ctx.strokeStyle = '#00F2FE';
    ctx.stroke();
    ctx.shadowBlur = 0;
    drawCleanText(CFG.act5_ios, 0, 0, CFG.act5_store_size, '#FFFFFF', '800');
    ctx.restore();

    const b2 = easeOutBack(clamp((ot - 0.35) / 0.45, 0, 1));
    ctx.save();
    ctx.translate(W / 2, 1515);
    ctx.scale(b2, b2);
    roundRect(ctx, -420, -92, 840, 184, 42);
    ctx.fillStyle = '#190D24';
    ctx.shadowColor = '#FF0844';
    ctx.shadowBlur = 38;
    ctx.fill();
    ctx.lineWidth = 6;
    ctx.strokeStyle = '#FF0844';
    ctx.stroke();
    ctx.shadowBlur = 0;
    drawCleanText(CFG.act5_android, 0, 0, CFG.act5_store_size, '#FFFFFF', '800');
    ctx.restore();

    drawTapRipple(W / 2 + 190, 1270, (ot - 1.10) / 0.55);
    drawTapRipple(W / 2 + 190, 1515, (ot - 1.90) / 0.55);
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
// 3. RENDER ONE LANGUAGE VIDEO
// ============================================================================
function renderLanguageVideo(langKey) {
  return new Promise((resolve, reject) => {
    const cfg = LANG_CONFIGS[langKey];
    const rawMp4 = path.join(ARTIFACT_DIR, `temp_raw_${langKey}.mp4`);
    const finalArtifactMp4 = path.join(ARTIFACT_DIR, cfg.fileName);
    const desktopMp4 = path.join('C:\\Users\\PC\\Desktop', cfg.fileName);

    console.log(`\n========================================`);
    console.log(`Starting render for [${langKey}] -> ${cfg.fileName}`);
    console.log(`========================================`);

    const ffmpegArgs = [
      '-y',
      '-f', 'image2pipe',
      '-vcodec', 'mjpeg',
      '-framerate', String(FPS),
      '-i', '-',
      '-i', SFX_WAV,
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '18',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-shortest',
      '-movflags', '+faststart',
      rawMp4
    ];

    const ffmpegProc = spawn(FFMPEG_PATH, ffmpegArgs, { stdio: ['pipe', 'ignore', 'pipe'] });
    ffmpegProc.stderr.on('data', () => {});

    let chromeProc = null;

    const server = http.createServer((req, res) => {
      if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(getAnimatorHtml(cfg));
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
          if (idx % 240 === 0) {
            console.log(`[${langKey}] Rendered frame ${idx} / ${TOTAL_FRAMES}`);
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
        console.log(`[${langKey}] All frames rendered! Mixing EDM soundtrack...`);
        res.writeHead(200);
        res.end('done');
        ffmpegProc.stdin.end();
      } else if (req.method === 'POST' && req.url.startsWith('/error')) {
        console.error(`[${langKey}] Browser error:`, req.url);
        res.writeHead(200);
        res.end();
        reject(new Error(req.url));
      } else {
        res.writeHead(404);
        res.end();
      }
    });

    server.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      const url = 'http://127.0.0.1:' + port + '/';
      const profileDir = path.join(ARTIFACT_DIR, 'scratch', `chrome_profile_${langKey}`);
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
      if (chromeProc) {
        try { chromeProc.kill(); } catch (_) {}
      }
      server.close();

      if (code !== 0) {
        return reject(new Error(`FFmpeg exited with code ${code}`));
      }

      execFileSync(FFMPEG_PATH, [
        '-y',
        '-i', rawMp4,
        '-ss', '14.8',
        '-t', '26',
        '-i', CLOUD_DANCER_MP3,
        '-filter_complex', '[0:a]volume=1.35[sfx];[1:a]volume=0.88,afade=t=in:st=0:d=0.4,afade=t=out:st=24.8:d=1.2[mus];[sfx][mus]amix=inputs=2:duration=first:dropout_transition=0,alimiter=limit=0.96[aout]',
        '-map', '0:v:0',
        '-map', '[aout]',
        '-c:v', 'copy',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-movflags', '+faststart',
        finalArtifactMp4
      ]);

      try {
        fs.copyFileSync(finalArtifactMp4, desktopMp4);
        console.log(`[${langKey}] Saved to Desktop:`, desktopMp4);
      } catch (e) {
        console.log(`[${langKey}] Copy note:`, e.message);
      }

      try { fs.unlinkSync(rawMp4); } catch (_) {}
      resolve(desktopMp4);
    });
  });
}

async function main() {
  generateSfxWav(SFX_WAV);
  const targetLangs = process.argv.slice(2).length > 0 ? process.argv.slice(2) : ['EN', 'DE', 'ES'];
  for (const lang of targetLangs) {
    await renderLanguageVideo(lang);
  }
  try { fs.unlinkSync(SFX_WAV); } catch (_) {}
  console.log('\nALL REQUESTED LANGUAGE VIDEOS GENERATED SUCCESSFULLY!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
