
// ================= Memory Grove: the Heartwood as a tech tree =================
// Tree space is 1280×960 px (native pixel art); every position below is in that space.
const GW = 1280, GH = 960;
// Night bark: deep warm browns (the Heartwood is the warm side), grain runs along the wood.
// Night bark: deep warm browns (the Heartwood is the warm side), grain runs along the wood.
const HB6 = ["#120a08", "#22150e", "#362216", "#4c3020", "#66442c", "#80583a"];
const LEAFG = ["#1e3a14", "#2e5a1e", "#4a7e2a", "#78a83c", "#a8cc5c"];
const SECTION = {
  perks:    { name: "Perks",    petals: ["#6a3c0c", "#b87818", "#e8b440", "#ffe39a"], mid: "#fff6d0", glow: "255,200,90" },
  families: { name: "Families", petals: ["#1a4222", "#338236", "#72c05a", "#c4ec98"], mid: "#f2ffd8", glow: "150,230,120" },
  cards:    { name: "Cards",    petals: ["#341a52", "#6e40a6", "#ae86e2", "#e4d4ff"], mid: "#fff0ff", glow: "190,150,255" },
};
// The three great limbs (Catmull-Rom through these points), with their widths at base and tip.
const LIMBS = {
  perks:    { pts: [[628, 648], [540, 604], [440, 562], [340, 520], [250, 470], [170, 410], [104, 334], [74, 250]], w: [38, 9] },
  families: { pts: [[640, 648], [640, 560], [645, 480], [636, 400], [641, 320], [645, 240], [638, 160], [640, 104]], w: [44, 10] },
  cards:    { pts: [[652, 648], [740, 604], [840, 562], [940, 517], [1040, 467], [1130, 407], [1192, 342], [1222, 280]], w: [38, 9] },
};
// Nodes: id, section, name, position, and either `parent` (another node) or `from` (a point on a limb).
// `lv` = levels (one node, pips shown by the game); `start` = grown from the beginning.
const NODES = [];
const N = (id, section, name, x, y, link, extra = {}) => NODES.push({ id, section, name, x, y, ...(typeof link === "string" ? { parent: link } : { from: link }), ...extra });
// Perks
N("morning_stores", "perks", "Morning Stores", 500, 530, [540, 604], { lv: 3 });
N("rich_dew", "perks", "Rich Dew", 452, 468, "morning_stores", { lv: 3 });
N("rested_roots", "perks", "Rested Roots", 430, 402, "rich_dew", { lv: 2 });
N("sprout_bed", "perks", "Sprout Bed", 524, 456, "morning_stores");
N("seed_pouch", "perks", "Seed Pouch", 430, 640, [446, 564]);
N("clear_sight", "perks", "Clear Sight", 384, 474, [410, 550]);
N("kindling", "perks", "Kindling", 318, 440, [340, 520]);
N("early_bloom", "perks", "Early Bloom", 318, 600, [350, 526]);
N("early_light", "perks", "Early Light", 250, 620, "early_bloom");
N("first_care", "perks", "First Care", 262, 392, [262, 478]);
N("deep_taproot", "perks", "Deep Taproot", 200, 540, [230, 458], { lv: 3 });
N("second_thoughts", "perks", "Second Thoughts", 196, 330, [176, 406], { lv: 2 });
N("let_go", "perks", "Let Go", 248, 268, "second_thoughts");
N("wider_dreams", "perks", "Wider Dreams", 164, 256, "second_thoughts");
N("omen_reader", "perks", "Omen Reader", 118, 470, [150, 390]);
N("slot_2", "perks", "Loadout slot 2", 58, 300, [96, 318]);
N("slot_3", "perks", "Loadout slot 3", 40, 236, "slot_2");
N("slot_4", "perks", "Loadout slot 4", 42, 170, "slot_3");
N("slot_5", "perks", "Loadout slot 5", 70, 110, "slot_4");
// Families: a short branch of three per family, alternating sides up the middle limb.
[["sporeling", "Sporeling", true], ["firefly_jar", "Firefly Jar", true], ["dewdrop", "Dewdrop", true], ["pebbling", "Pebbling"],
 ["rootling", "Rootling"], ["bellflower", "Bellflower"], ["acorn", "Acorn"], ["nestling", "Nestling"], ["whirligig", "Whirligig"]]
  .forEach(([id, name, start], i) => {
    const side = i % 2 ? 1 : -1, ay = 604 - i * 50, ax = 640 + Math.sin((604 - ay) / 90) * 4;
    N(id, "families", name, ax + side * 38, ay - 20, [ax, ay], start ? { start: true } : {});
    N(id + "_final", "families", name + ": final forms", ax + side * 60, ay - 52, id);
    N(id + "_hidden", "families", name + ": hidden branch", ax + side * 72, ay - 86, id + "_final");
  });
