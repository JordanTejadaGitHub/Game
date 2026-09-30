
// ---- flowers and buds ----
// A petal from (cx, cy) along angle a: an ellipse from the centre out to `len`, lit on its upper side.
function petal(L, cx, cy, a, len, wid, ramp) {
  const ca = Math.cos(a), sa = Math.sin(a), R = len + wid + 1;
  for (let y = Math.floor(cy - R); y <= cy + R; y++) for (let x = Math.floor(cx - R); x <= cx + R; x++) {
    const dx = x + .5 - cx, dy = y + .5 - cy, u = dx * ca + dy * sa, v = -dx * sa + dy * ca;
    if (u < 0) continue;
    const q = ((u - len / 2) / (len / 2)) ** 2 + (v / wid) ** 2;
    if (q > 1) continue;
    const t = clamp(.3 + (u / len) * .5 - (dy / R) * .25 + (q > .7 ? -.25 : 0), 0, 1);
    L.set(x, y, pick(ramp, t, x, y, .4));
  }
}
function flower(L, cx, cy, sec, r, petals, open = 1, rot = 0) {
  const P = SECTION[sec].petals;
  for (let k = 0; k < petals; k++) {
    const a = rot + k / petals * Math.PI * 2 - Math.PI / 2;
    petal(L, cx, cy, a, r * open, Math.max(1.6, r * .42 * open), P);
  }
  ellipse(L, cx, cy, Math.max(1.2, r * .3), Math.max(1.2, r * .3), (x, y, dx, dy) => dy < 0 && dx < .3 ? SECTION[sec].mid : P[2]);
}
function bud(L, cx, cy, sec, swell = 0, lit = false) {
  // Sepals, then a closed teardrop bud; `lit` tints its tip with the section colour.
  const P = SECTION[sec].petals;
  petal(L, cx, cy + 4, -Math.PI / 2 - .7, 6.5, 2, ["#1e2e14", "#2e4418", "#44602a"]);
  petal(L, cx, cy + 4, -Math.PI / 2 + .7, 6.5, 2, ["#1e2e14", "#2e4418", "#44602a"]);
  ellipse(L, cx, cy - 1, 3.4 + swell, 5.2 + swell,(x, y, dx, dy) => dy < -.35 && lit ? (dx < 0 ? P[3] : P[2]) : dx < -.2 ? "#6a7a44" : dx > .45 ? "#2e3e1c" : "#4a5c2c");
}
function haloOut(out, cx, cy, r, sec, a) {
  const [R, G, B] = SECTION[sec].glow.split(",").map(Number);
  ellipse(out, cx, cy, r, r, (x, y, dx, dy) => { const q = Math.hypot(dx, dy); return [R, G, B, Math.round(255 * a * (q < .45 ? .75 : q < .72 ? .4 : .15))]; });  // banded: 3 alpha steps, never a soft blur
}
// One node sprite. state: "locked" | "afford" (f 0-3) | "open" (f 0-3) | "bloom" (f 0-1). size 32 or 48 (Legendary).
function nodeSprite(sec, state, f, big = false) {
  const S = big ? 48 : 32, c = S / 2, out = new Img(S, S), L = new Img(S, S);
  const r = big ? 13 : 9, petals = big ? 8 : 5;
  if (state === "locked") { bud(L, c, c + 2, sec); out.stamp(L, "#0e0a06"); return out; }
  if (state === "afford") {
    haloOut(out, c, c, big ? 20 : 13, sec, [.25, .38, .5, .38][f]);
    bud(L, c, c + 2, sec, [0, .3, .5, .3][f] * .6, true); out.stamp(L, "#0e0a06"); return out;
  }
  if (state === "open") {
    haloOut(out, c, c, (big ? 22 : 14) + f * 2, sec, .35 + f * .15);
    if (f === 0) bud(L, c, c + 2, sec, 1.2, true);
    else flower(L, c, c, sec, r, petals, [0, .45, .75, 1.05][f], f * .1);
    out.stamp(L, "#0e0a06");
    if (f >= 2) for (let k = 0; k < 6; k++) { const a = k / 6 * Math.PI * 2 + f; out.set(c + Math.cos(a) * (r + 3 + f), c + Math.sin(a) * (r + 3 + f), "#fffbe8"); }
    return out;
  }
  // bloom
  haloOut(out, c, c, big ? 22 : 14, sec, f ? .42 : .34);
  if (big) flower(L, c, c, sec, r * .72, petals, 1, Math.PI / petals);
  flower(L, c, c, sec, r, petals, 1, f * .06);
  out.stamp(L, "#0e0a06");
  if (big) for (let k = 0; k < 4; k++) { const a = k * Math.PI / 2 + f * .4; out.set(c + Math.cos(a) * (r + 5), c + Math.sin(a) * (r + 5), "#fffbe8"); }
  out.set(c - 3 + f * 5, c - r + 1, "#ffffff");
  return out;
}

