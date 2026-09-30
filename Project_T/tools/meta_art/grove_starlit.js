
// ---------- Starlit card backs (milestone "Dream of everything", meta_design.md) ----------
// A night-sky background for a Dream offer card: 250×220 (DreamScreen CARD_SIZE), drawn in 2× chunky
// pixels, 9-slice with STARLIT_MARGIN on every side. The card's own style (the rarity / Entwined thread
// along the top, the gem, the text) draws over it, so the frame keeps the top edge's middle clear and
// the middle calm and dark for text. Only the border band has stars, so the edges tile (NinePatchRect
// axis_stretch TILE) when a card grows taller. Four frames make a slow twinkle loop.
const STARLIT_W = 250, STARLIT_H = 220, STARLIT_MARGIN = 28, STARLIT_FRAMES = 4;
function starlitCard(frame) {
  const s = 2, W = STARLIT_W / s | 0, H = STARLIT_H / s | 0, M = STARLIT_MARGIN / s, L = new Img(W, H);
  const band = (x, y) => Math.min(x, y, W - 1 - x, H - 1 - y);  // distance to the edge, in chunky px
  // Sky: deep blue-violet, lightest at the rim (a glow of dusk), darkest behind the text.
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const d = band(x, y), t = Math.max(0, 1 - d / M) ** 1.6;  // fades out inside the 9-slice margin (the middle tiles)
    L.set(x, y, pick([HW.Void, HW.Dread, HW.Night, HW.Shade], clamp(.1 + t * .95, 0, 1), x, y, .9));
  }
  // A faint band of the Milky Way across the bottom-left corner and the top-right one.
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    if (band(x, y) >= M - 1) continue;
    const m = Math.abs((x / W - y / H) * 1.4) - .55;
    if (m > 0 && m < .12 && hash(x, y, 1301) < .35 + (.12 - m) * 3) L.set(x, y, HW.Bruise);
  }
  // Stars in the border band only. Positions repeat every 27 chunky px down the sides, so a stretched
  // card tiles cleanly; each star twinkles on its own phase over the four frames.
  const stars = [];
  for (let k = 0; k < 96; k++) {
    const side = k % 4, u = hash(k, 1, 1302), v = hash(k, 2, 1302) * (M - 3) + 1;
    let x, y;
    if (side === 0) { x = u * W; y = v; } else if (side === 1) { x = u * W; y = H - 1 - v; }
    else if (side === 2) { x = v; y = M + (u * 27 | 0) + (k % 3) * 27; } else { x = W - 1 - v; y = M + (u * 27 | 0) + (k % 3) * 27; }
    if (y < 3 && Math.abs(x - W / 2) < W * .3) continue;  // leave the thread's middle clear
    stars.push([Math.round(x), Math.round(y), hash(k, 3, 1302), (hash(k, 4, 1302) * 4) | 0]);
  }
  for (const [x, y, size, phase] of stars) {
    const lit = (frame + phase) % 4, dim = lit === 3;
    const c = size > .85 ? HW.Moonlight : size > .5 ? HW.Mist : HW.Wraithlight;
    if (size > .85 && !dim) {  // a small four-point star
      L.set(x, y, lit === 0 ? HW.Moonlight : HW.Mist);
      for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) L.set(x + a, y + b, lit === 0 ? HW.Mist : HW.Wraithlight);
    } else L.set(x, y, dim ? HW.Dusk : c);
  }
  // A few faint stars drifting in from the band (never behind the text in the middle).
  for (let k = 0; k < 40; k++) {
    const x = hash(k, 5, 1303) * W | 0, y = hash(k, 6, 1303) * H | 0, d = band(x, y);
    if (d >= M * .55 && d < M - 1 && !(y < 3)) L.set(x, y, (frame + k) % 4 === 0 ? HW.Wraithlight : HW.Dusk);
  }
  // Corner ornaments: a bright four-point star in each corner, with a soft halo.
  for (const [cx, cy] of [[6, 6], [W - 7, 6], [6, H - 7], [W - 7, H - 7]]) {
    ellipse(L, cx, cy, 5, 5, (x, y, dx, dy) => CA(HW.Wraithlight, .25 * (1 - Math.hypot(dx, dy))));
    const r = frame % 2 ? 3 : 4;
    for (let i = -r; i <= r; i++) { L.set(cx + i, cy, Math.abs(i) < 2 ? HW.Moonlight : HW.Mist); L.set(cx, cy + i, Math.abs(i) < 2 ? HW.Moonlight : HW.Mist); }
  }
  // A thin rim: Dusk, lit Slate along the top and left.
  for (let x = 0; x < W; x++) for (const y of [0, H - 1]) if (!(y === 0 && Math.abs(x - W / 2) < W * .3)) L.set(x, y, y ? HW.Dusk : HW.Slate);
  for (let y = 1; y < H - 1; y++) { L.set(0, y, HW.Slate); L.set(W - 1, y, HW.Dusk); }
  // Scale up 2×.
  const out = new Img(STARLIT_W, STARLIT_H);
  for (let y = 0; y < STARLIT_H; y++) for (let x = 0; x < STARLIT_W; x++) { const X = x / s | 0, Y = y / s | 0; if (L.alpha(X, Y)) out.set(x, y, L.get(X, Y)); }
  return out;
}
// A stretched card for the preview: 9-slice with tiled edges, the way the game draws it.
function nineTile(src, W, H, m) {
  const out = new Img(W, H), sw = src.w - 2 * m, sh = src.h - 2 * m;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const sx = x < m ? x : x >= W - m ? src.w - (W - x) : m + (x - m) % sw, sy = y < m ? y : y >= H - m ? src.h - (H - y) : m + (y - m) % sh;
    if (src.alpha(sx, sy)) out.set(x, y, src.get(sx, sy));
  }
  return out;
}