// Cards: one branch per build style, Legendary flower at the tip.
N("storm_lore", "cards", "Storm Lore", 760, 522, [742, 602]);
N("guiding_lights", "cards", "Guiding Lights", 790, 452, "storm_lore");
N("spore_lore", "cards", "Spore Lore", 852, 482, [842, 560]);
N("reactions", "cards", "Reactions", 870, 410, "spore_lore");
N("dawnbreak", "cards", "Dawnbreak", 884, 330, "reactions", { legendary: true });
N("sharpened", "cards", "Sharpened", 952, 440, [942, 516]);
N("reckless", "cards", "Reckless", 980, 370, "sharpened");
N("full_moon", "cards", "Full Moon", 1000, 288, "reckless", { legendary: true });
N("tending_hands", "cards", "Tending Hands", 1062, 392, [1044, 465]);
N("nursery", "cards", "Nursery", 1090, 320, "tending_hands");
N("the_old_ones", "cards", "The Old Ones", 1102, 238, "nursery", { legendary: true });
N("seedbed", "cards", "Seedbed", 1172, 340, [1134, 404]);
N("wild_planting", "cards", "Wild Planting", 1208, 278, "seedbed");
N("rootbound", "cards", "Rootbound", 1228, 206, "wild_planting", { legendary: true });
N("one_line", "cards", "One Line", 832, 640, [846, 562]);
N("the_last_light", "cards", "The Last Light", 800, 710, "one_line", { legendary: true });
N("dead_wood", "cards", "Dead Wood", 962, 600, [944, 518]);
N("the_long_walk", "cards", "The Long Walk", 992, 676, "dead_wood", { legendary: true });
N("bittersweet_dreams", "cards", "Bittersweet Dreams", 1152, 482, [1128, 410]);
const byId = Object.fromEntries(NODES.map(n => [n.id, n]));
NODES.forEach(n => { n.depth = n.parent ? byId[n.parent].depth + 1 : 1; });
// Where dream-fruit (Memories) hang, in the order they appear: the point under a limb the vine
// hangs from (the fruit sprite's top centre goes here). Picked clear of the branches that droop.
function limbUnderside(limb, x) {
  const pts = catmull(LIMBS[limb].pts, 14);
  let best = pts[0], bi = 0; pts.forEach((p, i) => { if (Math.abs(p[0] - x) < Math.abs(best[0] - x)) { best = p; bi = i; } });
  const w = LIMBS[limb].w[0] + (LIMBS[limb].w[1] - LIMBS[limb].w[0]) * bi / (pts.length - 1);
  return [Math.round(best[0]), Math.round(best[1] + w / 2 - 3)];
}
// The crown: one shared mass of foliage over all three limbs (lobes, with a noisy edge).
const CROWN_LOBES = [[640, 330, 560, 250], [330, 392, 300, 190], [950, 392, 300, 190], [640, 190, 380, 160], [150, 300, 150, 160], [1130, 300, 150, 160]];
function crownIn(x, y) {
  const n = (pnoise(x, y, 60, 811) - .5) * .35;
  return CROWN_LOBES.some(([cx, cy, rx, ry]) => ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1 + n);
}
function crownBottom(x) { let y = GH - 1; while (y > 0 && !crownIn(x, y)) y--; return y; }
// Fruit hang from the crown's underside, clear of the branches that droop below it.
const FRUIT_SPOTS = [560, 720, 380, 900, 280, 1050, 480, 800, 640, 1200].map(x => [x, crownBottom(x) - 8]);

// ---- curves ----
function catmull(pts, samples) {
  const out = [];
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)];
    for (let s = 0; s < samples; s++) {
      const t = s / samples, t2 = t * t, t3 = t2 * t;
      out.push([0, 1].map(k => .5 * (2 * p1[k] + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)));
    }
  }
  out.push(pts[pts.length - 1]);
  return out;
}
const barkBig = seed => (x, y, nx) => {
  const grain = pnoise(x * 4, y, 14, seed + 1) - .5;
  const t = .55 - nx * .42 + (pnoise(x, y, 7, seed) - .5) * .2 + grain * .45 + (hash(x, y >> 1, seed) < .06 ? -.2 : 0);
  return pick(HB6.slice(1), clamp(t, 0, 1), x, y, .5);
};
// Draws a thick tapered path (list of points) with bark shading; returns the sampled centre line.
function thickPath(L, pts, w0, w1, fn) {
  let len = 0; const cum = [0];
  for (let i = 1; i < pts.length; i++) { len += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]); cum.push(len); }
  for (let i = 1; i < pts.length; i++) stroke(L, pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1], w0 + (w1 - w0) * cum[i - 1] / len, w0 + (w1 - w0) * cum[i] / len, fn);
  return len;
}