// ---- dream-fruit (Memories): idle glow (0-3), opening (4-7), opened (8) ----
// 48×48; the vine's top is the sprite's top centre (hang it from a limb's underside).
function fruitSprite(f) {
  const S = 48, out = new Img(S, S), L = new Img(S, S), cx = 24, cy = 30;
  for (let y = 0; y < 21; y++) L.set(cx + Math.round(Math.sin(y * .4) * 1.2), y, y % 3 ? LEAFG[2] : LEAFG[1]);
  petal(L, cx + 1, 9, -.4, 6, 2, LEAFG.slice(1)); petal(L, cx - 1, 14, Math.PI + .4, 5, 1.8, LEAFG.slice(1));
  const FR = ["#8a4a1a", "#e0883a", "#ffd27a", "#fff4c8"];
  if (f < 4) {
    haloOut(out, cx, cy, 19, "perks", [.35, .45, .55, .45][f]);
    blob(L, cx, cy, 9, 10, FR, { tex: .05 });
    out.stamp(L, "#3a1a08");
    const sp = [[20, 26], [27, 25], [28, 33], [21, 34]][f]; out.set(sp[0], sp[1], "#ffffff"); out.set(sp[0] + 1, sp[1], "#fff4c8");
    return out;
  }
  if (f < 8) {
    const g = f - 4, gap = [0, 2, 4, 6][g];
    haloOut(out, cx, cy, 19 + g * 2, "perks", .5 + g * .1);
    ellipse(L, cx - gap, cy, 9, 10, (x, y, dx) => x + .5 < cx - gap ? pick(FR, .5 - dx * .3, x, y) : null);
    ellipse(L, cx + gap, cy, 9, 10, (x, y, dx) => x + .5 >= cx + gap ? pick(FR, .45 - dx * .3, x, y) : null);
    out.stamp(L, "#3a1a08");
    for (let y = cy - 9; y <= cy + 9; y++) for (let x = Math.floor(cx - gap + 1); x < cx + gap; x++) out.set(x, y, CA("#fff8d8", .9));
    for (let k = 0; k < g; k++) { out.set(cx + (k % 2 ? 3 : -3), cy - 13 - k * 4, "#fffbe8"); out.set(cx + (k % 2 ? 3 : -3), cy - 12 - k * 4, CA("#ffd27a", .8)); }
    return out;
  }
  // Opened: two empty halves hanging, a faint glow left inside.
  haloOut(out, cx, cy, 15, "perks", .22);
  ellipse(L, cx - 7, cy + 1, 7, 9, (x, y, dx) => x + .5 < cx - 7 ? pick(["#5a2e12", "#a8602a", "#d09048"], .5 - dx * .3, x, y) : (dx < .5 ? "#ffe8b0" : null));
  ellipse(L, cx + 7, cy + 1, 7, 9, (x, y, dx) => x + .5 >= cx + 7 ? pick(["#5a2e12", "#a8602a", "#d09048"], .4 - dx * .3, x, y) : (dx > -.5 ? "#ffe8b0" : null));
  out.stamp(L, "#3a1a08");
  return out;
}

// ---- loadout slots ("Carry into the dream"): 0 locked, 1 empty, 2 filled, 3 filled + selected ----
function slotSprite(state) {
  const out = new Img(64, 64), L = new Img(64, 64), c = 32;
  ellipse(out, c, 57, 24, 5, SHADOW(.35));
  // A round waystone socket seen from above-front.
  ellipse(L, c, c + 2, 26, 26, (x, y, dx, dy) => { const r = Math.hypot(dx, dy); if (r < .66) return null; return pick([ST.d1, ST.m, ST.l1, ST.l2, ST.hi], clamp(.6 - dx * .3 - dy * .45 + (pnoise(x, y, 5, 9) - .5) * .3, 0, 1), x, y); });
  for (let k = 0; k < 8; k++) { const a = k / 8 * Math.PI * 2; L.set(c + Math.cos(a) * 22, c + 2 + Math.sin(a) * 22, ST.d1); }
  blob(L, 12, 44, 6, 3, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
  blob(L, 50, 16, 5, 2.5, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
  out.stamp(L, ST.out);
  const inner = (fill) => ellipse(out, c, c + 2, 16.5, 16.5, fill);
  if (state === 0) {
    inner((x, y, dx, dy) => pick(["#1a1628", "#262038", "#342c48"], .55 - dy * .4, x, y));
    for (let k = -12; k <= 12; k++) { out.set(c + k, c + 2 + Math.round(Math.sin(k * .5) * 3), LEAFG[1]); if (k % 4 === 0) out.set(c + k, c + 1 + Math.round(Math.sin(k * .5) * 3), LEAFG[3]); }
    ellipse(out, c, c + 2, 3, 3.5, (x, y, dx, dy) => dy < 0 ? "#8a7a5c" : "#5a4a38");
    return out;
  }
  inner((x, y, dx, dy) => pick(["#0c0a16", "#141024", "#1c1630"], .4 - dy * .4, x, y));
  if (state === 1) {
    for (let a = 0; a < Math.PI * 2; a += .07) out.set(c + Math.cos(a) * 9, c + 2 + Math.sin(a) * 9, CA("#6a6090", .8));
    return out;
  }
  const a = state === 3 ? .95 : .7;
  inner((x, y, dx, dy) => { const r = Math.hypot(dx, dy); return r > .86 ? CA("#ffd27a", a) : CA("#3a2a18", .9 - r * .3); });
  for (let k = 0; k < 16; k++) { const t = k / 16 * Math.PI * 2; out.set(c + Math.cos(t) * 18, c + 2 + Math.sin(t) * 18, CA("#fff0b0", a)); }
  if (state === 3) haloOut(out, c, c + 2, 31, "perks", .35);
  return out;
}
