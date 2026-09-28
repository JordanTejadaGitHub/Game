
// ---- the 10 Memories: small illustrated fragments, 320×180 ----
const MW = 320, MH = 180;
const HOLLOW_BARK = ["#140e14", "#2a2028", "#44363e", "#5e4e56"];
function mSky(img, cols, stars = .0025, seed = 1) {
  for (let y = 0; y < MH; y++) for (let x = 0; x < MW; x++) {
    img.set(x, y, pick(cols, clamp(y / MH + (pnoise(x, y, 60, seed) - .5) * .15, 0, 1), x, y, .9));
    if (y < MH * .6 && hash(x, y, seed + 1) < stars) img.set(x, y, hash(x, y, seed + 2) < .3 ? "#f0f2ff" : "#8a8ac0");
  }
}
function mHill(img, base, amp, cols, seed) {
  for (let x = 0; x < MW; x++) {
    const top = base - pnoise(x, 0, 70, seed) * amp;
    for (let y = Math.floor(top); y < MH; y++) img.set(x, y, pick(cols, clamp((y - top) / 40 + (pnoise(x, y, 8, seed) - .5) * .3, 0, 1), x, y, .6));
  }
}
function mTree(img, x, base, h, canopy, bark = HB6.slice(1), seed = 3) {
  const L = new Img(MW, MH), fn = (xx, yy, nx) => nx < -.3 ? bark[3] : nx > .4 ? bark[0] : bark[1 + (hash(xx, yy >> 1, seed) < .2 ? 0 : 1)];
  stroke(L, x, base, x, base - h * .55, h * .16, h * .1, fn);
  if (canopy) {
    [[0, -.78, .34, .22], [-.26, -.62, .24, .17], [.26, -.62, .24, .17], [0, -.56, .3, .15]].forEach(([dx, dy, rx, ry], k) =>
      blob(L, x + dx * h, base + dy * h, rx * h, ry * h, canopy, { lump: .1, seed: seed + k, tex: .15, rim: true }));
  } else {
    const limb = (x0, y0, a, len, w, d) => { const x1 = x0 + Math.cos(a) * len, y1 = y0 + Math.sin(a) * len; stroke(L, x0, y0, x1, y1, w, Math.max(1, w * .6), fn); if (d > 0) { limb(x1, y1, a - .45, len * .7, w * .6, d - 1); limb(x1, y1, a + .4, len * .66, w * .6, d - 1); } };
    limb(x, base - h * .5, -2.1, h * .28, h * .07, 2); limb(x, base - h * .5, -1.0, h * .3, h * .07, 2);
  }
  img.stamp(L, "#0a0608");
}
function mRootsCut(img, x, y, depth, spread, cols, seed) {
  for (let k = 0; k < 7; k++) {
    let px = x, py = y;
    const dir = (k - 3) * spread;
    for (let i = 1; i <= 14; i++) { const nx = x + dir * i * .9 + Math.sin(i * .6 + k) * 3, ny = y + depth * i / 14; stroke(img, px, py, nx, ny, 3 - i * .15, 3 - i * .16, cols[k % cols.length]); px = nx; py = ny; }
  }
}
function mCreature(img, x, y, col, s = 1) {
  ellipse(img, x, y, 3.4 * s, 2.4 * s, col); ellipse(img, x + 3 * s, y - 2 * s, 1.8 * s, 1.6 * s, col);
  img.set(x + 3 * s, y - 4 * s, col); img.set(x - 2 * s, y + 2.5 * s, col); img.set(x + 2 * s, y + 2.5 * s, col);
}
function mStone(img, x, y, glow) {
  const L = new Img(MW, MH);
  blob(L, x, y, 4, 6, [ST.d1, ST.m, ST.l1, ST.l2], { tex: .1 });
  img.stamp(L, ST.out);
  img.set(x, y - 2, glow ? "#a8f0dc" : ST.d1); img.set(x, y - 1, glow ? "#a8f0dc" : ST.d1);
}
function mEyes(img, x, y) { img.set(x, y, "#e8e0ff"); img.set(x + 3, y, "#e8e0ff"); img.set(x + 1, y, "#8a78c8"); img.set(x + 4, y, "#8a78c8"); }
function mMist(img, y0, col, a, seed) {
  for (let y = y0 - 20; y < y0 + 20; y++) for (let x = 0; x < MW; x++) {
    const n = pnoise(x, y, 30, seed) - Math.abs(y - y0) / 26;
    if (n > .3 && hash(x, y, seed) < (n - .3) * 2) img.set(x, y, CA(col, a));
  }
}
function mDream(img, x, y, r, col) {
  for (let k = 0; k < 34; k++) {
    const a = hash(k, 1, 9) * Math.PI * 2, d = Math.sqrt(hash(k, 2, 9)) * r, px = x + Math.cos(a) * d, py = y + Math.sin(a) * d * .6, al = .55 + hash(k, 3, 9) * .45;
    img.set(px, py, CA(col, al)); if (k % 3 === 0) { img.set(px + 1, py, CA(col, al * .7)); img.set(px, py + 1, CA(col, al * .7)); }
  }
}
function mGlow(img, x, y, r, a = .28) { ellipse(img, x, y, r, r * .85, (xx, yy, dx, dy) => CA("#ffc870", Math.max(0, 1 - Math.hypot(dx, dy)) ** 1.6 * a)); }
const NIGHT = ["#0a0820", "#141030", "#1e1838", "#2a2040"];
// The Heartwood keeps its warm moss-gold; the Hollow, while still healthy, a cool teal.
const GREEN_TREE = ["#121a0c", "#243c16", "#3a5e22", "#5a8030", "#8aa844"];
const HOLLOW_TREE = ["#0e1a1c", "#1a3032", "#284a48", "#3e6a60", "#5e8c7a"];
const GREY_TREE = ["#1a1a22", "#2e2e3a", "#464656", "#646474", "#84849a"];
const MEMORY_SCENES = [
  // 1. Before the Heartwood, there were two trees, and both of them dreamed.
  img => { mSky(img, NIGHT, .003, 11); mHill(img, 150, 18, ["#141e18", "#0c140e"], 12); mGlow(img, 100, 100, 70, .2); mTree(img, 100, 150, 90, GREEN_TREE); mTree(img, 225, 150, 90, HOLLOW_TREE, HB6.slice(1), 5); mDream(img, 100, 50, 30, "#ffd27a"); mDream(img, 225, 50, 30, "#c8b0ff"); mDream(img, 162, 66, 22, "#e8dcff"); },
  // 2. They shared their roots, and one dream grew between them: the forest.
  img => { mSky(img, NIGHT, .002, 21); mHill(img, 118, 8, ["#141e18", "#0c140e"], 22); for (let y = 122; y < MH; y++) for (let x = 0; x < MW; x++) img.set(x, y, pick(["#1a120c", "#120c08", "#0c0806"], (y - 122) / 58, x, y)); mRootsCut(img, 70, 120, 40, 2.2, ["#5e3c20", "#4a2e18"], 23); mRootsCut(img, 250, 120, 40, 2.2, ["#5e3c20", "#4a2e18"], 24); stroke(img, 90, 150, 230, 150, 3, 3, "#8a5e34"); for (let k = 0; k < 7; k++) mTree(img, 120 + k * 14, 120, 26 + (k % 3) * 6, GREEN_TREE, HB6.slice(1), 30 + k); mTree(img, 70, 120, 80, GREEN_TREE); mTree(img, 250, 120, 80, HOLLOW_TREE, HB6.slice(1), 6); },
  // 3. A long drought. The Heartwood's roots went deep; the Hollow's couldn't reach.
  img => { mSky(img, ["#3a1e18", "#6a3a22", "#9a5a2a", "#b87838"], 0, 31); ellipse(img, 250, 40, 16, 16, "#ffd890"); for (let y = 120; y < MH; y++) for (let x = 0; x < MW; x++) { const crack = Math.abs(pnoise(x, y, 12, 32) - .5) < .025; img.set(x, y, crack ? "#3a2014" : pick(["#8a5a34", "#6a4226", "#4a2e1a"], (y - 120) / 60, x, y)); } for (let x = 0; x < MW; x++) img.set(x, 176, "#4a7aa8"); for (let x = 0; x < MW; x++) img.set(x, 177, "#2c4c80"); mRootsCut(img, 90, 120, 55, 1.2, ["#3a2414"], 33); mRootsCut(img, 230, 120, 18, 1.8, ["#3a2414"], 34); mTree(img, 90, 120, 80, ["#2a3a14", "#4a5a1e", "#6a7a2a", "#8a9a3a", "#a8b04c"]); mTree(img, 230, 120, 80, ["#3a2a14", "#5a3e1a", "#7a5424", "#9a6a2e", "#b88a44"], HB6.slice(1), 7); },
  // 4. The creatures followed the Heartwood's shade. The Hollow was left alone, still dreaming.
  img => { mSky(img, NIGHT, .003, 41); mHill(img, 140, 12, ["#141e18", "#0c140e"], 42); mGlow(img, 70, 90, 80); mTree(img, 70, 140, 95, GREEN_TREE); mTree(img, 260, 140, 85, GREY_TREE, HOLLOW_BARK, 8); mDream(img, 260, 60, 24, "#c8b0ff"); for (let k = 0; k < 7; k++) mCreature(img, 110 + k * 18, 146 + (k % 2) * 4, k % 3 ? "#d8c8a8" : "#b8a888"); },
  // 5. The Hollow closed its dream around the last creatures. The dream broke.
  img => { mSky(img, NIGHT, .002, 51); mHill(img, 150, 8, ["#141e18", "#0c140e"], 52); mTree(img, 160, 150, 110, null, HOLLOW_BARK, 9); for (let a = 0; a < Math.PI * 2; a += .02) { const x = 160 + Math.cos(a) * 60, y = 95 + Math.sin(a) * 50; if (Math.sin(a * 7) > -.2) img.set(x, y, CA("#c8b0ff", .8)); } for (const [x0, y0, x1, y1] of [[160, 45, 150, 70], [150, 70, 162, 90], [212, 80, 196, 96], [118, 120, 132, 110]]) stroke(img, x0, y0, x1, y1, 1.2, 1, "#fff8e0"); for (let k = 0; k < 4; k++) mCreature(img, 140 + k * 13, 128, "#8a7aa0"); },
  // 6. Its leaves fell, one by one, and nobody came.
  img => { mSky(img, ["#0c0c1a", "#161626", "#202030", "#2a2a38"], .002, 61); mHill(img, 150, 6, ["#1a1a20", "#101016"], 62); mTree(img, 160, 150, 110, null, HOLLOW_BARK, 10); for (let k = 0; k < 22; k++) { const x = 90 + hash(k, 1, 63) * 140, y = 40 + hash(k, 2, 63) * 112; img.set(x, y, "#c89a4a"); img.set(x + 1, y, "#a87a3a"); img.set(x + 1, y + 1, "#8a5a2a"); img.set(x + 2, y + 1, "#6a4424"); img.set(x, y + 1, "#a87a3a"); } },
  // 7. It dreamed alone in the dark so long that its dreams turned: the first nightmares.
  img => { mSky(img, ["#04040a", "#08081a", "#100c22", "#18122a"], .001, 71); mHill(img, 150, 6, ["#0c0c12", "#08080c"], 72); mTree(img, 160, 150, 110, null, HOLLOW_BARK, 11); mMist(img, 146, "#2a1a44", .7, 73); for (const [x, y] of [[92, 140], [118, 132], [204, 136], [232, 142], [140, 150], [182, 148], [66, 150], [256, 150]]) { ellipse(img, x + 1, y + 1, 7, 8, CA("#0a0612", .85)); mEyes(img, x - 1, y); } },
  // 8. The creatures once carved waystones to mark the path between the two trees.
  img => { mSky(img, NIGHT, .003, 81); mHill(img, 132, 8, ["#141e18", "#0c140e"], 82); mGlow(img, 30, 90, 60, .2); mTree(img, 30, 132, 80, GREEN_TREE); mTree(img, 292, 132, 80, HOLLOW_TREE, HB6.slice(1), 12); for (let x = 50; x < 272; x++) { const y = 150 + Math.sin(x / 30) * 6; for (let d = -3; d <= 3; d++) img.set(x, y + d, pick(["#6a5a48", "#8a7a62", "#a8987a"], .5 - d * .1, x, y + d)); } for (let k = 0; k < 7; k++) { const x = 66 + k * 32; mStone(img, x, 146 + Math.sin(x / 30) * 6 - 6, k < 5); } mCreature(img, 222, 138, "#d8c8a8"); mCreature(img, 236, 140, "#c8b898"); },
  // 9. The Heartwood remembers it promised to come back.
  img => { mSky(img, NIGHT, .003, 91); mHill(img, 140, 16, ["#141e18", "#0c140e"], 92); mGlow(img, 90, 80, 90, .35); mTree(img, 90, 140, 110, GREEN_TREE); for (let k = 0; k < 5; k++) { const x = 72 + k * 9, y = 96 + (k % 2) * 6; img.set(x, y, "#ffd27a"); img.set(x + 1, y, "#fff4c8"); } mTree(img, 280, 132, 40, null, HOLLOW_BARK, 13); mMist(img, 128, "#2a1a44", .5, 93); },
  // 10. The path to the Hollow is still there, under the nightmares.
  img => { mSky(img, ["#06060e", "#0c0a1a", "#140e24", "#1e1430"], .002, 101); mHill(img, 120, 6, ["#10101a", "#0a0a10"], 102); mTree(img, 250, 118, 44, null, HOLLOW_BARK, 14); for (let y = 118; y < MH; y++) { const w = 4 + (y - 118) * .5, cx = 160 + (MH - y) * .6 + Math.sin(y / 9) * 5; for (let x = Math.floor(cx - w); x <= cx + w; x++) img.set(x, y, pick(["#3a3040", "#5a4e58", "#7a6e72"], .5 + (y - 118) / 120, x, y)); } for (let k = 0; k < 5; k++) { const y = 176 - k * 12, x = 160 + (MH - y) * .6 + Math.sin(y / 9) * 5 - 14 - k; mStone(img, x, y, k === 0); } mMist(img, 126, "#2a1a44", .75, 103); for (const [x, y] of [[196, 122], [226, 128], [140, 130], [280, 126]]) mEyes(img, x, y); },
];
function memory(i) { const img = new Img(MW, MH); MEMORY_SCENES[i](img); return img; }