// ---- the base tree: roots, trunk, three limbs, always visible ----
function groveTree() {
  const out = new Img(GW, GH), L = new Img(GW, GH), M = new Img(GW, GH);
  // Earth mound with moss.
  ellipse(out, 640, 952, 560, 90, (x, y, dx, dy) => pick(["#0c0806", "#140e0a", "#1c140e"], clamp(.6 - dy * .5 + (pnoise(x, y, 9, 3) - .5) * .4, 0, 1), x, y));
  for (let k = 0; k < 900; k++) {
    const x = 120 + hash(k, 1, 4) * 1040, y = 880 + hash(k, 2, 4) * 80;
    if (hash(k, 3, 4) < .6) { out.set(x, y, LEAFG[1]); out.set(x, y - 1, LEAFG[2]); if (hash(k, 4, 4) < .4) out.set(x + 1, y - 2, LEAFG[3]); }
  }
  // A soft flat shadow under the whole tree.
  ellipse(out, 640, 918, 400, 42, SHADOW(.45));
  // Roots: big flared roots with ridges running along them.
  const rootFn = seed => (x, y, nx) => {
    const ridge = Math.abs(((pnoise(x * 3, y, 12, seed) * 7) % 1) - .5) < .1;
    return pick(HB6.slice(1), clamp(.58 - nx * .45 + (ridge ? -.28 : 0) + (pnoise(x, y, 6, seed + 1) - .5) * .12, 0, 1), x, y, .5);
  };
  const roots = [[[596, 870], [520, 884], [446, 912], [372, 944], [330, 952]], [[684, 870], [760, 884], [834, 912], [908, 944], [950, 952]],
    [[612, 890], [578, 924], [556, 960]], [[668, 890], [702, 924], [724, 960]], [[590, 856], [512, 852], [440, 868], [388, 890]],
    [[690, 856], [768, 852], [840, 868], [892, 890]], [[640, 900], [646, 962]]];
  roots.forEach((r, i) => thickPath(L, catmull(r, 12), [46, 46, 34, 34, 28, 28, 30][i], 8, rootFn(20 + i)));
  // Twisted strands: each sample's segments are drawn back to front (by where they are in the
  // twist), and each strand's edge is darkened so the strands read apart.
  // Each strand is a shaded cylinder: dark edges, a lit band toward the key light (top left), and
  // bark lines running along it, broken into dashes.
  const strandFn = seed => (x, y, nx) => {
    if (Math.abs(nx) > .84) return HB6[1];
    let t = .6 - nx * .55;
    if (nx > -.6 && nx < -.28) t += .16;
    const line = Math.abs(((nx + 1) * 3.5 + (pnoise(x, y, 18, seed) - .5) * .8) % 1 - .5);
    if (line > .4 && pnoise(x, y, 5, seed + 3) > .35) t -= .22;
    return pick(HB6.slice(1), clamp(t, 0, 1), x, y, .35);
  };
  const twist = (centre, widthAt, count, turns, seed) => {
    const N = centre.length - 1;
    for (let i = 0; i < N; i++) {
      const [x0, y0] = centre[i], [x1, y1] = centre[i + 1], dx = x1 - x0, dy = y1 - y0, d = Math.hypot(dx, dy) || 1, px = -dy / d, py = dx / d;
      const segs = [];
      for (let k = 0; k < count; k++) {
        const ang0 = (i / N) * turns * Math.PI * 2 + k * Math.PI * 2 / count, ang1 = ((i + 1) / N) * turns * Math.PI * 2 + k * Math.PI * 2 / count;
        const w0 = widthAt(i / N), w1 = widthAt((i + 1) / N), sw0 = w0 * (count > 2 ? .5 : .62), sw1 = w1 * (count > 2 ? .5 : .62);
        const o0 = Math.sin(ang0) * (w0 - sw0) * .5, o1 = Math.sin(ang1) * (w1 - sw1) * .5;
        segs.push({ depth: Math.cos(ang0), a: [x0 + px * o0, y0 + py * o0], b: [x1 + px * o1, y1 + py * o1], w0: sw0, w1: sw1, k });
      }
      segs.sort((p, q) => p.depth - q.depth).forEach(s => stroke(L, s.a[0], s.a[1], s.b[0], s.b[1], s.w0, s.w1, strandFn(seed + s.k * 13)));
    }
  };
  const trunk = catmull([[640, 905], [632, 830], [648, 750], [636, 680], [640, 610]], 24);
  twist(trunk, t => 128 - t * 40, 3, .9, 30);
  // The three great limbs grow out of the twist as pairs of strands and vanish into the crown.
  for (const [k, limb] of Object.entries(LIMBS)) {
    const pts = catmull([[640, 690], ...limb.pts], 16);
    twist(pts, t => (limb.w[0] + 18) * (1 - t) + limb.w[1] * t, 2, 1.4, k.length * 7);
  }
  // Moss along the lit tops of the limbs and trunk.
  for (let y = 1; y < GH; y++) for (let x = 0; x < GW; x++) {
    if (!L.alpha(x, y) || L.alpha(x, y - 3)) continue;
    const n = pnoise(x, y, 11, 41);
    if (n > .45) for (let d = 0; d < 1 + Math.floor((n - .45) * 8); d++) if (L.alpha(x, y + d)) M.set(x, y + d, LEAFG[Math.min(4, 2 + d % 3)]);
  }
  out.stamp(L, HB6[0]);
  // Moonlight rims the tree's upper-right edges (the moon is up and to the right).
  for (let y = 1; y < GH - 1; y++) for (let x = 1; x < GW - 1; x++)
    if (L.alpha(x, y) && !L.alpha(x + 1, y - 1) && L.alpha(x - 1, y + 1)) out.set(x, y, hash(x, y, 5) < .7 ? "#8a8ea8" : "#6a6a88");
  out.put(M);
  // Bark knots on the trunk and limb bases.
  for (const [x, y, r] of [[618, 700, 6], [664, 836, 5], [610, 870, 4], [588, 612, 4], [700, 612, 4], [646, 520, 4], [470, 574, 4], [900, 540, 4]]) {
    ellipse(out, x, y, r, r * 1.3, (xx, yy, dx, dy) => { const q = Math.hypot(dx, dy); return q > .75 ? HB6[1] : q > .4 ? HB6[3] : HB6[0]; });
  }
  // Ivy spiralling up the trunk.
  for (let i = 0; i < 260; i++) {
    const t = i / 260, y = 900 - t * 270, x = 640 + Math.sin(t * 11) * (56 - t * 22);
    if (Math.cos(t * 11) < -.2) continue;  // behind the trunk
    out.set(x, y, LEAFG[1]); out.set(x + 1, y, LEAFG[2]);
    if (i % 7 === 0) { petal(out, x, y, -Math.PI / 2 + (i % 14 ? .8 : -.8), 5, 2, LEAFG.slice(1)); }
  }
  // Glowing sigils at the base of each limb: which section is which.
  const sigil = (cx, cy, sec, shape) => {
    const [R, G, B] = SECTION[sec].glow.split(",").map(Number);
    ellipse(out, cx, cy, 22, 22, (x, y, dx, dy) => [R, G, B, Math.round(110 * Math.max(0, 1 - Math.hypot(dx, dy)) ** 1.5)]);
    shape.forEach(([x, y]) => { for (const [a, b] of [[0, 0], [1, 0], [0, 1], [1, 1]]) out.set(cx + x * 2 + a, cy + y * 2 + b, SECTION[sec].petals[3]); });
  };
  const ring = []; for (let a = 0; a < Math.PI * 2; a += .35) ring.push([Math.round(Math.cos(a) * 5), Math.round(Math.sin(a) * 5)]);
  sigil(600, 640, "perks", [...ring, [0, 0], [0, -1], [0, 1], [-1, 0], [1, 0]]);
  sigil(641, 596, "families", [[0, -6], [0, -5], [0, -4], [0, -3], [0, -2], [0, -1], [0, 0], [0, 1], [0, 2], [0, 3], [-1, -3], [-2, -4], [1, -1], [2, -2], [-1, 1], [-2, 0], [1, 3], [2, 2]]);
  sigil(684, 640, "cards", [[-3, -5], [-2, -5], [-1, -5], [0, -5], [1, -5], [2, -5], [3, -5], [-3, 5], [-2, 5], [-1, 5], [0, 5], [1, 5], [2, 5], [3, 5], [-3, -4], [-3, -3], [-3, -2], [-3, -1], [-3, 0], [-3, 1], [-3, 2], [-3, 3], [-3, 4], [3, -4], [3, -3], [3, -2], [3, -1], [3, 0], [3, 1], [3, 2], [3, 3], [3, 4], [0, -1], [0, 0], [0, 1], [-1, 0], [1, 0]]);
  // Pale glowing mushrooms on the roots.
  for (const [x, y, s] of [[470, 896, 1], [486, 900, .7], [812, 894, 1.1], [828, 899, .8], [560, 928, .8], [742, 930, .9], [372, 930, .7]]) {
    ellipse(out, x, y + 3 * s, 1.6 * s, 3 * s, "#c8c0d8");
    ellipse(out, x, y, 4.5 * s, 2.8 * s, (xx, yy, dx, dy) => dy < -.1 && dx < .2 ? "#d8ccf0" : "#9a88c8");
    out.set(x - 1, y - 1, "#f4f0ff"); ellipse(out, x, y, 9 * s, 7 * s, (xx, yy, dx, dy) => CA("#c8b0ff", Math.max(0, 1 - Math.hypot(dx, dy)) * .22));
  }
  // The loadout's waystones: five small carved stones in an arc at the roots ("Carry into the dream").
  LOADOUT_STONES.forEach(([x, y], i) => {
    const S = new Img(GW, GH);
    ellipse(out, x, y + 13, 20, 5, SHADOW(.4));
    blob(S, x, y, 16, 13, [ST.d1, ST.m, ST.l1, ST.l2, ST.hi], { tex: .1, rim: true, seed: i });
    blob(S, x - 6, y - 9, 7, 3, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
    out.stamp(S, ST.out);
    for (let a = 0; a < Math.PI * 2; a += .3) out.set(x + Math.cos(a) * 6, y + 2 + Math.sin(a) * 4.5, "#8ad8c8");
    out.set(x, y + 2, "#c8fff0");
  });
  // Hollow: an arched doorway full of warm light.
  for (let y = 740; y <= 820; y++) for (let x = 612; x <= 668; x++) {
    const dx = x + .5 - 640, inside = Math.abs(dx) <= 20 && (y >= 770 || Math.hypot(dx, (y - 770) * 1.05) <= 20);
    if (!inside) continue;
    const edge = Math.abs(dx) > 17 || (y < 770 && Math.hypot(dx, (y - 770) * 1.05) > 17);
    const r = Math.hypot(dx, (y - 792) * .8) / 26;
    out.set(x, y, edge ? "#1a0e08" : r < .3 ? "#fff4c8" : r < .6 ? "#ffd27a" : r < .85 ? "#e0883a" : "#8a4a1a");
  }
  // Hanging moss strands under the limbs.
  for (let k = 0; k < 160; k++) {
    const x = Math.floor(80 + hash(k, 1, 50) * 1120);
    let y = 120; while (y < 700 && !(L.alpha(x, y) && !L.alpha(x, y + 1))) y++;
    if (y >= 700 || hash(k, 2, 50) < .45) continue;
    const len = 6 + hash(k, 3, 50) * 16;
    for (let i = 1; i < len; i++) out.set(x + Math.round(Math.sin(i * .3 + k)), y + i, i % 3 ? "#56624e" : "#3e4a3a");
  }
  return out;
}

// The loadout stones at the roots (centres), left to right = slot 1 … 5.
const LOADOUT_STONES = [[478, 906], [558, 926], [640, 934], [722, 926], [802, 906]];
const MOON = [1062, 118];

// ---- the night sky behind it: moon, stars, two layers of distant forest, low fog ----
function grovesky() {
  const out = new Img(GW, GH), cols = ["#06051a", "#0a0820", "#0e0b28", "#131030", "#1a1434", "#241a36", "#2e2034"];
  for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) {
    const glow = Math.max(0, 1 - Math.hypot((x - 640) / 620, (y - 700) / 520));
    const moon = Math.max(0, 1 - Math.hypot(x - MOON[0], y - MOON[1]) / 230);
    let t = y / GH * .55 + glow * .55 + moon * .35 + (pnoise(x, y, 90, 61) - .5) * .12;
    out.set(x, y, pick(cols, clamp(t, 0, 1), x, y, .9));
    const h = hash(x, y, 62);
    if (y < 760 && h < .0016 * (1 - glow) * (1 - moon)) out.set(x, y, h < .0004 ? "#e8ecff" : "#8a8ac0");
  }
  // The moon, with a soft halo and a few darker seas.
  ellipse(out, MOON[0], MOON[1], 70, 70, (x, y, dx, dy) => CA("#b8c4ff", Math.max(0, 1 - Math.hypot(dx, dy)) ** 2 * .35));
  ellipse(out, MOON[0], MOON[1], 30, 30, (x, y, dx, dy) => {
    const sea = pnoise(x, y, 9, 64) > .6;
    return pick(["#9aa0c8", "#c4c8e4", "#e8eaf8", "#fbfcff"], clamp(.75 - dx * .3 - dy * .3 - (sea ? .3 : 0), 0, 1), x, y, .5);
  });
  // Far forest (bluer), then nearer forest (darker), then fog lying between them.
  const band = (base, amp, cell, seed, fill, edge) => {
    for (let x = 0; x < GW; x++) {
      const spikes = Math.max(0, Math.sin(x / (cell * .45) + seed) * 12) + (hash(Math.floor(x / 7), 0, seed) < .3 ? 6 : 0);
      const top = base - pnoise(x, 0, cell, seed) * amp - spikes;
      for (let y = Math.floor(top); y < GH; y++) out.set(x, y, y < top + 2 ? edge : fill);
    }
  };
  band(770, 70, 50, 63, "#161a30", "#262c48");
  for (let y = 770; y < 872; y++) for (let x = 0; x < GW; x++) {
    const edge = (Math.abs(y - 820) / 50) ** 2;
    if (pnoise(x, y, 40, 66) > .45 + edge * .6) out.set(x, y, CA("#5a5a8a", .16));
  }
  band(830, 50, 34, 65, "#0a0c16", "#141828");
  return out;
}

