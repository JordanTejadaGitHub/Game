
// ---------- Memory Wardens: their Grove blooms and their family-pick card border ----------
// The three Memory Warden nodes (memory_white_stag / memory_pond_keeper / memory_moon_moth, free blooms
// on the Families limb, grown the first time their boss is dispelled) use this sheet instead of the
// Families row of grove_nodes.png: same 32×32 cell and the same 11 columns, one row per Warden.
const MEMORY_WARDENS = ["memory_white_stag", "memory_pond_keeper", "memory_moon_moth"];
// The boss's sign in the flower's heart (5×5, centred): antlers, a ripple, moth wings.
const MEMORY_MOTIFS = {
  memory_white_stag: [[-2, -2], [-2, -1], [-1, 0], [0, 0], [1, 0], [2, -1], [2, -2], [0, 1], [0, 2], [-2, -3], [2, -3], [-3, -2], [3, -2]],
  memory_pond_keeper: [[-2, 0], [-1, -1], [0, -1], [1, -1], [2, 0], [1, 1], [0, 1], [-1, 1], [0, 0], [-3, 1], [3, 1]],
  memory_moon_moth: [[0, -2], [0, -1], [0, 0], [0, 1], [-1, -1], [-2, -2], [-2, -1], [-2, 0], [1, -1], [2, -2], [2, -1], [2, 0], [-1, 1], [1, 1]],
};
const MEMORY_MOTIF_COLOUR = { memory_white_stag: "Moonlight", memory_pond_keeper: "Dewlight", memory_moon_moth: "Wraithlight" };
function memoryNodeSprite(id, state, f) {
  const out = nodeSprite("families", state, f), c = 16, earned = state === "open" && f >= 2 || state === "bloom";
  // A dotted gold ring round the flower (only once it opens), turning slowly.
  if (earned) for (let k = 0; k < 10; k++) { const a = k / 10 * Math.PI * 2 + f * .3; out.set(c + Math.cos(a) * 12.5, c + Math.sin(a) * 12.5, k % 2 ? HW.Gold : HW.Glow); }
  // The boss's sign in the flower's heart.
  if (earned) for (const [x, y] of MEMORY_MOTIFS[id]) out.set(c + x, c + y, HW[MEMORY_MOTIF_COLOUR[id]]);
  // A little dream-fruit hanging at the lower right: gold once earned, a dim bud before.
  const fx = 25, fy = 25;
  out.set(fx - 1, fy - 4, LEAFG[2]); out.set(fx, fy - 3, LEAFG[1]);
  ellipse(out, fx, fy, 2.6, 3, (x, y, dx, dy) => earned ? (dx < 0 && dy < 0 ? HW.Heartlight : dy > .3 ? HW.Ember : HW.Gold) : (dy < 0 ? HW.Dusk : HW.Night));
  return out;
}
const memoryNodeRow = id => strip([memoryNodeSprite(id, "locked", 0), ...[0, 1, 2, 3].map(f => memoryNodeSprite(id, "afford", f)),
  ...[0, 1, 2, 3].map(f => memoryNodeSprite(id, "open", f)), memoryNodeSprite(id, "bloom", 0), memoryNodeSprite(id, "bloom", 1)]);

// The family pick's Memory Warden card border (screens_ui.md "Memory Warden card"): a gold frame drawn
// OVER the card (transparent middle), with a soft gold glow that spills MEMORY_BLEED px outside it and a
// dream-fruit hanging from the top centre. 274×324 = the 250×300 card + the bleed on every side.
// 9-slice, MEMORY_MARGIN on every side; the card is always 250 wide, so only the left and right
// edges repeat when it grows taller (their vine repeats every 24 px). Four frames: a slow glow pulse.
const MEMORY_BLEED = 12, MEMORY_CARD = [250, 300], MEMORY_MARGIN = 42, MEMORY_CARD_FRAMES = 4;
function memoryCardBorder(f) {
  const b = MEMORY_BLEED, W = MEMORY_CARD[0] + 2 * b, H = MEMORY_CARD[1] + 2 * b, out = new Img(W, H), pulse = [0, .5, 1, .5][f];
  const edge = (x, y) => Math.min(x - b, y - b, W - 1 - b - x, H - 1 - b - y);  // <0 outside the card
  // The glow: palette gold at stepped alpha, strongest right at the card's edge.
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const d = edge(x, y);
    if (d < 0) { const t = 1 + d / b; if (t > 0) out.set(x, y, CA(HW.Gold, Math.round((.24 + pulse * .1) * t * t * 20) / 20)); }
    else if (d < 10) out.set(x, y, CA(HW.Glow, Math.round((.14 + pulse * .06) * (1 - d / 10) * 20) / 20));
  }
  // The frame: a 3 px gold band (lit top-left) with a thin Ember line inside it.
  for (let y = b; y < H - b; y++) for (let x = b; x < W - b; x++) {
    const d = edge(x, y);
    if (d > 4) continue;
    const lit = x - b < 3 || y - b < 3;
    out.set(x, y, d === 4 ? HW.Ember : d === 0 ? (lit ? HW.Glow : HW.Ember) : lit ? HW.Gold : d === 3 ? HW.Ember : HW.Gold);
  }
  // A gold vine down each side with small leaves, repeating every 24 px (tiles with the 9-slice).
  for (const side of [0, 1]) for (let y = MEMORY_MARGIN - 6; y < H - MEMORY_MARGIN + 6; y++) {  // the whole stretched band (240 px = 10 repeats)
    const x0 = side ? W - b - 9 : b + 8, p = ((y - MEMORY_MARGIN) % 24 + 24) % 24, wob = Math.round(Math.sin(p / 24 * Math.PI * 2) * 1.5);
    out.set(x0 + wob, y, HW.Gold);
    if (p === 6 || p === 18) { const s = p === 6 ? 1 : -1; out.set(x0 + wob + s, y - 1, LEAFG[3]); out.set(x0 + wob + 2 * s, y - 1, LEAFG[2]); out.set(x0 + wob + s, y, LEAFG[2]); }
  }
  // Corner flourishes: a curl of gold with a bud.
  for (const [sx, sy] of [[1, 1], [-1, 1], [1, -1], [-1, -1]]) {
    const cx = sx > 0 ? b + 12 : W - b - 13, cy = sy > 0 ? b + 12 : H - b - 13;
    for (let a = 0; a < Math.PI * 1.4; a += .08) out.set(cx + Math.cos(a * sx) * (6 - a), cy + Math.sin(a * sy) * (6 - a), HW.Gold);
    ellipse(out, cx, cy, 1.6, 1.6, HW.Heartlight);
  }
  // The dream-fruit at the top centre, hanging over the frame: stem, leaves, a glowing gold fruit.
  const fx = W / 2, fy = b + 10;
  for (let y = b - 8; y < fy - 5; y++) out.set(fx, y, LEAFG[1]);
  petal(out, fx + 1, b - 3, -.5, 7, 2.2, LEAFG.slice(1)); petal(out, fx - 1, b - 1, Math.PI + .5, 6, 2, LEAFG.slice(1));
  ellipse(out, fx, fy, 16, 16, (x, y, dx, dy) => { const r = Math.hypot(dx, dy); return r > 1 ? null : CA(HW.Glow, Math.round((.18 + pulse * .12) * (1 - r) * 20) / 20); });
  const F = new Img(W, H); blob(F, fx, fy, 6, 7, [HW.Ember, HW.Gold, HW.Glow, HW.Heartlight], { tex: .05 }); out.stamp(F, HW.Root);
  out.set(fx - 2, fy - 3, HW.Heartlight);
  return out;
}
