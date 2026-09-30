
// ---------- The secret sixth waystone (milestone "The Heartwood in full bloom", meta_design.md) ----------
// Never drawn in grove_tree.png: it stays hidden until every Grove node is owned, then rises out of the
// roots at the Hollow's threshold. World sprites are 96×96 with the stone's centre at SIXTH_ANCHOR
// (draw a frame at loadout_stones[5] − SIXTH_ANCHOR).
const SECRET_STONE = [640, 893];
const SIXTH_CELL = 96, SIXTH_ANCHOR = [48, 60], SIXTH_RISE_FRAMES = 24, SIXTH_IDLE_FRAMES = 4;
const ease = t => { t = clamp(t, 0, 1); return t * t * (3 - 2 * t); };
// The stone itself: like the other five, a touch larger, the Hollow's arch carved in gold on its
// face and a starlight rim along its lit edge. `twinkle` picks which rim stars are lit.
function sixthStone(img, cx, cy, twinkle, clipY = 1e9, glow = 1) {
  const S = new Img(img.w, img.h), O = new Img(img.w, img.h);
  blob(S, cx, cy, 18, 15, [ST.d1, ST.m, ST.l1, ST.l2, ST.hi], { tex: .1, rim: true, seed: 6 });
  blob(S, cx - 7, cy - 10, 8, 3, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
  O.stamp(S, ST.out);
  // The carved arch: a doorway outline in Gold with a warm light inside it.
  for (let y = -7; y <= 6; y++) for (let x = -5; x <= 5; x++) {
    const inside = Math.abs(x) <= 4 && (y >= -2 || Math.hypot(x, (y + 2) * 1.1) <= 4.5), edge = inside && (Math.abs(x) === 4 || (y < -2 && Math.hypot(x, (y + 2) * 1.1) > 3.4) || y === 6);
    if (!inside) continue;
    O.set(cx + x, cy + 2 + y, edge ? HW.Gold : CA(y > 1 ? HW.Glow : HW.Ember, .55 + .45 * glow));
  }
  O.set(cx, cy + 5, HW.Heartlight);
  // Starlight rim: moonlit pixels along the upper-left edge, and three little stars that twinkle.
  for (let a = Math.PI * 1.05; a < Math.PI * 1.75; a += .05) O.set(cx + Math.cos(a) * 17.5, cy + Math.sin(a) * 14.5, HW.Moonlight);
  [[-15, -9], [14, -11], [17, 3]].forEach(([dx, dy], k) => {
    const lit = (twinkle + k) % 3 === 0;
    O.set(cx + dx, cy + dy, lit ? HW.Moonlight : HW.Mist);
    if (lit) for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) O.set(cx + dx + a, cy + dy + b, HW.Wraithlight);
  });
  for (let y = 0; y < O.h && y <= clipY; y++) for (let x = 0; x < O.w; x++) if (O.alpha(x, y)) img.set(x, y, O.get(x, y));
}
// Two roots that lie across the spot and part to let the stone through (0 = closed, 1 = open).
function partingRoots(img, cx, groundY, open) {
  const L = new Img(img.w, img.h), gap = open * 22;
  const fn = barkBig(66);
  stroke(L, cx - 40, groundY + 2, cx - 4 - gap, groundY - 5 + open * 3, 8, 5, fn);
  stroke(L, cx + 40, groundY + 3, cx + 4 + gap, groundY - 4 + open * 3, 8, 5, fn);
  for (let x = 0; x < L.w; x++) for (let y = 1; y < L.h; y++) if (L.alpha(x, y) && !L.alpha(x, y - 1) && hash(x, y, 67) < .5) L.set(x, y, LEAFG[1 + (x % 2)]);  // moss on top
  img.stamp(L, HB6[0]);
}
function sixthRiseFrame(f) {
  const img = new Img(SIXTH_CELL, SIXTH_CELL), [cx, cy] = SIXTH_ANCHOR, groundY = cy + 15;
  const open = ease(f / 6), rise = ease((f - 5) / 10), flash = f < 12 ? 0 : f <= 15 ? (f - 11) / 4 : Math.max(0, 1 - (f - 15) / 8);
  // Soft ground shadow and, once the stone is up, the soil pushed aside around it.
  ellipse(img, cx, groundY + 1, 24, 5, SHADOW(.4));
  if (rise > 0) ellipse(img, cx, groundY, 20 + rise * 3, 4, (x, y, dx, dy) => pick([HW.Root, HW.Bark, HW.Loam], .4 - dy * .4, x, y, .6));
  // A crack of golden light opens between the roots before the stone appears.
  if (f >= 2 && f <= 9) {
    const a = Math.min(1, (f - 1) / 4) * (f > 7 ? (10 - f) / 3 : 1);
    ellipse(img, cx, groundY - 1, 4 + open * 14, 2, (x, y, dx, dy) => CA(Math.abs(dx) < .4 ? HW.Heartlight : HW.Glow, a * (1 - Math.abs(dx))));
    for (let k = 0; k < 6; k++) img.set(cx + (hash(k, f, 68) - .5) * 30, groundY - 3 - hash(k, 1, 68) * (f - 1) * 3, HW.Loam);  // crumbs thrown up
  }
  // The stone pushes up through the soil (drawn only above the ground line).
  if (rise > 0) sixthStone(img, cx, cy + (1 - rise) * 32, f % 3, groundY, 1);
  partingRoots(img, cx, groundY, open);
  // The light: a burst when it arrives, settling into a soft glow; sparkles fly up and fade.
  const glowR = 26 + flash * 14, glowA = .18 + flash * .35;
  if (f >= 12) ellipse(img, cx, cy + 2, glowR, glowR * .85, (x, y, dx, dy) => { const r = Math.hypot(dx, dy); return r > 1 ? null : CA(r < .35 ? HW.Heartlight : HW.Glow, glowA * (1 - r) ** 1.5); });
  if (f >= 13 && f <= 22) for (let k = 0; k < 10; k++) {
    const a = hash(k, 2, 69) * Math.PI * 2, d = 14 + (f - 13) * 3 * (.6 + hash(k, 3, 69) * .6), fade = 1 - (f - 13) / 10;
    img.set(cx + Math.cos(a) * d, cy + Math.sin(a) * d * .7 - (f - 13) * 1.5, CA(k % 3 ? HW.Glow : HW.Moonlight, fade));
  }
  return img;
}
// At rest: the stone between its parted roots, a soft glow, the rim stars taking turns.
function sixthIdleFrame(f) {
  const img = new Img(SIXTH_CELL, SIXTH_CELL), [cx, cy] = SIXTH_ANCHOR, groundY = cy + 15;
  ellipse(img, cx, groundY + 1, 24, 5, SHADOW(.4));
  ellipse(img, cx, groundY, 23, 4, (x, y, dx, dy) => pick([HW.Root, HW.Bark, HW.Loam], .4 - dy * .4, x, y, .6));
  sixthStone(img, cx, cy, f, groundY, .85 + (f % 2) * .15);
  partingRoots(img, cx, groundY, 1);
  ellipse(img, cx, cy + 2, 26, 22, (x, y, dx, dy) => { const r = Math.hypot(dx, dy); return r > 1 ? null : CA(HW.Glow, (.14 + (f % 2) * .04) * (1 - r) ** 1.5); });
  return img;
}
// Its loadout slot (UI, 64×64 like loadout_slots.png): 0 empty socket, 1 filled, 2 filled + selected.
// The same socket as the other five, with a starlight ring and the Hollow's arch carved at its top.
function sixthSlot(state) {
  const out = slotSprite(state + 1), c = 32;
  for (let a = 0; a < Math.PI * 2; a += .045) {
    const x = c + Math.cos(a) * 25.5, y = c + 2 + Math.sin(a) * 25.5;
    if (Math.sin(a) < -.93) continue;  // the arch sits here
    out.set(x, y, Math.cos(a - 3.9) > .6 ? HW.Moonlight : HW.Wraithlight);
  }
  [[8, 10], [55, 14], [58, 46], [7, 50]].forEach(([x, y], k) => { out.set(x, y, HW.Moonlight); if (k % 2 === 0) for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) out.set(x + a, y + b, HW.Wraithlight); });
  for (let y = -5; y <= 2; y++) for (let x = -3; x <= 3; x++) {
    const inside = Math.abs(x) <= 3 && (y >= -2 || Math.hypot(x, y + 2) <= 3.2);
    if (inside) out.set(c + x, 6 + y, Math.abs(x) === 3 || Math.hypot(x, y + 2) > 2.4 && y < -2 ? HW.Gold : HW.Glow);
  }
  return out;
}
