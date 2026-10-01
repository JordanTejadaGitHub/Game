
// ---- small icons (32×32, outlined like every other sprite) ----
const INK = "#120c10";
const CLAY = ["#4a2e1c", "#7a4e2c", "#a8703e", "#d0a060"];
const PARCH = ["#5a4a3a", "#9a8468", "#cdb892", "#efe2c2"];
const DREAMC = ["#2a1848", "#553488", "#8a64c8", "#c8b0f0"];
const GOLDC = ["#7a4a10", "#c08020", "#f0c050", "#fff0b0"];
const DEWC = ["#1e3058", "#2c4c80", "#3f6aa8", "#6ab0e8", "#bfe8ff"];
function icon(draw) { const out = new Img(32, 32), L = new Img(32, 32); draw(L, out); const o = new Img(32, 32); o.stamp(L, INK); o.put(out); return o; }
function drop(L, cx, cy, s) {
  for (let y = Math.floor(cy - s * 2.2); y <= cy + s; y++) for (let x = Math.floor(cx - s - 1); x <= cx + s + 1; x++) {
    const dx = x + .5 - cx, dy = y + .5 - cy, inCirc = dx * dx + dy * dy <= s * s, inTip = dy < 0 && dy > -s * 2.2 && Math.abs(dx) <= s * (1 + dy / (s * 2.2));
    if (inCirc || inTip) L.set(x, y, pick(DEWC.slice(1), clamp(.55 - dx / s * .35 - dy / s * .25, 0, 1), x, y, .4));
  }
  L.set(cx - s * .4, cy - s * .3, DEWC[4]);
}
function card(L, x, y, w, h, ramp, emblem) {
  for (let yy = y; yy < y + h; yy++) for (let xx = x; xx < x + w; xx++) {
    const edge = xx === x || yy === y || xx === x + w - 1 || yy === y + h - 1;
    L.set(xx, yy, edge ? ramp[1] : pick(ramp.slice(2), .5 - (xx - x) / w * .3 - (yy - y) / h * .3 + .3, xx, yy, .3));
  }
  if (emblem) emblem(x + w / 2, y + h / 2);
}
function rays(out, cx, cy, r, col) { for (let k = 0; k < 8; k++) { const a = k / 8 * Math.PI * 2; out.set(cx + Math.cos(a) * r, cy + Math.sin(a) * r, col); } }
function sprout(L, x, y, h) { for (let i = 0; i < h; i++) L.set(x, y - i, LEAFG[2]); petal(L, x, y - h, -Math.PI * .8, 5, 1.8, LEAFG.slice(1)); petal(L, x, y - h, -Math.PI * .2, 5, 1.8, LEAFG.slice(1)); }
function flame(L, cx, cy) { drop(L, cx, cy, 3); for (let y = cy - 6; y <= cy + 3; y++) for (let x = cx - 3; x <= cx + 3; x++) if (L.alpha(x, y)) L.set(x, y, pick(["#c0501a", "#f0902a", "#ffd060", "#fff4c0"], clamp(.8 - (y - cy + 6) / 10 - Math.abs(x - cx) * .1, 0, 1), x, y)); }