// ---- the crown: bubbly foliage clumps over all three limbs ----
// The same clumps at every stage; the palette brightens from a dormant indigo (stage 0) to a
// glowing dream-green (stage 3), so the stages crossfade cleanly as the tree is planted.
const CROWN_CLUMPS = (() => {
  const list = [];
  for (let gy = 20; gy < 640; gy += 34) for (let gx = -10; gx < GW + 10; gx += 40) {
    const x = gx + (hash(gx, gy, 821) - .5) * 26 + (gy / 34 % 2) * 20, y = gy + (hash(gx, gy, 822) - .5) * 26;
    if (!crownIn(x, y)) continue;
    list.push([x, y, 30 + hash(gx, gy, 823) * 16, 26 + hash(gx, gy, 824) * 11]);
  }
  // A few clumps hanging below the crown's edge.
  for (let k = 0; k < 16; k++) { const x = 140 + k * 66 + (hash(k, 1, 825) - .5) * 30, y = crownBottom(x) + 4; list.push([x, y, 20 + hash(k, 2, 825) * 8, 16 + hash(k, 3, 825) * 6]); }
  return list.sort((a, b) => a[1] - b[1]);
})();
// The existing dark night greens (colours unchanged), extended to seven tiers for the clump shading.
const CROWN_P = ["#050b08", "#07100b", "#0c1a10", "#132816", "#1c381c", "#284a24", "#3a5e30"];
// Stages grow the crown outward: the core over the limbs is always there, the edges fill in.
const CROWN_SHARE = [.55, .7, .85, 1];
const CROWN_RANK = CROWN_CLUMPS.map(([x, y], k) => Math.hypot((x - 640) / 620, (y - 380) / 330) + hash(k, 1, 840) * .35);
const CROWN_CUT = CROWN_SHARE.map(s => [...CROWN_RANK].sort((a, b) => a - b)[Math.max(0, Math.round(CROWN_RANK.length * s) - 1)]);
// Each clump is a cauliflower of bubbles: small bumps scalloping its underside (behind), a core,
// then bumps round its top, lowest first, so the upper ones overlap like puffs of cloud.
const CROWN_BUBBLES = CROWN_CLUMPS.map(([cx, cy, rx, ry], k) => {
  const under = [], top = [];
  for (let i = 0; i < 3; i++) {
    const a = .45 + i * 1.1 + (hash(k, i, 851) - .5) * .4;
    under.push([cx + Math.cos(a) * rx * .5, cy + Math.sin(a) * ry * .42, rx * (.3 + hash(k, i, 852) * .1), ry * (.32 + hash(k, i, 853) * .1)]);
  }
  const n = 4 + Math.floor(hash(k, 9, 854) * 3);
  for (let i = 0; i < n; i++) {
    const a = Math.PI * (1.04 + (i + (hash(k, i, 855) - .5) * .5) / (n - 1) * .92);
    top.push([cx + Math.cos(a) * rx * .56, cy + Math.sin(a) * ry * .5 + ry * .06, rx * (.32 + hash(k, i, 856) * .14), ry * (.34 + hash(k, i, 857) * .14)]);
  }
  // A few puffs sitting on the top bumps: the brightest, frontmost layer.
  for (let i = 0; i < 2; i++) {
    const a = Math.PI * (1.3 + i * .35 + (hash(k, i, 858) - .5) * .2);
    top.push([cx + Math.cos(a) * rx * .3, cy + Math.sin(a) * ry * .42, rx * (.24 + hash(k, i, 859) * .08), ry * (.26 + hash(k, i, 860) * .08)]);
  }
  return [...under, [cx, cy + ry * .04, rx * .8, ry * .76], ...top.sort((p, q) => q[1] - p[1])];
});
// Draws the crown into per-pixel buffers (who owns each pixel, how lit it is), then shades from
// them: a dark gap round every clump in front, a crease under every bump, leaf texture, crisp tiers.
function crownLayer(stage) {
  const L = new Img(GW, GH), OWN = new Int32Array(GW * GH).fill(-1), LIT = new Float32Array(GW * GH), P = CROWN_P;
  // Lower clumps in front, so every clump shows its lit top against the shaded underside behind it.
  const order = CROWN_CLUMPS.map((c, k) => k).filter(k => CROWN_RANK[k] <= CROWN_CUT[stage]).sort((a, b) => CROWN_CLUMPS[a][1] - CROWN_CLUMPS[b][1]);
  const light = (dx, dy) => { const r2 = Math.min(.98, dx * dx + dy * dy), nz = Math.sqrt(1 - r2); return clamp((-dx * .45 - dy * .75 + nz * .5 + .3) / 1.3, 0, 1); };
  order.forEach((k, oi) => {
    const [cx, cy, rx, ry] = CROWN_CLUMPS[k];
    // Lower in the crown = darker; the far right a touch darker (away from the key light).
    const base = .1 - (cy - 240) / 640 * .5 - (cx - 560) / 1280 * .12;
    CROWN_BUBBLES[k].forEach(([bx, by, brx, bry], bi) => {
      const seed = k * 7 + bi;
      for (let y = Math.floor(by - bry * 1.15); y <= by + bry * 1.15; y++) for (let x = Math.floor(bx - brx * 1.15); x <= bx + brx * 1.15; x++) {
        if (x < 0 || y < 0 || x >= GW || y >= GH) continue;
        const dx = (x + .5 - bx) / brx, dy = (y + .5 - by) / bry, a = Math.atan2(dy, dx);
        const w = 1 + .08 * Math.sin(a * 4 + seed) + .05 * Math.sin(a * 7 + seed * 1.7);
        if ((dx * dx + dy * dy) / (w * w) > 1) continue;
        const i = y * GW + x;
        OWN[i] = oi * 16 + bi;
        LIT[i] = light(dx / w, dy / w) * .65 + light((x + .5 - cx) / (rx * 1.1), (y + .5 - cy) / (ry * 1.1)) * .35 + base;
      }
    });
  });
  for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) {
    const i = y * GW + x, o = OWN[i]; if (o < 0) continue;
    const t = (LIT[i] - .45) * 1.7 + .5;
    let tier = clamp(1 + Math.floor(t * 5 + (bay(x, y) - .5) * .3), 1, 5);
    // A clump in front casts a dark gap: an outline right against it, a shadow falling off behind.
    let gap = 9;
    for (let d = 1; d <= 4 && gap > 4; d++) for (const [ex, ey] of [[0, 1], [1, 1], [-1, 1], [1, 0], [-1, 0], [0, -1]]) {
      const xx = x + ex * d, yy = y + ey * d;
      if (xx < 0 || yy < 0 || xx >= GW || yy >= GH) continue;
      const q = OWN[yy * GW + xx]; if (q > o && (q >> 4) !== (o >> 4)) { gap = d; break; }
    }
    if (gap === 1) tier = 0; else if (gap <= 4) tier = Math.max(1, tier - (gap <= 2 ? 2 : 1));
    // A crease under each bump of the same clump (the front bump sits just above).
    else {
      const up = y > 0 ? OWN[i - GW] : -1, up2 = y > 1 ? OWN[i - 2 * GW] : -1;
      if (up > o && (up >> 4) === (o >> 4)) tier = Math.max(1, tier - 2);
      else if (up2 > o && (up2 >> 4) === (o >> 4)) tier = Math.max(1, tier - 1);
      // Leaf texture: short dark dashes (gaps between leaves) and a few bright leaf tips on the lit parts.
      else if (tier >= 3) {
        const cx = x >> 2, cy = y / 3 | 0, h = hash(cx, cy, 870);
        if (h < .22 && (x & 3) < 2 && y % 3 === 1) tier -= 1;
        else if (tier === 5 && h > .9 && (x & 3) === 2 && y % 3 === 0) tier = 6;
      }
    }
    if (tier && CROWN_CLUMPS[order[o >> 4]][1] > 520) tier = Math.max(1, tier - 1);
    L.set(x, y, P[tier]);
  }
  return L;
}
function groveCanopy(stage) {
  const out = new Img(GW, GH), L = crownLayer(stage), P = CROWN_P;
  out.stamp(L, P[0]);
  for (let y = 1; y < GH - 1; y++) for (let x = 1; x < GW - 1; x++)
    if (L.alpha(x, y) && !L.alpha(x + 1, y - 1) && L.alpha(x - 1, y + 1)) out.set(x, y, "#3e5e4c");  // moonlit edge
  // Hanging moss under the crown.
  for (let k = 0; k < 70; k++) {
    const x = Math.floor(90 + hash(k, 1, 830) * 1100), y0 = crownBottom(x);
    if (y0 < 100 || hash(k, 2, 830) < .4) continue;
    const len = 8 + hash(k, 3, 830) * 22;
    for (let i = 0; i < len; i++) out.set(x + Math.round(Math.sin(i * .3 + k)), y0 + i - 4, i % 3 ? P[3] : P[2]);
  }
  // Dream-leaves catch the light: more of them, brighter, the fuller the tree.
  for (let k = 0; k < 20 + stage * 70; k++) {
    const [cx, cy, rx, ry] = CROWN_CLUMPS[Math.floor(hash(k, 5, 831) * CROWN_CLUMPS.length)];
    const x = Math.floor(cx + (hash(k, 3, 831) - .5) * rx), y = Math.floor(cy + (hash(k, 4, 831) - .6) * ry);
    if (!L.alpha(x, y)) continue;
    out.set(x, y, CA("#ffe9a0", .45 + stage * .15)); if (k % 3 === 0) { out.set(x + 1, y, CA("#ffd27a", .5)); out.set(x, y + 1, CA("#ffd27a", .4)); }
  }
  return out;
}

