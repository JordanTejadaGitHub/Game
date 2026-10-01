
// ---------- Per-node blooms: what a fully grown node looks like ----------
// Every grown node shows its own icon (NODE_ICON, from its .tres) at the heart of a flower in its limb's
// colours. The petal ring changes with the node's step along its line (depth: 1 five round petals,
// 2 a double ring, 3+ a pointed star ring with gold pips), so nodes sharing an icon still differ.
// Legendary tips get a gold rim. Sheet grove_blooms.png: a row per node (layout "bloom": row), 2 frames
// of BLOOM_CELL px (a slow shimmer). Ascension nodes use grove_ascended_blooms.png instead.
const BLOOM_CELL = 56, ASC_CELL = 72;
function nodeIcon(id) {
  const e = NODE_ICON[id]; if (!e || e[1] < 0) return null;
  const [root, i] = e;
  return root === 0 ? FAMILY_ICONS[FAMILY_ORDER[i]]() : root === 1 ? cardIcon(CARD_ORDER[i]) : PERK_ICONS[PERK_ORDER[i]]();
}
// The loadout slots have no icon: a little waystone with its teal ring.
function waystoneIcon() {
  const o = new Img(32, 32), S = new Img(32, 32);
  blob(S, 16, 18, 10, 8, [ST.d1, ST.m, ST.l1, ST.l2, ST.hi], { tex: .1, rim: true, seed: 3 });
  blob(S, 12, 12, 4, 2, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
  o.stamp(S, ST.out);
  for (let a = 0; a < Math.PI * 2; a += .4) o.set(16 + Math.cos(a) * 4, 19 + Math.sin(a) * 3, HW.Dew);
  o.set(16, 19, HW.Dewlight);
  return o;
}
function bloomSprite(n, f) {
  const S = BLOOM_CELL, c = S / 2, out = new Img(S, S), L = new Img(S, S), P = SECTION[n.section].petals, depth = Math.min(3, n.depth);
  haloOut(out, c, c, 27, n.section, f ? .4 : .32);
  const rot = f * .08;
  if (depth === 1) for (let k = 0; k < 5; k++) petal(L, c, c, rot + k / 5 * Math.PI * 2 - Math.PI / 2, 22, 8, P);
  else if (depth === 2) {
    for (let k = 0; k < 6; k++) petal(L, c, c, rot + k / 6 * Math.PI * 2 - Math.PI / 2, 23, 7, P);
    for (let k = 0; k < 6; k++) petal(L, c, c, rot + (k + .5) / 6 * Math.PI * 2 - Math.PI / 2, 19, 6.5, [P[2], P[3], SECTION[n.section].mid]);  // a lighter inner ring
  } else {
    for (let k = 0; k < 8; k++) petal(L, c, c, rot + k / 8 * Math.PI * 2 - Math.PI / 2, 25, 4.5, P);
  }
  // A dark heart so the icon reads; its rim marks the step: plain, a gold ring, a double gold ring.
  ellipse(L, c, c, 14, 14, (x, y, dx, dy) => { const q = Math.hypot(dx, dy); return depth >= 2 && q > .88 ? HW.Gold : depth >= 3 && q > .74 && q < .82 ? HW.Gold : q > .86 ? P[1] : P[0]; });
  out.stamp(L, HW.Void);
  if (depth >= 3) for (let k = 0; k < 4; k++) { const a = rot + (k + .5) / 4 * Math.PI * 2; out.set(c + Math.cos(a) * 19, c + Math.sin(a) * 19, HW.Glow); out.set(c + Math.cos(a) * 19 + 1, c + Math.sin(a) * 19, HW.Gold); }
  if (n.legendary) for (let a = 0; a < Math.PI * 2; a += .09) { const r = 26 + Math.sin(a * 8) * 1.5; out.set(c + Math.cos(a) * r, c + Math.sin(a) * r, HW.Gold); }
  const ic = nodeIcon(n.id) || waystoneIcon();
  out.put(ic, c - 16, c - 16);
  if (f) out.set(c - 9, c - 11, HW.Heartlight);  // a glint on the second frame
  return out;
}
// Ascension: the grandest node on the Families limb. Slow gold rays, a gold petal ring, a crown of
// light above, and the Ascended Warden itself (its idle frame, scaled down) in the middle. 4 frames.
function ascendedBloom(n, warden, f) {
  const S = ASC_CELL, c = S / 2, out = new Img(S, S), L = new Img(S, S);
  for (let k = 0; k < 12; k++) {  // rays, turning slowly, banded
    const a = (k / 12 + f / 48) * Math.PI * 2;
    for (let r = 20; r < 35; r++) { const x = c + Math.cos(a) * r, y = c + Math.sin(a) * r; out.set(x, y, CA(HW.Glow, r < 26 ? .55 : r < 31 ? .32 : .15)); }
  }
  haloOut(out, c, c, 30, "perks", .3 + (f % 2) * .06);
  for (let k = 0; k < 10; k++) petal(L, c, c + 2, (k + f * .05) / 10 * Math.PI * 2 - Math.PI / 2, 26, 6.5, [HW.Ember, HW.Gold, HW.Glow, HW.Heartlight]);
  ellipse(L, c, c + 2, 22, 22, (x, y, dx, dy) => Math.hypot(dx, dy) > .9 ? HW.Gold : dy < 0 ? HW.Slate : HW.Dusk);  // a lighter disc so the Warden reads
  out.stamp(L, HW.Root);
  // The crown: five gold points above the medallion, the middle one tallest.
  [[-12, 5], [-6, 7], [0, 10], [6, 7], [12, 5]].forEach(([dx, h]) => { for (let i = 0; i < h; i++) { const w = Math.max(0, Math.floor((h - i) / 3)); for (let j = -w; j <= w; j++) out.set(c + dx + j, c - 17 - i, i === h - 1 ? HW.Heartlight : HW.Gold); } });
  for (let x = c - 14; x <= c + 14; x++) { out.set(x, c - 17, HW.Gold); out.set(x, c - 16, HW.Ember); }
  // The Warden: area-averaged down to 36 px, drawn in the medallion.
  const D = 42, k = warden.w / D, ox = c - D / 2, oy = c + 1 - D / 2;
  for (let y = 0; y < D; y++) for (let x = 0; x < D; x++) {
    let r = 0, g = 0, b = 0, a = 0, cnt = 0;
    for (let yy = Math.floor(y * k); yy < Math.floor((y + 1) * k); yy++) for (let xx = Math.floor(x * k); xx < Math.floor((x + 1) * k); xx++) {
      const p = warden.get(xx, yy); cnt++; if (p[3] < 128) continue; r += p[0]; g += p[1]; b += p[2]; a++;
    }
    if (a * 2 >= cnt && Math.hypot(x - D / 2, y - D / 2) < 21) out.set(ox + x, oy + y, [r / a, g / a, b / a, 255]);
  }
  return out;
}
// Loads the Ascended Wardens' frames (data URLs) and draws the ascension sheet: a row per Ascension
// node in NODES order, 4 frames. Resolves to the sheet.
function ascendedSheet(nodes) {
  return Promise.all(nodes.map(n => new Promise(ok => {
    const im = new Image(); im.onload = () => {
      const cv = document.createElement("canvas"); cv.width = im.width; cv.height = im.height; const cx = cv.getContext("2d"); cx.drawImage(im, 0, 0);
      const W = new Img(im.width, im.height); W.d.set(cx.getImageData(0, 0, im.width, im.height).data); ok(W);
    };
    im.src = ASCENDED_ART[n.id.replace(/_ascension$/, "")];
  }))).then(wardens => stack(nodes.map((n, i) => strip([0, 1, 2, 3].map(f => ascendedBloom(n, wardens[i], f))))));
}
// Ascension blooms, uniform version (2026-09-30, user: the icon blooms looked out of place): the
// Legendary tip's big 48 px flower in the Families colours with a small gold crown above it.
function ascendedBloomPlain(f) {
  const S = 48, out = new Img(S, S), b = nodeSprite("families", "bloom", f % 2, true);
  out.put(b);
  [[-6, 3], [0, 5], [6, 3]].forEach(([dx, h]) => { for (let i = 0; i < h; i++) out.set(24 + dx, 9 - i, i === h - 1 ? HW.Heartlight : HW.Gold); });
  for (let x = 17; x <= 31; x++) out.set(x, 9, HW.Gold);
  if (f >= 2) out.set(f === 2 ? 18 : 30, 6, HW.Glow);
  return out;
}