const PERK_ICONS = {
  morning_stores: () => icon(L => { blob(L, 16, 22, 8, 7, CLAY, { tex: .08 }); for (let x = 11; x <= 21; x++) { L.set(x, 15, CLAY[3]); L.set(x, 16, CLAY[1]); } drop(L, 16, 10, 3); }),
  rich_dew: () => icon((L, o) => { drop(L, 16, 19, 7); rays(o, 16, 14, 13, "#e8f6ff"); o.set(25, 8, "#ffffff"); }),
  rested_roots: () => icon((L, o) => { let px = 16, py = 8; for (let i = 0; i < 40; i++) { const a = i * .35, r = 10 - i * .22, x = 16 + Math.cos(a) * r, y = 18 + Math.sin(a) * r; stroke(L, px, py, x, y, 3, 3, (xx, yy, nx) => nx < 0 ? HB6[4] : HB6[3]); px = x; py = y; } sprout(L, 16, 8, 3); o.set(25, 5, "#cfd8ff"); o.set(26, 5, "#cfd8ff"); o.set(25, 7, "#cfd8ff"); o.set(26, 6, "#cfd8ff"); }),
  seed_pouch: () => icon(L => { blob(L, 16, 20, 9, 8, PARCH, { tex: .1 }); for (let x = 12; x <= 20; x++) L.set(x, 12, PARCH[1]); blob(L, 16, 10, 4, 2, PARCH); ellipse(L, 16, 21, 2.5, 3.2, (x, y, dx, dy) => dy < 0 ? GOLDC[3] : GOLDC[2]); }),
  clear_sight: () => icon((L, o) => { for (let y = 16; y <= 26; y++) for (let x = 7; x <= 25; x++) { const nx = (x - 16) / 9; if (Math.abs(nx) <= 1) L.set(x, y, nx < -.3 ? HB6[4] : nx > .4 ? HB6[2] : HB6[3]); } ellipse(L, 16, 16, 9, 4, (x, y, dx, dy) => Math.floor(Math.hypot(dx, dy) * 4) % 2 ? "#d8b484" : "#b08050"); sprout(L, 19, 15, 3); rays(o, 16, 12, 13, "#fff0b0"); }),
  sprout_bed: () => icon(L => { ellipse(L, 16, 25, 12, 5, (x, y, dx, dy) => pick(["#3a2616", "#5a3a22", "#7a5234"], .5 - dy * .4, x, y)); sprout(L, 11, 22, 6); sprout(L, 21, 22, 8); }),
  kindling: () => icon(L => { card(L, 8, 5, 16, 22, DREAMC, (cx, cy) => flame(L, cx, cy + 2)); }),
  early_bloom: () => icon(L => { for (let y = 18; y < 29; y++) L.set(16, y, LEAFG[2]); petal(L, 16, 24, -Math.PI * .85, 6, 2, LEAFG.slice(1)); flower(L, 16, 13, "perks", 8, 5, .8); }),
  early_light: () => icon((L, o) => { ellipse(L, 16, 16, 6, 6, (x, y, dx, dy) => pick(GOLDC, .6 - dx * .3 - dy * .3, x, y)); for (let k = 0; k < 8; k++) { const a = k / 8 * Math.PI * 2; stroke(L, 16 + Math.cos(a) * 8.5, 16 + Math.sin(a) * 8.5, 16 + Math.cos(a) * 12.5, 16 + Math.sin(a) * 12.5, 2, 1.2, GOLDC[2]); } }),
  first_care: () => icon((L, o) => { blob(L, 15, 20, 8, 6, ["#3a4a5a", "#5a6e82", "#8aa0b4", "#b8ccdc"], { tex: .05 }); stroke(L, 21, 18, 28, 12, 2.2, 1.6, "#5a6e82"); stroke(L, 9, 16, 7, 21, 2, 2, "#5a6e82"); drop(o, 28, 19, 1.6); drop(o, 26, 25, 1.4); }),
  deep_taproot: () => icon(L => { let px = 16, py = 10; for (let i = 1; i <= 18; i++) { const x = 16 + Math.sin(i * .6) * 2.5, y = 10 + i; stroke(L, px, py, x, y, 4.5 - i * .18, 4.5 - i * .2, (xx, yy, nx) => nx < 0 ? HB6[4] : HB6[3]); px = x; py = y; } stroke(L, 15, 20, 9, 25, 2, 1.4, HB6[3]); stroke(L, 17, 23, 23, 28, 2, 1.4, HB6[3]); sprout(L, 16, 10, 3); }),
  second_thoughts: () => icon((L, o) => { card(L, 5, 9, 13, 18, DREAMC); card(L, 14, 5, 13, 18, DREAMC); for (let a = .2; a < 5.6; a += .15) o.set(16 + Math.cos(a) * 13, 16 + Math.sin(a) * 13, "#e8dcff"); o.set(27, 11, "#e8dcff"); o.set(28, 12, "#e8dcff"); o.set(26, 12, "#e8dcff"); }),
  let_go: () => icon((L, o) => { card(L, 9, 8, 14, 19, DREAMC); for (let k = 0; k < 3; k++) { o.set(4, 12 + k * 4, "#c8b0f0"); o.set(5, 12 + k * 4, "#8a64c8"); } petal(o, 25, 6, Math.PI * .75, 6, 1.6, LEAFG.slice(1)); }),
  omen_reader: () => icon((L, o) => { ellipse(L, 15, 16, 10, 10, (x, y, dx, dy) => Math.hypot(dx - .45, dy + .15) < .78 ? null : pick(["#8a88b0", "#b8b8d8", "#e8e8ff"], .6 - dx * .3 - dy * .3, x, y)); o.set(24, 9, "#fff6d0"); o.set(23, 10, "#fff6d0"); o.set(25, 10, "#fff6d0"); o.set(24, 11, "#fff6d0"); o.set(24, 10, "#ffffff"); }),
  wider_dreams: () => icon(L => { [[3, 10], [8, 7], [13, 5], [18, 7]].forEach(([x, y]) => card(L, x, y, 11, 17, DREAMC)); }),
};
const FAMILY_ICONS = {
  sporeling: () => icon(L => { blob(L, 16, 18, 10, 9, ["#3a1e4a", "#6a3a86", "#9a6ac0", "#c8a0e8"], { tex: .05 }); L.set(13, 18, INK); L.set(19, 18, INK); L.set(14, 21, "#f49aa8"); L.set(18, 21, "#f49aa8"); sprout(L, 16, 9, 2); }),
  firefly_jar: () => icon((L, o) => { blob(L, 16, 19, 8, 9, ["#2a3a44", "#46606e", "#6a8a98", "#a8c8d4"], { tex: .05 }); for (let x = 10; x <= 22; x++) { L.set(x, 9, CLAY[2]); L.set(x, 10, CLAY[1]); } [[13, 17], [18, 21], [17, 15], [14, 23]].forEach(([x, y]) => { L.set(x, y, "#fff27a"); L.set(x + 1, y, "#d8e060"); }); }),
  dewdrop: () => icon(L => { drop(L, 16, 20, 8); L.set(13, 20, INK); L.set(19, 20, INK); L.set(16, 23, "#1e3058"); }),
  pebbling: () => icon(L => { blob(L, 16, 19, 11, 8, [ST.d1, ST.m, ST.l1, ST.l2, ST.hi], { tex: .08, rim: true }); blob(L, 14, 13, 6, 2.5, LEAFG.slice(1, 4), { tex: .2 }); L.set(13, 19, INK); L.set(19, 19, INK); }),
  rootling: () => icon(L => { let px = 8, py = 26; for (let i = 0; i < 30; i++) { const a = i * .3, r = 9 - i * .22, x = 17 + Math.cos(a) * r, y = 17 + Math.sin(a) * r; stroke(L, px, py, x, y, 3.2, 3, (xx, yy, nx) => nx < 0 ? HB6[4] : HB6[3]); px = x; py = y; } sprout(L, 17, 8, 2); }),
  bellflower: () => icon(L => { stroke(L, 8, 5, 18, 10, 1.6, 1.4, LEAFG[2]); for (let y = 10; y <= 24; y++) { const w = 3 + (y - 10) * .45; for (let x = Math.floor(18 - w); x <= 18 + w; x++) L.set(x, y, pick(["#2a3a7a", "#4a62b0", "#7a96e0", "#b8ccff"], clamp(.6 - (x - 18) / w * .35 - (y - 17) / 14 * .2, 0, 1), x, y)); } for (let x = 11; x <= 25; x += 2) L.set(x, 25, "#4a62b0"); L.set(18, 26, GOLDC[2]); }),
  acorn: () => icon(L => { blob(L, 16, 20, 7, 8, ["#6a3a18", "#9a5a2a", "#c88a44", "#e8b870"], { tex: .05 }); ellipse(L, 16, 13, 9, 4.5, (x, y) => (x + y) % 3 === 0 ? HB6[2] : HB6[3]); for (let y = 6; y < 10; y++) L.set(16, y, HB6[3]); }),
  nestling: () => icon(L => { ellipse(L, 16, 16, 5, 6, (x, y, dx, dy) => pick(["#c8c0b0", "#e8e2d4", "#fffaf0"], .6 - dx * .3 - dy * .3, x, y)); for (let k = 0; k < 40; k++) { const a = Math.PI * (hash(k, 1, 3) * .9 + .05), r = 8 + hash(k, 2, 3) * 4; stroke(L, 16 + Math.cos(a) * r, 18 + Math.sin(a) * r * .55, 16 - Math.cos(a) * r * .6, 21 + Math.sin(a) * 3, 1.3, 1.2, k % 2 ? HB6[3] : HB6[4]); } }),
  whirligig: () => icon(L => { petal(L, 15, 20, -Math.PI * .8, 13, 3.4, ["#6a4a24", "#a07840", "#d0a868", "#f0d8a0"]); petal(L, 17, 20, -Math.PI * .2, 13, 3.4, ["#6a4a24", "#a07840", "#d0a868", "#f0d8a0"]); ellipse(L, 16, 21, 3.5, 3, (x, y, dx) => dx < 0 ? "#c88a44" : "#8a5a2a"); }),
};
const CARD_ICONS = {
  storm: e => { for (const [x0, y0, x1, y1] of [[18, 7, 13, 16], [13, 16, 19, 16], [19, 16, 14, 25]]) stroke(e, x0, y0, x1, y1, 2.4, 2, GOLDC[3]); },
  spores_and_reactions: e => { for (const [x, y, r] of [[13, 13, 3], [19, 16, 3.5], [14, 21, 2.5]]) ellipse(e, x, y, r, r, (xx, yy, dx, dy) => dy < 0 ? "#d8f4a8" : "#8ac860"); e.set(20, 10, GOLDC[3]); e.set(21, 9, GOLDC[3]); },
  keen_edges: e => { ellipse(e, 16, 16, 7, 7, (x, y, dx, dy) => Math.hypot(dx + .45, dy - .1) < .8 ? null : pick(["#b8b8d8", "#e8e8ff"], .5 - dy * .3, x, y)); },
  tending: e => { for (let a = 0; a < Math.PI * 2; a += .12) { e.set(16 + Math.cos(a) * 6, 18 + Math.sin(a) * 3.5, PARCH[3]); } sprout(e, 16, 20, 7); },
  overgrowth: e => { for (const a of [-2.6, -1.9, -1.2, -.5]) petal(e, 16, 23, a, 8, 2.2, LEAFG.slice(1)); },
  lone_lantern: e => { for (let y = 10; y <= 22; y++) for (let x = 12; x <= 20; x++) e.set(x, y, (x === 12 || x === 20 || y === 10 || y === 22) ? HB6[2] : pick(GOLDC.slice(1), .9 - (y - 10) / 14, x, y)); for (let x = 14; x <= 18; x++) e.set(x, 8, HB6[3]); e.set(16, 7, HB6[3]); },
  the_long_way: e => { let px = 10, py = 25; for (let i = 1; i <= 20; i++) { const y = 25 - i * .85, x = 16 + Math.sin(i * .55) * 6; stroke(e, px, py, x, y, 3.2 - i * .08, 3 - i * .08, PARCH[3]); px = x; py = y; } },
  bittersweet: e => { ellipse(e, 16, 17, 6, 6, (x, y, dx, dy) => dx < 0 ? pick(["#8a1a2a", "#c83a4a", "#f07a8a"], .6 - dx * .3 - dy * .3, x, y) : pick(["#1a1420", "#2c2438", "#40364c"], .5 - dy * .3, x, y)); stroke(e, 16, 11, 18, 6, 1.4, 1.2, LEAFG[2]); },
  woven: e => { for (let i = 0; i < 3; i++) { const y = 11 + i * 5; stroke(e, 9, y, 23, y + 3, 1.6, 1.4, i % 2 ? GOLDC[3] : "#c8a8ff"); stroke(e, 11 + i * 5, 8, 14 + i * 5, 25, 1.6, 1.4, i % 2 ? "#c8a8ff" : GOLDC[3]); } },
  deep_poison: e => { ellipse(e, 16, 19, 5.5, 5.5, (x, y, dx, dy) => Math.hypot(dx + .4, dy + .4) < .35 ? "#d8b8ff" : pick(["#2a1438", "#4a2468", "#7a44a0"], .55 - dx * .3 - dy * .3, x, y)); for (let y = 8; y <= 13; y++) e.set(16 + (13 - y) * .3, y, LEAFG[2]); stroke(e, 16, 12, 21, 9, 1.3, 1, LEAFG[1]); },
  kinship: e => { sprout(e, 12, 24, 10); sprout(e, 20, 24, 10); for (const [x, y] of [[15, 12], [17, 12], [14, 13], [18, 13], [16, 15]]) e.set(x, y, "#f07a8a"); e.set(16, 14, "#f07a8a"); e.set(15, 14, "#f07a8a"); e.set(17, 14, "#f07a8a"); },
  seeds: e => { for (const [x, y] of [[11, 20], [16, 16], [21, 20]]) ellipse(e, x, y, 3, 4, (xx, yy, dx, dy) => pick(["#6a4a1c", "#b88a3a", "#f2d27a"], .55 - dx * .3 - dy * .35, xx, yy)); for (let y = 8; y <= 12; y++) e.set(16, y, LEAFG[2]); stroke(e, 16, 10, 20, 7, 1.2, 1, LEAFG[1]); },
  quiet_ones: e => { for (let x = 9; x <= 23; x++) { const d = Math.abs(x - 16) / 7, y = 18 + Math.round(Math.sqrt(Math.max(0, 1 - d * d)) * 5); for (let yy = 18; yy <= y; yy++) e.set(x, yy, yy === y ? PARCH[1] : PARCH[3]); } ellipse(e, 16, 12, 2.5, 3.5, (xx, yy, dx, dy) => pick(["#3a7ab8", "#7ab8e8", "#d8f0ff"], .5 - dx * .3 - dy * .4, xx, yy)); },
  // The lean Cards limb (meta_design.md Section 3, 2026-09-30): first-pass icons, Meta Game Asset may repaint.
  swift: e => { for (const [y, l] of [[11, 9], [16, 12], [21, 9]]) stroke(e, 22 - l, y, 22, y, 1.8, 1.4, y === 16 ? GOLDC[3] : PARCH[3]); for (const [x0, y0, x1, y1] of [[20, 12, 25, 16], [25, 16, 20, 20]]) stroke(e, x0, y0, x1, y1, 1.8, 1.6, GOLDC[3]); },
  wide_reach: e => { for (const [r, c] of [[9, "#3a7ab8"], [6, "#7ab8e8"], [3, "#d8f0ff"]]) for (let a = 0; a < Math.PI * 2; a += .1) e.set(16 + Math.cos(a) * r, 17 + Math.sin(a) * r * .6, c); e.set(16, 17, "#ffffff"); },
  daring: e => { petal(e, 16, 25, -Math.PI / 2, 16, 4.2, ["#5a1418", "#9a2a28", "#d0503a", "#f08a6a"]); for (let y = 12; y <= 24; y++) e.set(16, y, "#5a1418"); },
  hedgerows: e => { for (let x = 8; x <= 24; x += 4) ellipse(e, x, 19, 3, 5, (xx, yy, dx, dy) => pick(LEAFG.slice(0, 3), .55 - dx * .3 - dy * .35, xx, yy)); for (const [x, y] of [[10, 13], [14, 12], [18, 12], [22, 13], [12, 24], [20, 24]]) e.set(x, y, PARCH[1]); },
  reclaiming: e => { for (let y = 17; y <= 25; y++) for (let x = 10; x <= 22; x++) e.set(x, y, y === 17 ? "#e8b870" : pick(["#6a3a18", "#9a5a2a", "#c88a44"], .6 - (x - 16) / 12, x, y)); for (let a = 0; a < Math.PI * 2; a += .3) e.set(16 + Math.cos(a) * 3, 17 + Math.sin(a) * .8, "#9a5a2a"); sprout(e, 16, 17, 7); },
};
function cardIcon(key) {
  return icon((L, o) => {
    card(L, 10, 3, 17, 23, DREAMC.map(c => c));
    const E = new Img(32, 32);
    card(L, 5, 6, 17, 23, DREAMC);
    CARD_ICONS[key](E);
    for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) if (E.alpha(x, y)) L.set(x - 2, y + 1, E.get(x, y));
  });
}
