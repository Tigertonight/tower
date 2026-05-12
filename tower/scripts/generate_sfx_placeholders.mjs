import fs from "node:fs";
import path from "node:path";

const root = path.resolve("tower_game/audio/sfx");
fs.mkdirSync(root, { recursive: true });

const sr = 44100;
let seed = 1337;
const rnd = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 4294967296;
};
const sine = (f, t) => Math.sin(Math.PI * 2 * f * t);
const noise = () => rnd() * 2 - 1;
const env = (t, dur, a = 0.006, r = 0.08) =>
  Math.min(1, t / a) * Math.max(0, Math.min(1, (dur - t) / r));
const thud = (t, dur, base = 90) =>
  (sine(base + 30 * Math.exp(-t * 20), t) * 0.55 + noise() * 0.22) *
  env(t, dur, 0.004, dur * 0.75);
const click = (t, dur) => (noise() * 0.8 + sine(900, t) * 0.22) * env(t, dur, 0.001, dur * 0.45);
const chime = (t, dur, f = 880) =>
  (sine(f, t) * 0.55 + sine(f * 1.5, t) * 0.25) * env(t, dur, 0.01, dur * 0.75);
const paper = (t, dur) => (noise() * 0.55 + sine(240 + (180 * t) / dur, t) * 0.18) *
  env(t, dur, 0.002, dur * 0.55);

function writeWav(name, seconds, make) {
  const n = Math.max(1, Math.floor(seconds * sr));
  const data = Buffer.alloc(n * 2);
  let last = 0;
  for (let i = 0; i < n; i += 1) {
    const t = i / sr;
    const s = Math.max(-1, Math.min(1, make(t, i, n)));
    last = last * 0.15 + s * 0.85;
    data.writeInt16LE(Math.floor(last * 32767), i * 2);
  }
  const header = Buffer.alloc(44);
  header.write("RIFF", 0);
  header.writeUInt32LE(36 + data.length, 4);
  header.write("WAVE", 8);
  header.write("fmt ", 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(sr, 24);
  header.writeUInt32LE(sr * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write("data", 36);
  header.writeUInt32LE(data.length, 40);
  fs.writeFileSync(path.join(root, `${name}.wav`), Buffer.concat([header, data]));
}

const assets = {
  sfx_ui_run_start: [0.65, (t) => paper(t, 0.65) * 0.55 + (t > 0.32 ? thud(t - 0.32, 0.33, 80) : 0) * 0.8],
  sfx_ui_button_click: [0.1, (t) => click(t, 0.1) * 0.5],
  sfx_ui_hover_soft: [0.09, (t) => paper(t, 0.09) * 0.22],
  sfx_card_draw: [0.2, (t) => paper(t, 0.2) * 0.55 + sine(320, t) * 0.06 * env(t, 0.2, 0.004, 0.12)],
  sfx_card_shuffle: [0.58, (t) => paper(t, 0.58) * (0.45 + 0.2 * Math.sin(70 * t))],
  sfx_card_play_attack: [0.3, (t) => paper(t, 0.3) * 0.45 + (t > 0.055 ? thud(t - 0.055, 0.245, 120) : 0) * 0.75],
  sfx_card_play_skill: [0.3, (t) => paper(t, 0.3) * 0.35 + chime(t, 0.3, 980) * 0.28],
  sfx_card_play_power: [0.58, (t) => paper(t, 0.58) * 0.26 + chime(t, 0.58, 520) * 0.38 + sine(80, t) * 0.18 * env(t, 0.58, 0.04, 0.4)],
  sfx_combat_hit: [0.18, (t) => thud(t, 0.18, 130) * 0.9 + click(t, 0.08) * 0.25],
  sfx_combat_block: [0.28, (t) => thud(t, 0.28, 75) * 0.6 + sine(180, t) * 0.16 * env(t, 0.28, 0.008, 0.2)],
  sfx_combat_status_neg: [0.36, (t) => noise() * 0.22 * env(t, 0.36, 0.02, 0.28) + sine(1100 - (650 * t) / 0.36, t) * 0.18 * env(t, 0.36, 0.01, 0.32)],
  sfx_combat_status_pos: [0.36, (t) => chime(t, 0.36, 760) * 0.36 + chime(t, 0.36, 1140) * 0.18],
  sfx_turn_start: [0.36, (t) => paper(t, 0.36) * 0.34 + (t > 0.18 ? chime(t - 0.18, 0.18, 720) : 0) * 0.25],
  sfx_turn_end: [0.33, (t) => (t < 0.12 ? click(t, 0.12) * 0.45 : 0) + (t > 0.08 ? thud(t - 0.08, 0.25, 70) * 0.45 : 0)],
  sfx_enemy_intent: [0.32, (t) => sine(190, t) * 0.28 * env(t, 0.32, 0.015, 0.22) + chime(t, 0.32, 640) * 0.18],
  sfx_combat_victory: [1.2, (t) => chime(t, 1.2, 520) * 0.34 + chime(Math.max(0, t - 0.25), 0.95, 780) * 0.24 + (t > 0.72 ? click(t - 0.72, 0.12) * 0.25 : 0)],
  sfx_combat_defeat: [1.35, (t) => sine(82, t) * 0.42 * env(t, 1.35, 0.04, 1.1) + noise() * 0.08 * env(t, 1.35, 0.02, 1.0)],
  sfx_reward_appear: [0.55, (t) => paper(t, 0.55) * 0.25 + chime(t, 0.55, 820) * 0.22 + (t > 0.12 ? chime(t - 0.12, 0.43, 1040) * 0.18 : 0) + (t > 0.24 ? chime(t - 0.24, 0.31, 1240) * 0.15 : 0)],
  sfx_reward_pick: [0.32, (t) => paper(t, 0.32) * 0.25 + click(t, 0.12) * 0.25 + chime(t, 0.32, 920) * 0.16],
  sfx_shop_enter: [0.7, (t) => chime(t, 0.7, 620) * 0.22 + paper(t, 0.7) * 0.28],
  sfx_shop_buy: [0.45, (t) => click(t, 0.08) * 0.38 + (t > 0.09 ? click(t - 0.09, 0.08) * 0.3 : 0) + (t > 0.2 ? thud(t - 0.2, 0.25, 85) * 0.36 : 0)],
  sfx_campfire_rest: [1.2, (t) => noise() * 0.12 * env(t, 1.2, 0.03, 0.8) + sine(150, t) * 0.18 * env(t, 1.2, 0.08, 0.9)],
  sfx_campfire_upgrade: [1.1, (t) => paper(t, 1.1) * 0.18 + sine(640 + 140 * t, t) * 0.16 * env(t, 1.1, 0.02, 0.8) + (t > 0.78 ? chime(t - 0.78, 0.32, 980) * 0.22 : 0)],
  sfx_event_open: [0.5, (t) => paper(t, 0.5) * 0.38 + (t > 0.19 ? click(t - 0.19, 0.12) * 0.32 : 0) + chime(t, 0.5, 420) * 0.18],
  sfx_boss_intro: [1.8, (t) => sine(62, t) * 0.38 * env(t, 1.8, 0.04, 1.55) + chime(t, 1.8, 260) * 0.18 + noise() * 0.05 * env(t, 1.8, 0.02, 1.2)],
};

for (const [name, [dur, fn]] of Object.entries(assets)) {
  writeWav(name, dur, fn);
}
console.log(`Generated ${Object.keys(assets).length} SFX WAV files in ${root}`);