// ---- branch segments: [bare twig, growing 25/50/75%, grown] ----
function bez(a, c, b, t) { const u = 1 - t; return [u * u * a[0] + 2 * u * t * c[0] + t * t * b[0], u * u * a[1] + 2 * u * t * c[1] + t * t * b[1]]; }
function segGeom(n) {
  const a = n.parent ? [byId[n.parent].x, byId[n.parent].y] : n.from, b = [n.x, n.y];
  const mx = (a[0] + b[0]) / 2, my = (a[1] + b[1]) / 2, dx = b[0] - a[0], dy = b[1] - a[1], len = Math.hypot(dx, dy);
  let px = -dy / len, py = dx / len; if (py > 0) { px = -px; py = -py; }
  const bend = len * .16 * (hash(n.x, n.y, 70) < .5 ? 1 : .6);
  const w0 = [0, 7, 5.5, 4.5, 4][Math.min(4, n.depth)];
  return { a, b, c: [mx + px * bend, my + py * bend], len, w0, w1: Math.max(2.5, w0 * .62) };
}
function segBox(g) {
  let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
  for (let t = 0; t <= 1; t += .02) { const [x, y] = bez(g.a, g.c, g.b, t); x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  const m = Math.ceil(g.w0) + 8;
  return [Math.floor(x0 - m), Math.floor(y0 - m), Math.ceil(x1 + m), Math.ceil(y1 + m)];
}
function drawTwig(L, g, ox, oy, seed) {
  const steps = Math.ceil(g.len * 2);
  for (let i = 0; i <= steps; i++) { const [x, y] = bez(g.a, g.c, g.b, i / steps); L.set(x - ox, y - oy, "#3a2616"); L.set(x - ox, y - oy + 1, "#24160c"); }
  for (const t of [.35, .7]) {
    const [x, y] = bez(g.a, g.c, g.b, t), s = hash(Math.floor(t * 10), 1, seed) < .5 ? -1 : 1;
    for (let i = 1; i < 5; i++) L.set(x - ox + s * i, y - oy - i, "#3a2616");
  }
}
function drawLiving(L, g, ox, oy, upto, seed) {
  const steps = Math.ceil(g.len * 2 * upto), fn = barkBig(seed);
  let last = g.a;
  for (let i = 1; i <= steps; i++) {
    const t = i / Math.ceil(g.len * 2), [x, y] = bez(g.a, g.c, g.b, t), w = g.w0 + (g.w1 - g.w0) * t;
    stroke(L, last[0] - ox, last[1] - oy, x - ox, y - oy, w, w, fn); last = [x, y];
  }
  return last;
}
function segment(n) {
  const g = segGeom(n), box = segBox(g), W = box[2] - box[0], H = box[3] - box[1], seed = hash(n.x, n.y, 71) * 1000 | 0;
  const frames = [];
  for (const upto of [0, .25, .5, .75, 1]) {
    const out = new Img(W, H), T = new Img(W, H), L = new Img(W, H);
    drawTwig(T, g, box[0], box[1], seed);
    out.put(T);
    if (upto > 0) {
      const tip = drawLiving(L, g, box[0], box[1], upto, seed);
      // Moss on top and leaf pairs along the grown part.
      for (let k = 1; k < 12; k++) {
        const t = k / 12; if (t > upto) break;
        const [x, y] = bez(g.a, g.c, g.b, t), s = k % 2 ? -1 : 1, lx = x - box[0], ly = y - box[1] - g.w0 * .4;
        L.set(lx + s * 2, ly - 2, LEAFG[3]); L.set(lx + s * 3, ly - 2, LEAFG[3]); L.set(lx + s * 3, ly - 3, LEAFG[4]); L.set(lx + s * 2, ly - 1, LEAFG[2]);
      }
      out.stamp(L, HB6[0]);
      if (upto < 1) { out.set(tip[0] - box[0], tip[1] - box[1], LEAFG[4]); out.set(tip[0] - box[0] + 1, tip[1] - box[1] - 1, "#d8f0a0"); }
    }
    frames.push(out);
  }
  return { frames, box, W, H };
}
