
// ================= Memory Grove: the Heartwood as a tech tree =================
// Tree space is 1280×960 px (native pixel art); every position below is in that space.
const GW = 1280, GH = 960;
// Heartwood 32 (assets/palette/heartwood32.json, injected by export.ps1 -Rebuild): colours by name.
const HW = Object.fromEntries(HW32.ramps.flatMap(r => r.colors.map(c => [c.name, c.hex])));
// Night bark: the Bark ramp (the Heartwood is the warm side), grain runs along the wood.
const HB6 = [HW.Void, HW.Night, HW.Root, HW.Bark, HW.Loam, HW.Loam];  // cool, grey-brown wood in the fog; the warmth is saved for the Hollow and the gold rim
const LEAFG = [HW.Deepmoss, HW.Moss, HW.Leaf, HW.Sprig, HW.Newleaf];
const SECTION = {
  perks:    { name: "Perks",    petals: ["#6a3c0c", "#b87818", "#e8b440", "#ffe39a"], mid: "#fff6d0", glow: "255,200,90" },
  families: { name: "Families", petals: ["#1a4222", "#338236", "#72c05a", "#c4ec98"], mid: "#f2ffd8", glow: "150,230,120" },
  cards:    { name: "Cards",    petals: ["#341a52", "#6e40a6", "#ae86e2", "#e4d4ff"], mid: "#fff0ff", glow: "190,150,255" },
};
// The three great limbs (Catmull-Rom through these points), with their widths at base and tip.
const LIMBS = {
  perks:    { pts: [[628, 648], [566, 596], [500, 540], [432, 482], [362, 424], [292, 366], [224, 306], [168, 244]], w: [38, 9] },
  families: { pts: [[640, 648], [640, 560], [645, 480], [636, 400], [641, 320], [645, 240], [638, 160], [640, 104]], w: [44, 10] },
  cards:    { pts: [[652, 648], [714, 596], [780, 540], [848, 482], [918, 424], [988, 366], [1056, 306], [1112, 244]], w: [38, 9] },
};
// The trunk leans in an S-curve (roots to the limbs' fork); trunkX(y) is its centre line.
const TRUNK_PTS = [[640, 905], [618, 846], [608, 786], [650, 730], [674, 668], [640, 610]];
const trunkX = y => { for (let k = 1; k < TRUNK_PTS.length; k++) if (y >= TRUNK_PTS[k][1]) { const [x0, y0] = TRUNK_PTS[k - 1], [x1, y1] = TRUNK_PTS[k]; return x0 + (x1 - x0) * (y0 - y) / (y0 - y1); } return 640; };
// Nodes: id, section, name, position, and either `parent` (another node) or `from` (a point on a limb).
// These positions are only starting points: spreadNodes() moves every node inside the crown's
// leaves and spreads them evenly before the branches and the layout are made.
// `lv` = levels (one node, pips shown by the game); `start` = grown from the beginning.
const NODES = [];
const N = (id, section, name, x, y, link, extra = {}) => NODES.push({ id, section, name, x, y, ...(typeof link === "string" ? { parent: link } : { from: link }), ...extra });
// Perks: three paths off the limb (meta_design.md "Section 1: Perks"), each growing up into the crown —
// Economy nearest the trunk, Survival in the middle, Choice at the far end (its side branch Early Bloom
// → Early Light → Kindling hangs below). The loadout slots sit below the limb, between the paths.
N("morning_stores", "perks", "Morning Stores", 486, 474, [500, 540], { lv: 3 });
N("rich_dew", "perks", "Rich Dew", 474, 404, "morning_stores", { lv: 3 });
N("rested_roots", "perks", "Rested Roots", 460, 334, "rich_dew", { lv: 2 });
N("seed_pouch", "perks", "Seed Pouch", 448, 264, "rested_roots");
N("sprout_bed", "perks", "Sprout Bed", 546, 450, "morning_stores");
N("deep_taproot", "perks", "Deep Taproot", 344, 358, [362, 424], { lv: 3 });
N("first_care", "perks", "First Care", 334, 288, "deep_taproot");
N("clear_sight", "perks", "Clear Sight", 324, 218, "first_care");
N("second_thoughts", "perks", "Second Thoughts", 206, 246, [224, 306], { lv: 2 });
N("let_go", "perks", "Let Go", 196, 180, "second_thoughts");
N("omen_reader", "perks", "Omen Reader", 188, 118, "let_go");
N("wider_dreams", "perks", "Wider Dreams", 244, 90, "omen_reader");
N("wider_roots", "perks", "Wider Roots", 140, 80, "omen_reader");  // Branch expansion: a wider family this run
N("heartwoods_crown", "perks", "The Heartwood's Crown", 520, 330, [480, 500]);  // The secret 6th slot: hidden until every other node is grown
N("early_bloom", "perks", "Early Bloom", 250, 372, "second_thoughts");
N("early_light", "perks", "Early Light", 232, 436, "early_bloom");
N("kindling", "perks", "Kindling", 214, 500, "early_light");
N("slot_4", "perks", "Loadout slot 4", 400, 520, [410, 466]);  // Slots 1–3 are open from the start
N("slot_5", "perks", "Loadout slot 5", 318, 540, "slot_4");
// Keepsakes twig (meta_design.md b8fd690c): cosmetics at the foot of the Perks limb, no gameplay effect.
// Off until their UnlockData exist (test_meta checks layout = data); Meta Game Code flips it with the .tres files.
const KEEPSAKES = false;
if (KEEPSAKES) {
N("golden_leaf", "perks", "Golden Leaf", 534, 540, [533, 568], { twig: true });
N("blossoms", "perks", "Blossoms", 548, 492, "golden_leaf", { twig: true });
N("gilded_pages", "perks", "Gilded Pages", 500, 520, "golden_leaf", { twig: true });
N("starlit_backs", "perks", "Starlit Card Backs", 536, 446, "blossoms", { twig: true });
}
// Families: a short branch of three per family (family, hidden branch, Ascension),
// alternating sides up the middle limb.
[["sporeling", "Sporeling", true], ["firefly_jar", "Firefly Jar", true], ["dewdrop", "Dewdrop", true], ["pebbling", "Pebbling"],
 ["rootling", "Rootling"], ["bellflower", "Bellflower", true], ["acorn", "Acorn"], ["nestling", "Nestling"], ["whirligig", "Whirligig"]]
  .forEach(([id, name, start], i) => {
    const side = i % 2 ? 1 : -1, ay = 604 - i * 50, ax = 640 + Math.sin((604 - ay) / 90) * 4;
    N(id, "families", name, ax + side * 38, ay - 20, [ax, ay], start ? { start: true } : {});
    N(id + "_hidden", "families", name + ": hidden branch", ax + side * 66, ay - 62, id);  // Final forms need no node any more
    N(id + "_ascension", "families", name + ": Ascension", ax + side * 96, ay - 108, id + "_hidden");
  });
// Memory Wardens: free blooms a boss leaves the first time it is dispelled (low on the Families limb).
N("memory_white_stag", "families", "Memory Warden: The White Stag", 600, 560, [640, 580]);
N("memory_pond_keeper", "families", "Memory Warden: The Pond Keeper", 680, 560, [640, 575]);
N("memory_moon_moth", "families", "Memory Warden: The Moon Moth", 640, 530, [640, 560]);
// Cards: one branch per build style, Legendary flower at the tip.
N("sharpened", "cards", "Sharpened", 952, 440, [942, 516]);
N("full_moon", "cards", "Full Moon", 1000, 288, "sharpened", { legendary: true });  // Reckless was cut in the pool trim
N("hunters_moon", "cards", "Hunter's Moon", 930, 300, "sharpened", { legendary: true });
N("tending_hands", "cards", "Tending Hands", 1062, 392, [1044, 465]);
N("nursery", "cards", "Nursery", 1090, 320, "tending_hands");
N("elders", "cards", "Elders", 1096, 260, "nursery");
N("the_old_ones", "cards", "The Old Ones", 1104, 190, "elders", { legendary: true });
N("seedbed", "cards", "Seedbed", 1172, 340, [1134, 404]);
N("rootbound", "cards", "Rootbound", 1228, 206, "seedbed", { legendary: true });  // Wild Planting was cut in the pool trim
N("mixed_company", "cards", "Mixed Company", 1190, 270, "seedbed");
N("menagerie", "cards", "Menagerie", 1170, 200, "mixed_company", { legendary: true });
N("one_line", "cards", "One Line", 832, 640, [846, 562]);
N("the_last_light", "cards", "The Last Light", 800, 710, "one_line", { legendary: true });
N("dead_wood", "cards", "Dead Wood", 962, 600, [944, 518]);
N("the_long_walk", "cards", "The Long Walk", 992, 676, "dead_wood", { legendary: true });
N("winding_roads", "cards", "Winding Roads", 950, 680, "dead_wood");
N("crossroads", "cards", "Crossroads", 960, 750, "winding_roads", { legendary: true });
N("bittersweet_dreams", "cards", "Bittersweet Dreams", 1152, 482, [1128, 410]);
N("lucid_dreaming", "cards", "Lucid Dreaming", 1190, 540, "bittersweet_dreams", { legendary: true });
// Deep Poison hangs under the limb past Keen Edges.
N("seeping", "cards", "Seeping", 1102, 552, [1090, 436]);
N("venom", "cards", "Venom", 1120, 622, "seeping");
N("nightshade", "cards", "Nightshade", 1132, 702, "venom", { legendary: true });
N("eternal_static", "cards", "Eternal Charge", 1160, 690, "venom", { legendary: true });
// Swift and Wide Reach near the trunk (where Storm and Spores grew); Daring, Hedgerows and Reclaiming below the limb.
N("quickening", "cards", "Quickening", 760, 522, [742, 602]);
N("light_feet", "cards", "Light Feet", 790, 452, "quickening");
N("whirlwind_heart", "cards", "Whirlwind Heart", 800, 380, "light_feet", { legendary: true });
N("broad_strokes", "cards", "Broad Strokes", 852, 482, [842, 560]);
N("far_reach", "cards", "Far Reach", 870, 410, "broad_strokes");
N("great_ripple", "cards", "Great Ripple", 884, 330, "far_reach", { legendary: true });
N("scarred_bark", "cards", "Scarred Bark", 760, 680, [760, 600]);
N("last_stand", "cards", "Last Stand", 750, 750, "scarred_bark");
N("last_leaf", "cards", "Last Leaf", 720, 810, "last_stand", { legendary: true });
N("restless_night", "cards", "Restless Night", 780, 820, "last_stand", { legendary: true });
N("bitter_hedges", "cards", "Bitter Hedges", 1040, 600, [1030, 500]);
N("briar_crown", "cards", "Briar Crown", 1020, 680, "bitter_hedges", { legendary: true });
N("rooted_nightmares", "cards", "Rooted Nightmares", 1060, 690, "bitter_hedges", { legendary: true });
N("reclaimed_earth", "cards", "Reclaimed Earth", 1200, 420, [1170, 400]);
N("thorn_and_bramble", "cards", "Thorn and Bramble", 1230, 480, "reclaimed_earth");
N("wildwood_reclaimed", "cards", "Wildwood Reclaimed", 1240, 550, "thorn_and_bramble", { legendary: true });
// Grove of Kin: the Kinship Legendary (its cards come from discovering a Kinship).
// Seeds (support and economy bets).
N("planted_promises", "cards", "Planted Promises", 1010, 470, [1000, 480]);
N("deep_promises", "cards", "Deep Promises", 1030, 400, "planted_promises");
N("golden_harvest", "cards", "Golden Harvest", 1050, 330, "deep_promises", { legendary: true });
// The Quiet Ones (support Wardens).
N("old_wood", "cards", "Old Wood", 900, 620, [900, 540]);  // Catchers removed: its cards come with the Acorn family
N("the_quiet_ones", "cards", "The Quiet Ones", 880, 760, "old_wood", { legendary: true });
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
  // A low mossy mound (lit on its upper left) the roots sink into, as on the map Heartwood.
  ellipse(out, 640, 948, 380, 66, (x, y, dx, dy) => pick([HW.Void, HW.Void, HW.Deepmoss, HW.Moss], clamp(.3 - dy * .45 + (pnoise(x, y, 9, 3) - .5) * .4, 0, 1), x, y));
  for (let k = 0; k < 900; k++) {
    const x = 120 + hash(k, 1, 4) * 1040, y = 880 + hash(k, 2, 4) * 80;
    if (((x - 640) / 370) ** 2 + ((y - 948) / 60) ** 2 > 1) continue;  // moss only on the mound, not the water
    if (hash(k, 3, 4) < .6) { out.set(x, y, LEAFG[1]); out.set(x, y - 1, LEAFG[2]); if (hash(k, 4, 4) < .4) out.set(x + 1, y - 2, LEAFG[3]); }
  }
  // A soft flat shadow under the whole tree.
  ellipse(out, 640, 918, 400, 42, SHADOW(.45));
  // Roots: big flared roots with ridges running along them.
  const rootFn = seed => (x, y, nx) => {
    const ridge = Math.abs(((pnoise(x * 3, y, 12, seed) * 7) % 1) - .5) < .1;
    return pick(HB6.slice(1), clamp(.58 - nx * .45 + (ridge ? -.28 : 0) + (pnoise(x, y, 6, seed + 1) - .5) * .12, 0, 1), x, y, .5);
  };
  // Short thick flares that bend down into the mound (their ends are hidden under its front lip).
  const roots = [[[598, 866], [548, 884], [508, 906], [488, 928]], [[682, 866], [732, 884], [772, 906], [792, 928]],
    [[612, 888], [590, 918], [582, 940]], [[668, 888], [690, 918], [698, 940]], [[640, 898], [642, 944]]];
  roots.forEach((r, i) => thickPath(L, catmull(r, 12), [48, 48, 36, 36, 30][i], 18, rootFn(20 + i)));
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
  const trunk = catmull(TRUNK_PTS, 24);
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
    if (n > .3) for (let d = 0; d < 1 + Math.floor((n - .3) * 14); d++) if (L.alpha(x, y + d)) M.set(x, y + d, LEAFG[Math.min(4, 2 + d % 3)]);
  }
  out.stamp(L, HB6[0]);
  // A 1 px warm gold rim on the upper-left edges (art_direction.md: light from the upper left, warm
  // gold rim on Wardens and the Heartwood), matching the map Heartwood.
  for (let y = 1; y < GH - 1; y++) for (let x = 1; x < GW - 1; x++)
    if (L.alpha(x, y) && !L.alpha(x - 1, y - 1) && L.alpha(x + 1, y + 1)) out.set(x, y, hash(x, y, 5) < .7 ? HW.Gold : HW.Oak);
  out.put(M);
  // Bark knots on the trunk and limb bases.
  for (const [x, y, r] of [[618, 700, 6], [664, 836, 5], [610, 870, 4], [588, 612, 4], [700, 612, 4], [646, 520, 4], [470, 574, 4], [900, 540, 4]]) {
    ellipse(out, x, y, r, r * 1.3, (xx, yy, dx, dy) => { const q = Math.hypot(dx, dy); return q > .75 ? HB6[1] : q > .4 ? HB6[3] : HB6[0]; });
  }
  // Ivy spiralling up the trunk.
  for (let i = 0; i < 260; i++) {
    const t = i / 260, y = 900 - t * 270, x = trunkX(y) + Math.sin(t * 11) * (56 - t * 22);
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
  // The mound's front lip over the roots' ends, then swamp mist dithered across the ground.
  for (let x = 300; x < 980; x++) {
    const top = 920 + Math.round((pnoise(x, 0, 14, 33) - .5) * 8 + ((x - 640) / 60) ** 2);
    for (let y = top; y < GH; y++) out.set(x, y, y - top < 2 ? HW.Moss : pick([HW.Deepmoss, HW.Deepmoss, HW.Void], (y - top) / 30, x, y, .3));
  }
  for (let y = 850; y < GH; y++) for (let x = 0; x < GW; x++) {
    const d = (1 - Math.abs(y - 915) / 65) * (1 - Math.abs(x - 640) / 700) * (.55 + pnoise(x, y, 22, 34) * .7);
    if (d > .15 && bay(x, y) < d * .32) out.set(x, y, d > .55 ? HW.Mist : d > .35 ? HW.Slate : HW.Dusk);  // opaque dither: blending would snap to muddy colours
  }
  // Pale glowing mushrooms on the roots.
  for (const [x, y, s] of [[470, 896, 1], [486, 900, .7], [812, 894, 1.1], [828, 899, .8], [560, 928, .8], [742, 930, .9], [372, 930, .7]]) {
    ellipse(out, x, y + 3 * s, 1.6 * s, 3 * s, "#c8c0d8");
    ellipse(out, x, y, 4.5 * s, 2.8 * s, (xx, yy, dx, dy) => dy < -.1 && dx < .2 ? "#d8ccf0" : "#9a88c8");
    out.set(x - 1, y - 1, "#f4f0ff"); ellipse(out, x, y, 9 * s, 7 * s, (xx, yy, dx, dy) => CA("#c8b0ff", Math.max(0, 1 - Math.hypot(dx, dy)) * .22));
  }
  // The loadout's waystones: five small carved stones in an arc at the roots ("Carry into the dream").
  // The loadout waystones are no longer painted here: the game draws grove/waystone.png at the
  // layout's loadout_stone_sets for the slots the player has (centred under the trunk).
  hollow(out, 610, 824);
  // Threads of dream-light curling up out of the Hollow into the trunk, dithered, thinning as they rise.
  for (const [ph, amp] of [[0, 16], [2.2, 12], [4.1, 20]]) for (let t = 0; t < 1; t += .002) {
    const y = 752 - t * 190, x = trunkX(y) - 20 + Math.sin(t * 9 + ph) * amp * (.4 + t);
    if (hash(Math.round(x), Math.round(y), 76) < .75 - t * .55) out.set(x, y, t < .35 ? HW.Glow : t < .7 ? HW.Gold : HW.Ember);
  }
  // Hanging moss strands under the limbs.
  for (let k = 0; k < 160; k++) {
    const x = Math.floor(80 + hash(k, 1, 50) * 1120);
    let y = 120; while (y < 700 && !(L.alpha(x, y) && !L.alpha(x, y + 1))) y++;
    if (y >= 700 || hash(k, 2, 50) < .45) continue;
    const len = 6 + hash(k, 3, 50) * 16;
    for (let i = 1; i < len; i++) out.set(x + Math.round(Math.sin(i * .3 + k)), y + i, i % 3 ? "#56624e" : "#3e4a3a");
  }
  // The limb sigils stay readable: no moss or mist over them.
  const nearSigil = (x, y) => [[600, 640], [641, 596], [684, 640]].some(([sx, sy]) => Math.hypot(x - sx, y - sy) < 18);
  // Moss patches all over the trunk and roots, like the title's giant.
  for (let y = 560; y < 960; y++) for (let x = 400; x < 880; x++) {
    if (!L.alpha(x, y) || (x > 560 && x < 665 && y > 735 && y < 835) || nearSigil(x, y)) continue;  // keep the Hollow and sigils clear
    const n = pnoise(x, y, 14, 95) * .7 + pnoise(x, y, 5, 96) * .3;
    if (n > .6) out.set(x, y, n > .72 ? HW.Moss : HW.Deepmoss);
    else if (n > .57 && hash(x, y, 97) < .5) out.set(x, y, HW.Leaf);
  }
  // A cool veil of mist over the wood (the fog's teal and dusk, never white), thicker low down.
  for (let y = 520; y < GH; y++) for (let x = 0; x < GW; x++) {
    if (!out.alpha(x, y) || (x > 570 && x < 655 && y > 745 && y < 830) || nearSigil(x, y)) continue;
    const d = clamp((y - 520) / 300, 0, 1) * clamp((900 - y) / 60, 0, 1) * (.55 + pnoise(x, y, 50, 101) * .6);  // fades out before the roots and waystones
    if (bay(x, y) < d * .24) out.set(x, y, d > .6 ? HW.Pool : HW.Dusk);
  }
  // Wisps of mist drifting IN FRONT of the tree and on across the background at the same heights, so
  // the tree stands inside the fog. Cool, sparse, opaque dither; the Hollow stays clear.
  const wisps = (cy, h, dens, seed) => { for (let y = cy - h; y < cy + h; y++) for (let x = 0; x < GW; x++) {
    if ((x > 575 && x < 650 && y > 748 && y < 828) || nearSigil(x, y)) continue;
    if (LOADOUT_STONES.some(([sx, sy]) => Math.hypot(x - sx, (y - sy) * 1.3) < 26)) continue;  // waystones stay clear
    const wob = (pnoise(x, 0, 90, seed + 2) - .5) * h * 1.2, yy = y - wob;  // the band drifts up and down
    const band = clamp(1 - Math.abs(yy - cy) / h, 0, 1) ** 1.5, n = pnoise(x * .6, yy, 34, seed) * .75 + pnoise(x, yy, 12, seed + 1) * .25;
    const d = band * clamp((n - .36) * 2.6, 0, 1);
    if (d > 0 && bay(x, y) < d * dens) out.set(x, y, d > .75 ? (y > 850 ? HW.Bruise : HW.Shade) : HW.Dusk);  // muted dream mist, violet only in the thick low cores
  } };
  // The drifting mist bands are separate strips now (groveMistStrip, animated by GroveTreeView).
  // Mist curling across the trunk itself (a little denser than the haze round it), the Hollow clear.
  for (let y = 590; y < 900; y++) for (let x = 470; x < 820; x++) {
    if ((x > 572 && x < 652 && y > 745 && y < 832) || nearSigil(x, y)) continue;
    const tx = trunkX(Math.min(y, 905)), dx = (x - tx) / 150;
    const n = pnoise(x * .7, y, 28, 131) * .7 + pnoise(x, y, 10, 132) * .3, curl = Math.sin(y / 38 + dx * 3) * .5 + .5;
    const d = Math.max(0, 1 - dx * dx) * clamp((n - .4) * 2.4, 0, 1) * (.55 + curl * .45) * (.6 + (y - 590) / 310 * .5);
    if (d > 0 && bay(x, y) < d * .45) out.set(x, y, d > .7 ? HW.Shade : HW.Dusk);
  }
  return out;
}

// The hollow: a doorway grown into the trunk. A pointed opening that leans with the trunk, a rolled
// bark lip (lit outside, warm where the glow catches its inner edge), grain curling round it, warm
// light spilling onto the bark and the ground, and a root for a doorstep.
function hollow(img, cx, by) {
  const y0 = by - 68, halfW = y => { const k = clamp((y - y0) / 24, 0, 1); return (15.5 * Math.sqrt(k) + (y > by - 20 ? (y - (by - 20)) * .08 : 0)) + (pnoise(0, y, 6, 991) - .5) * 2.4; };
  const inOpen = (x, y, g = 0) => y >= y0 - g && y <= by && Math.abs(x + .5 - cx - (y - by) * .06) <= halfW(y + g * .3) + g;
  // A narrow banded halo just outside the lip (1-2 px steps, never a soft blur).
  for (let y = by - 90; y < by + 4; y++) for (let x = cx - 30; x < cx + 30; x++) {
    if (!img.alpha(x, y) || inOpen(x, y, 7)) continue;
    if (inOpen(x, y, 9)) img.set(x, y, CA(HW.Glow, .3)); else if (inOpen(x, y, 11)) img.set(x, y, CA(HW.Glow, .14));
  }
  ellipse(img, cx + 2, by + 6, 24, 6, (x, y, dx, dy) => CA(HW.Glow, Math.hypot(dx, dy) < .6 ? .22 : .1));  // banded pool of light
  for (const k of [10, 15, 21]) for (let y = y0 - k - 8; y <= by; y++) for (let x = cx - 50; x <= cx + 50; x++) {
    const q = Math.hypot((x + .5 - cx) / (17 + k), Math.min(0, y - (by - 34)) / (36 + k)), q2 = Math.hypot((x + .5 - cx) / (18 + k), Math.min(0, y - (by - 34)) / (37 + k));
    if (!img.alpha(x, y) || q <= 1 || q2 > 1 || inOpen(x, y, 7) || pnoise(x, y, 5, 992 + k) > .62) continue;
    img.set(x, y, HB6[1]); if (k === 10 && hash(x, y, 993) < .5) img.set(x - 1, y - 1, HB6[4]);
  }
  for (let y = y0 - 8; y <= by + 1; y++) for (let x = cx - 40; x <= cx + 40; x++) {
    if (!inOpen(x, y, 6) || inOpen(x, y)) continue;
    const inner = inOpen(x, y, 2), mid = inOpen(x, y, 4), left = x < cx;
    img.set(x, y, inner ? (left ? "#8a4a22" : "#b8703a") : mid ? (left || y < y0 + 6 ? HB6[4] : HB6[3]) : (left && y < by - 20 ? HB6[5] : HB6[2]));
  }
  for (let y = y0; y <= by; y++) for (let x = cx - 30; x <= cx + 30; x++) {
    if (!inOpen(x, y)) continue;
    const e = inOpen(x, y, -2) ? (inOpen(x, y, -4) ? 0 : .5) : 1, r = Math.hypot((x - cx) / 20, (y - (by - 16)) / 42) + (bay(x, y) - .5) * .12;
    let c = r < .3 ? "#fff4c8" : r < .55 ? "#ffd27a" : r < .8 ? "#e0883a" : r < 1.05 ? "#8a4a1a" : "#4a2410";
    if (e === 1) c = x < cx || y < y0 + 10 ? "#1a0e08" : "#4a2410"; else if (e === .5 && (x < cx - 4 || y < y0 + 12)) c = r < .55 ? "#e0883a" : "#4a2410";
    img.set(x, y, c);
  }
  stroke(img, cx - 24, by + 2, cx - 4, by - 1, 5, 4, (x, y, nx) => nx < -.3 ? HB6[4] : nx > .4 ? HB6[1] : HB6[3]);
  stroke(img, cx - 4, by - 1, cx + 22, by + 3, 4, 3, (x, y, nx) => nx < -.3 ? "#c07840" : nx > .4 ? HB6[1] : HB6[3]);
  for (let x = cx - 22; x < cx + 20; x += 2) if (hash(x, 1, 994) < .6) { img.set(x, by - 4 + Math.round(Math.abs(x - cx + 4) * .05), LEAFG[2]); img.set(x + 1, by - 5 + Math.round(Math.abs(x - cx + 4) * .05), LEAFG[3]); }
  for (let x = cx - 8; x <= cx + 8; x++) if (hash(x, 2, 994) < .7) { const yy = y0 - 6 + Math.round(Math.abs(x - cx) * .5); img.set(x, yy, LEAFG[2]); if (hash(x, 3, 994) < .5) img.set(x, yy - 1, LEAFG[4]); }
}

// The loadout stones at the roots (centres), left to right = slot 1 … 5.
const LOADOUT_STONES = [[478, 906], [558, 926], [640, 934], [722, 926], [802, 906]];
const MOON = [1062, 118];

// ---- the night sky behind it: moon, stars, two layers of distant forest, low fog ----
function grovesky(pad = 0) {
  // pad > 0 draws the same scene pad px wider on each side (grove_backdrop.png), for screens wider than 4:3.
  const X0 = -pad, X1 = GW + pad, padImg = () => { const b = new Img(GW + 2 * pad, GH); return { base: b, w: b.w, h: GH, set: (x, y, c) => b.set(x + pad, y, c), alpha: (x, y) => b.alpha(Math.floor(x) + pad, y), get: (x, y) => b.get(Math.floor(x) + pad, y) }; };
  // The title screen's world: a misty swamp forest at night. Cool slate fog brightening toward the
  // horizon, tall dark trunks in three layers fading into it, pale shafts of light, still dark water.
  const out = padImg(), SKY = [HW.Void, HW.Void, HW.Night, HW.Night, HW.Pool, HW.Pool, HW.Slate];
  const fogAt = (x, y) => clamp(Math.max(0, 1 - Math.hypot((x - 640) / 760, (y - 640) / 420)) * .9 + (y / GH) * .25 + (pnoise(x, y, 120, 61) - .5) * .18, 0, 1);
  for (let y = 0; y < GH; y++) for (let x = X0; x < X1; x++) {
    out.set(x, y, pick(SKY, fogAt(x, y), x, y, .9));
    const h = hash(x, y, 62), clear = Math.max(0, 1 - y / 360);
    if (h < .0022 * clear * clear) out.set(x, y, h < .0006 ? HW.Moonlight : HW.Slate);
  }
  // A few twinkling four-point stars high up.
  for (let k = 0; k < 22; k++) {
    const x = (X0 + hash(k, 1, 75) * (X1 - X0)) | 0, y = hash(k, 2, 75) * 260 | 0;
    if (Math.hypot(x - MOON[0], y - MOON[1]) < 90) continue;
    out.set(x, y, HW.Moonlight);
    for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) out.set(x + a, y + b, hash(k, 3, 75) < .4 ? HW.Mist : HW.Dusk);
  }
  // The moon behind the fog.
  ellipse(out, MOON[0], MOON[1], 58, 58, (x, y, dx, dy) => { const r = Math.hypot(dx, dy); return r < .72 ? HW.Dusk : bay(x, y) < (1 - r) * 1.2 ? HW.Dusk : null; });
  ellipse(out, MOON[0], MOON[1], 30, 30, (x, y, dx, dy) => {
    const sea = pnoise(x, y, 9, 64) > .6;
    return pick([HW.Stone, HW.Mist, HW.Moonlight, HW.Moonlight], clamp(.75 - dx * .3 - dy * .3 - (sea ? .3 : 0), 0, 1), x, y, .5);
  });
  // Pale shafts of light falling through the fog between the trunks.
  for (const [sx, w, lean] of [[250, 60, .12], [470, 44, .08], [860, 52, -.06], [1060, 70, -.1]]) for (let y = 0; y < 880; y++) for (let x = sx - w; x < sx + w; x++) {
    const cx = sx + (y - 440) * lean, d = Math.abs(x + (y - 440) * lean - sx) / w, a = (1 - d) * (.35 + y / 880 * .5) * (.6 + pnoise(x, y, 40, 80) * .6);
    const px = Math.round(x + (cx - sx));
    if (a > .15 && bay(px, y) < (a - .15) * .75) out.set(px, y, a > .5 ? HW.Mist : HW.Slate);
  }
  // Tall trunks in three layers: far ones pale in the fog, near ones almost black, a lit left edge on each.
  // A faint violet dream shimmer in the fog up high (opaque dither, sparse).
  for (let y = 0; y < 420; y++) for (let x = X0; x < X1; x++) {
    const d = pnoise(x, y, 140, 90) * (1 - y / 420);
    if (d > .45 && bay(x, y) < (d - .5) * .5) out.set(x, y, HW.Bruise);
  }
  // Floating islands, like the title screen's: a dark rock islet with a moss top, a tiny tree, and
  // roots dangling below. `fog` 0..1 = how far back (fainter colours, dithered away).
  const island = (cx, cy, w, fog, seed) => {
    const I = padImg(), rock = fog > .5 ? [HW.Night, HW.Dusk, HW.Slate] : [HW.Void, HW.Night, HW.Dusk];
    for (let y = cy - 4; y < cy + w * .7; y++) for (let x = cx - w; x <= cx + w; x++) {
      const u = (x - cx) / w, v = (y - cy) / (w * .7), edge = 1 - Math.abs(u) ** 1.6 - (pnoise(x, y, 6, seed) - .5) * .3;
      if (v < 0 ? Math.abs(u) > .98 : v > edge) continue;
      I.set(x, y, v < .12 ? (fog > .5 ? HW.Pool : HW.Deepmoss) : pick(rock, clamp(.6 - u * .4 - v * .5, 0, 1), x, y, .5));
    }
    for (let k = 0; k < 5; k++) {  // dangling roots
      const rx = cx + (hash(seed, k, 91) - .5) * w * 1.2, len = 14 + hash(seed, k, 92) * w * .9;
      for (let i = 0; i < len; i++) I.set(rx + Math.sin(i * .3 + k) * 1.5, cy + w * .5 * (1 - Math.abs(rx - cx) / w) + i, rock[0]);
    }
    const tx = cx + (hash(seed, 1, 93) - .5) * w * .6;  // a tiny tree on top
    for (let i = 0; i < 16; i++) I.set(tx, cy - 3 - i, rock[0]);
    blob(I, tx, cy - 22, 9, 7, fog > .5 ? [HW.Night, HW.Pool, HW.Pool] : [HW.Deepmoss, HW.Moss, HW.Leaf], { seed, dither: 0 });
    for (let y = 0; y < GH; y++) for (let x = X0; x < X1; x++) if (I.alpha(x, y) && bay(x, y) < 1 - fog * .45) out.set(x, y, I.get(x, y));
  };
  // Drifting pale motes in the air.
  for (let k = 0; k < 22; k++) {
    const x = (X0 + hash(k, 1, 94) * (X1 - X0)) | 0, y = hash(k, 2, 94) * 860 | 0;
    out.set(x, y, k % 4 ? HW.Mist : HW.Wraithlight);
    if (k % 5 === 0) for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) out.set(x + a, y + b, HW.Slate);
  }
  // A background trunk: it rises out of the water on a root flare, bends a little, and dissolves into
  // the fog as it climbs (dithered, `fade` = how far up it still reads). Bark grain runs along it,
  // moss clings to its lit left side, a branch or two reaches out.
  const trunk = (x0, w, lean, bend, seed, cols, rim, fade) => {
    const top = 880 - fade;
    const at = y => x0 + (y - 880) * lean + Math.sin(y / 150 + seed) * bend * (1 - y / 880);
    for (let y = Math.max(0, top - 120); y < 884; y++) {
      const vis = clamp((y - (top - 120)) / 140, 0, 1);  // how solid it is at this height
      const flare = y > 840 ? (y - 840) / 44 : 0, cx = at(y), ww = w * (1 + flare * flare * 1.4) + (pnoise(y, 0, 24, seed) - .5) * 2.5;
      for (let x = Math.floor(cx - ww / 2); x <= cx + ww / 2; x++) {
        if (bay(x, y) >= vis) continue;
        const nx = (x - cx) / (ww / 2), grain = Math.abs(((nx + 1) * 2.5 + pnoise(x, y, 40, seed) * .6) % 1 - .5) > .38;
        let c = nx < -.72 ? rim : pick(cols, clamp(.55 - nx * .35 + (grain ? -.25 : 0), 0, 1), x, y, .4);
        if (nx < -.1 && pnoise(x, y, 9, seed + 7) > .72) c = HW.Deepmoss;  // moss on the lit side
        out.set(x, y, c);
      }
    }
    for (let k = 0; k < 2; k++) {  // a branch or two, reaching up and out, fading with the trunk
      const y = top + 40 + hash(seed, k, 81) * (fade * .5), s = hash(seed, k, 82) < .5 ? -1 : 1, cx = at(y);
      if (y > 700) continue;
      const pts = catmull([[cx, y], [cx + s * w * 1.4, y - 26], [cx + s * w * 2.6, y - 70]], 8);
      for (let i = 1; i < pts.length; i++) stroke(out, pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1], Math.max(2, w * .3 * (1 - i / pts.length)), 1.5, (xx, yy) => bay(xx, yy) < clamp((yy - (top - 120)) / 140, 0, 1) ? cols[0] : null);
    }
  };
  const mistBand = (y0, y1, dens, col) => { for (let y = y0; y < y1; y++) for (let x = X0; x < X1; x++) { const u = (y - y0) / (y1 - y0), d = Math.sin(Math.PI * u) ** 2 * (.4 + pnoise(x, y, 70, 83 + y0) * .9); if (bay(x, y) < d * dens) out.set(x, y, col); } };  // smooth top and bottom, no hard edge
  // Far: pale, barely there. Middle: darker, reaching higher. Near: one dark trunk at each edge.
  for (const x of [180, 430, 860, 1080]) trunk(x + (hash(x, 1, 84) - .5) * 40, 10 + hash(x, 2, 84) * 8, (hash(x, 3, 84) - .5) * .08, 10, x, [HW.Pool, HW.Pool, HW.Slate], HW.Slate, 360 + hash(x, 4, 84) * 160);
  if (pad) for (const x of [-520, -260, 1540, 1790]) trunk(x + (hash(x + 999, 1, 84) - .5) * 40, 10 + hash(x + 999, 2, 84) * 8, (hash(x + 999, 3, 84) - .5) * .08, 10, x, [HW.Pool, HW.Pool, HW.Slate], HW.Slate, 360 + hash(x + 999, 4, 84) * 160);
  mistBand(380, 900, .34, HW.Slate);
  for (const x of [90, 330, 960, 1170]) trunk(x + (hash(x, 1, 85) - .5) * 50, 20 + hash(x, 2, 85) * 12, (hash(x, 3, 85) - .5) * .1, 14, x + 20, [HW.Night, HW.Night, HW.Pool], HW.Pool, 560 + hash(x, 4, 85) * 200);
  if (pad) for (const x of [-420, -140, 1420, 1700]) trunk(x + (hash(x + 999, 1, 85) - .5) * 50, 20 + hash(x + 999, 2, 85) * 12, (hash(x + 999, 3, 85) - .5) * .1, 14, x + 20, [HW.Night, HW.Night, HW.Pool], HW.Pool, 560 + hash(x + 999, 4, 85) * 200);
  mistBand(520, 900, .28, HW.Pool);
  island(200, 640, 40, .35, 1); island(1090, 610, 34, .4, 2); island(410, 730, 20, .55, 3); island(890, 710, 22, .5, 4); island(1215, 750, 14, .6, 5);
  if (pad) { island(-330, 600, 36, .4, 6); island(1600, 660, 30, .45, 7); }
  for (const [x, w, lean] of [[28, 58, .04], [1256, 62, -.05]]) trunk(x, w, lean, 10, x, [HW.Void, HW.Dread, HW.Night], HW.Dusk, 900);
  mistBand(660, 900, .3, HW.Slate);
  // Still dark water at the bottom: ripple lines, the trunks' dim reflections, and the Heartwood's
  // warm light reflected in a broken column below it.
  for (let y = 872; y < GH; y++) for (let x = X0; x < X1; x++) {
    const src = out.get(x, Math.max(0, 872 - (y - 872) * 2 - 1));
    out.set(x, y, ((y - 872) % 5 === 0 && hash(x >> 3, y, 86) < .5) ? HW.Dusk : pick([HW.Void, HW.Night, HW.Pool], .25 + (src[0] + src[1] + src[2]) / 765 * .6 + (pnoise(x, y, 30, 87) - .5) * .2, x, y, .7));
    const warm = Math.max(0, 1 - Math.abs(x - 640) / 260) * Math.max(0, 1 - (y - 872) / 110) * 1.3;
    if (warm > .1 && (y - 872) % 3 !== 2 && hash(x >> 2, y, 88) < warm * .8) out.set(x, y, warm > .6 ? HW.Glow : warm > .35 ? HW.Gold : HW.Ember);
  }
  return out.base;
}

// ---- the crown: big lit lobes made of small leaf clusters, in chunky 2× pixels ----
// A few big lobes carry the light (bright top-left, a dark belly underneath); the texture is many
// small leaf clusters, each one flat tone from the lobe under it with a lit tip and a dark rim along
// its bottom, upper clusters overlapping lower ones. Drawn at half resolution and scaled up 2×.
// The night greens (colours unchanged), seven tiers.
// The crown: green-black in the shadows and the belly (Dread / Night are the sky's colours, so the tree would melt into it), cold moonlit Pool, then Moss where the light reaches.
const CROWN_P = [HW.Void, HW.Void, HW.Deepmoss, HW.Deepmoss, HW.Pool, HW.Moss, HW.Moss];  // shade green-black, lit tops cool Pool / Moss (bright Leaf only on a few top clusters)
const CROWN_PX = 2, CROWN_SEED = 970;
// Stages grow the crown outward: the clusters over the limbs are always there, the edges fill in.
const CROWN_SHARE = [.72, .8, .9, 1];
const CROWN = (() => {
  const s = CROWN_PX, W = Math.ceil(GW / s), H = Math.ceil(GH / s), seed = CROWN_SEED;
  const inCrown = (x, y) => crownIn(x * s, y * s);
  // Lobes: big packed discs inside the crown's outline; upper ones in front.
  const lobes = [], cand = [];
  for (let k = 0; k < 4000; k++) {
    const x = hash(k, 1, seed) * W, y = hash(k, 2, seed) * H * .7, r = 110 / s + hash(k, 3, seed) * 90 / s;
    if (inCrown(x, y) && inCrown(x, y + r * .5)) cand.push([x, y, r]);
  }
  cand.sort((a, b) => b[2] - a[2]);
  for (const c of cand) if (lobes.every(l => Math.hypot(l[0] - c[0], l[1] - c[1]) > (l[2] + c[2]) * .62)) lobes.push(c);
  lobes.sort((a, b) => b[1] - a[1]);
  // How lit a point is: its lobe's dome shading, brighter at the top of the crown, darker low and right.
  const macro = (x, y) => {
    if (!inCrown(x, y + 14 / s)) return -1;
    let t = -1;
    lobes.forEach(([lx, ly, r]) => {
      const dx = (x - lx) / r, dy = (y - ly) / (r * .85), q = dx * dx + dy * dy;
      if (q <= 1) t = clamp((-dx * .5 - dy * .8 + Math.sqrt(1 - q) * .45 + .25) / 1.3, 0, 1);  // the front lobe wins
    });
    return t < 0 ? -1 : t * .95 + .24 - (y * s - 150) / 520 * .62 - (x * s - 560) / 1280 * .1;
  };
  // Leaf clusters on a jittered grid: [x, y, r, light, rank] (rank orders the stages, centre first).
  const clusters = [], sp = 22 / s;
  for (let gy = 0; gy < H * .78; gy += sp * .8) for (let gx = 0; gx < W; gx += sp) {
    const x = gx + (hash(gx * 7, gy * 3, seed + 1) - .5) * sp * .9 + (Math.round(gy / (sp * .8)) % 2) * sp / 2, y = gy + (hash(gx * 5, gy * 11, seed + 2) - .5) * sp * .7;
    const m = macro(x, y); if (m < -.5) continue;
    clusters.push([x, y, (12 + hash(gx, gy, seed + 3) * 7) / s, m, Math.hypot((x * s - 640) / 620, (y * s - 380) / 330) + hash(gx * 3, gy * 5, 840) * .08]);
  }
  clusters.sort((a, b) => b[1] - a[1]);
  const ranks = clusters.map(c => c[4]).sort((a, b) => a - b);
  return { W, H, clusters, cut: CROWN_SHARE.map(sh => ranks[Math.max(0, Math.round(ranks.length * sh) - 1)]) };
})();
// A drip: a chain of shrinking blobs hanging straight down from the crown's belly.
function crownDrip(cx, cy, len, w, k) {
  const b = [[cx, cy, w * 1.2, w]];
  for (let y = 0, r = w; y < len && r > 2.5; y += r * .9, r *= .86) b.push([cx + Math.sin(y * .08 + k) * 2, cy + y, r, r * 1.1]);
  return b;
}
function groveCanopy(stage) {
  const { W, H, clusters, cut } = CROWN, s = CROWN_PX, P = CROWN_P, seed = CROWN_SEED;
  const L = new Img(W, H), TIER = new Int8Array(W * H).fill(-1), shown = clusters.filter(c => c[4] <= cut[stage]);
  shown.forEach(([cx, cy, r, m], k) => {
    const base = clamp(1 + Math.floor(m * 5), 1, 5);
    for (let y = Math.floor(cy - r); y <= cy + r; y++) for (let x = Math.floor(cx - r * 1.2); x <= cx + r * 1.2; x++) {
      if (x < 0 || y < 0 || x >= W || y >= H) continue;
      const dx = (x + .5 - cx) / (r * 1.15), dy = (y + .5 - cy) / r, a = Math.atan2(dy, dx);
      const q = Math.hypot(dx, dy) / (1 + .16 * Math.sin(a * 3 + k) + .1 * Math.sin(a * 5 + k * 1.3)); if (q > 1) continue;
      let t = base;
      if (dy > .3 && q > .72) t = base - 2;                                   // dark rim under the cluster
      else if (dy > .05 && q > .55) t = base - 1;
      else if (dx < .15 && dy < -.02 && q < .72 && base >= 2) t = base + 1;   // lit tip
      TIER[y * W + x] = clamp(t, 1, 6);
    }
  });
  // The dark belly along the crown's underside, and a few rounded drips hanging from it.
  const bottomAt = x => { for (let y = Math.floor(H * .78); y > 0; y--) if (TIER[y * W + x] >= 0) return y; return -1; };
  for (let x = 0; x < W; x++) {
    const bottom = bottomAt(x); if (bottom < 0) continue;
    for (let y = bottom - Math.floor(16 / s); y <= bottom; y++) if (y > 0 && TIER[y * W + x] >= 0) TIER[y * W + x] = y > bottom - 7 / s ? 2 : Math.min(TIER[y * W + x], 3);  // a dark green belly, not black
  }
  for (let X = 4; X < W; X += Math.round(30 / s)) {
    if (hash(X, 0, seed + 5) > .55) continue;
    const bottom = bottomAt(X); if (bottom < 60 / s) continue;
    const w = (5 + hash(X, 1, seed + 5) * 6) / s, len = (8 + hash(X, 2, seed + 5) ** 2 * 44) / s;
    crownDrip(X, bottom - w * .5, len, w, X).forEach(([bx, by, rx, ry]) => {
      for (let y = Math.floor(by - ry); y <= by + ry; y++) for (let x = Math.floor(bx - rx); x <= bx + rx; x++)
        if (x >= 0 && y >= 0 && x < W && y < H && ((x + .5 - bx) / rx) ** 2 + ((y + .5 - by) / ry) ** 2 <= 1) TIER[y * W + x] = 2;
    });
  }
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const t = TIER[y * W + x]; if (t < 0) continue;
    // The deepest shade is a checker of near-black and Deepmoss, so it reads as leafy shadow (dark
    // green from afar), never as the sky showing through.
    L.set(x, y, t === 1 ? ((x + y) % 2 ? P[0] : P[2]) : (t >= 5 && y * s < 300 && hash(x, y, seed + 6) < .08 ? HW.Leaf : P[t]));  // bright Leaf only on the crown's topmost clusters
  }
  const small = new Img(W, H); small.stamp(L, P[0]);
  for (let y = 1; y < H - 1; y++) for (let x = 1; x < W - 1; x++)
    if (L.alpha(x, y) && !L.alpha(x - 1, y - 1) && !L.alpha(x - 3, y - 3) && !L.alpha(x - 6, y - 6) && L.alpha(x + 1, y + 1) && y * s < 420 && hash(x, y, 35) < .8) small.set(x, y, HW.Gold);  // only the outer edge, not every gap  // warm rim where the light catches the upper-left edge
  // Scale up 2× into the tree's space.
  const out = new Img(GW, GH);
  for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) { const X = x / s | 0, Y = y / s | 0; if (small.alpha(X, Y)) out.set(x, y, small.get(X, Y)); }
  // The same cool veil over the crown, faint at the top, a little thicker at its underside.
  for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) {
    if (!out.alpha(x, y)) continue;
    const d = clamp((y - 150) / 500, 0, 1) * (.5 + pnoise(x, y, 60, 102) * .6);
    if (bay(x, y) < d * .22) out.set(x, y, d > .55 ? HW.Pool : HW.Dusk);
  }
  // Violet dream mist drifting across the crown itself, over the leaves (the shape stays the same for
  // the node layout, which reads this layer).
  for (const [cy, h, seed, dens] of [[360, 46, 122, .16], [490, 44, 123, .3]]) for (let y = cy - h * 2; y < cy + h * 2; y++) for (let x = 0; x < GW; x++) {
    if (y < 0 || !out.alpha(x, y)) continue;
    const wob = (pnoise(x, 0, 90, seed + 2) - .5) * h * 1.2, yy = y - wob;
    const band = clamp(1 - Math.abs(yy - cy) / h, 0, 1) ** 1.5, n = pnoise(x * .6, yy, 34, seed) * .75 + pnoise(x, yy, 12, seed + 1) * .25;
    const d = band * clamp((n - .36) * 2.6, 0, 1);
    if (d > 0 && bay(x, y) < d * dens) out.set(x, y, d > .8 ? HW.Shade : HW.Dusk);  // muted: mostly dusk, violet only at the cores
  }
  // A wisp of mist drifting in front of the crown's underside and the top of the trunk, continuing
  // across the open fog (this layer is drawn over the limbs and trunk).
  for (let y = 560; y < 640; y++) for (let x = 0; x < GW; x++) {
    if (!out.alpha(x, y)) continue;  // only over the leaves: the open-air part is in grove_tree.png (the layout reads this layer's shape)
    const band = Math.sin(Math.PI * (y - 560) / 80) ** 2, n = pnoise(x * .35, y, 26, 113) * .8 + pnoise(x, y, 9, 114) * .2;
    const d = band * clamp((n - .32) * 2.4, 0, 1);
    if (d > 0 && bay(x, y) < d * .25) out.set(x, y, d > .8 ? HW.Shade : HW.Dusk);
  }
  // Long swamp-moss drapes hanging from the crown.
  for (let k = 0; k < 140; k++) {
    const x = 70 + hash(k, 1, 99) * 1140 | 0; let y = 600; while (y > 60 && !out.alpha(x, y)) y--;
    if (y < 150 || hash(k, 2, 99) < .3) continue;
    const len = 20 + hash(k, 3, 99) ** 1.5 * 90;
    for (let i = 0; i < len; i++) { const xx = x + Math.round(Math.sin(i * .12 + k) * 2); out.set(xx, y + i, i > len * .75 ? HW.Deepmoss : i % 4 ? HW.Moss : HW.Deepmoss); if (i % 6 === 3) out.set(xx + (k % 2 ? 1 : -1), y + i, HW.Leaf); }
  }
  // Dream motes floating in and round the crown: tiny gold and pale-violet crosses (opaque, 1 px arms),
  // small enough never to read as nodes; more of them the fuller the tree.
  for (let k = 0; k < 30 + stage * 12; k++) {
    const x = 20 + hash(k, 1, 77) * 1240 | 0, y = 30 + hash(k, 2, 77) * 820 | 0, gold = k % 3 !== 0, open = !out.alpha(x, y);
    if (open) for (const [r, a] of [[3.5, .3], [2.5, .5]]) ellipse(out, x, y, r, r, (xx, yy) => out.alpha(xx, yy) ? null : CA(gold ? HW.Gold : HW.Wraithlight, a));
    out.set(x, y, gold ? HW.Heartlight : HW.Moonlight);
    if (k % 2 || open) for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) out.set(x + a, y + b, gold ? HW.Glow : HW.Wraithlight);
  }
  // Dream-leaves catch the light: more of them, brighter, the fuller the tree.
  for (let k = 0; k < 20 + stage * 60; k++) {
    const c = shown[Math.floor(hash(k, 5, 831) * shown.length)], x = Math.floor(c[0] * s), y = Math.floor((c[1] - c[2] * .3) * s);
    if (!out.alpha(x, y)) continue;
    out.set(x, y, CA("#ffe9a0", .45 + stage * .15)); if (k % 3 === 0) { out.set(x + 1, y, CA("#ffd27a", .5)); out.set(x, y + 1, CA("#ffd27a", .4)); }
  }
  return out;
}

// ---- node layout: every node inside the leaves, spread evenly ----
// Runs once the full crown (stage 3) exists: nodes outside it slide toward its centre, then each
// node repeatedly moves toward the middle of the leaf area nearest to it (Lloyd relaxation), so the
// nodes fill the crown, gaps between the limbs included, while staying within reach of their parent.
let CROWN_MASK = null;
const inMask = (x, y, m) => !CROWN_MASK || [[0, 0], [m, 0], [-m, 0], [0, m], [0, -m]].every(([a, b]) => CROWN_MASK.alpha(Math.round(x + a), Math.round(y + b)));
// The great limbs run up through the crown and end just inside its outer edge (only a tip that
// would poke out of the leaves is cut); `cut` is the part that's left, for branch starts.
function trimLimbs(mask) {
  CROWN_MASK = mask;
  for (const limb of Object.values(LIMBS)) {
    const curve = catmull(limb.pts, 16);
    let last = curve.length - 1;
    // Inside the crown the limb winds: S-bends that start from nothing where it enters the leaves.
    let entry = 0; while (entry < curve.length - 1 && !inMask(curve[entry][0], curve[entry][1], 20)) entry++;
    const seed = limb.w[0] * 7 + limb.pts.length, base = curve.map(p => p.slice());
    for (let i = entry + 1; i < curve.length; i++) {
      const [x0, y0] = base[i - 1], [x1, y1] = base[Math.min(base.length - 1, i + 1)], d = Math.hypot(x1 - x0, y1 - y0) || 1;
      const u = (i - entry) / 16, ramp = Math.min(1, u / 1.5);
      const off = ramp * (Math.sin(u * 1.9 + seed) * 20 + Math.sin(u * 4.1 + seed * 2) * 6);
      curve[i] = [curve[i][0] - (y1 - y0) / d * off, curve[i][1] + (x1 - x0) / d * off];
    }
    while (last > 0 && !inMask(curve[last][0], curve[last][1], 18)) last--;
    const keep = Math.floor(last / 16);
    limb.pts = [...limb.pts.slice(0, keep + 1), ...(last % 16 ? [curve[last].map(Math.round)] : [])];
    limb.cut = curve.slice(0, last + 1);
  }
}
// The limbs' parts inside the crown, drawn over a canopy stage so they show through the leaves up
// to their tips: they come out of the leaves at the crown's belly, taper as they rise,
// and carry a little moss and a few leaf tufts so they sit in the foliage.
function limbsInCrown(img) {
  for (const [sec, limb] of Object.entries(LIMBS)) {
    const pts = limb.cut, n = pts.length;
    let i0 = 0; while (i0 < n - 1 && !inMask(pts[i0][0], pts[i0][1], 20)) i0++;
    const L = new Img(GW, GH), S = new Img(GW, GH), wAt = i => limb.w[0] * .7 + (limb.w[1] - limb.w[0] * .7) * i / (n - 1);
    thickPath(L, pts.slice(i0), wAt(i0), Math.max(5, limb.w[1]), barkBig(sec.length * 13));
    for (let y = 1; y < GH; y++) for (let x = 0; x < GW; x++)  // moss along the top
      if (L.alpha(x, y) && !L.alpha(x, y - 2) && pnoise(x, y, 9, 44) > .5) L.set(x, y, LEAFG[2 + (x % 3 === 0)]);
    S.stamp(L, HB6[0]);
    const [sx, sy] = pts[i0];
    for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) {
      if (!S.alpha(x, y)) continue;
      img.set(x, y, S.get(x, y)); img.set(x, y, CA(CROWN_P[1], .45));  // in the leaves' shade
    }
    // Leaves close over the join where the limb enters the crown.
    for (let k = 0; k < 4; k++) blob(img, Math.floor(sx / 2) * 2 + (k - 1.5) * 12, Math.floor(sy / 2) * 2 + 4 - (k % 2) * 6, 12, 8, CROWN_P.slice(1, 4), { seed: 50 + k, dither: 0 });
    for (let k = 0; k < 22; k++) {  // leaf tufts over the limb
      const [x, y] = pts[Math.floor(i0 + (n - 1 - i0) * (.12 + hash(k, 1, 45) * .8))];
      const cx = Math.floor(x / CROWN_PX) * CROWN_PX, cy = Math.floor(y / CROWN_PX) * CROWN_PX;
      blob(img, cx + (hash(k, 2, 45) - .5) * 10, cy + (hash(k, 3, 45) - .5) * 6, 9 + hash(k, 4, 45) * 8, 6 + hash(k, 5, 45) * 5, CROWN_P.slice(2, 6), { seed: k, dither: 0 });
    }
  }
}
const TWIG_MAX_X = 556;  // the Keepsakes twig stays on the Perks side of the trunk
function spreadNodes(mask) {
  CROWN_MASK = mask;
  const list = NODES;
  // A line's first node grows from the nearest point on its own limb (inside the leaves), so its
  // branch is short; every other node grows from its parent.
  const limbPts = {};
  for (const [sec, limb] of Object.entries(LIMBS)) { const all = limb.cut || catmull(limb.pts, 16), inside = all.filter(([x, y]) => inMask(x, y, 8)); limbPts[sec] = inside.length ? inside : all; }
  const nearestLimb = n => limbPts[n.section].reduce((b, p) => (p[0] - n.x) ** 2 + (p[1] - n.y) ** 2 < (b[0] - n.x) ** 2 + (b[1] - n.y) ** 2 ? p : b);
  const anchor = n => n.parent ? byId[n.parent] : (([x, y]) => ({ x, y }))(nearestLimb(n));
  for (const n of list) for (let k = 0; k < 250 && !inMask(n.x, n.y, 24); k++) {
    const dx = 640 - n.x, dy = 300 - n.y, d = Math.hypot(dx, dy) || 1;
    n.x = Math.round(n.x + dx / d * 4); n.y = Math.round(n.y + dy / d * 4);
  }
  let area = 0; for (let y = 0; y < GH; y += 4) for (let x = 0; x < GW; x += 4) if (inMask(x, y, 26)) area += 16;
  const R = Math.sqrt(area / list.length) * 1.08;
  // Even coverage (Lloyd relaxation): each node moves toward the middle of the leaf area nearest to
  // it, but never far from what it grows from.
  const samples = []; for (let y = 0; y < GH; y += 8) for (let x = 0; x < GW; x += 8) if (inMask(x, y, 26)) samples.push([x, y]);
  for (let it = 0; it < 60; it++) {
    const sx = new Float64Array(list.length), sy = new Float64Array(list.length), sc = new Float64Array(list.length);
    for (const [x, y] of samples) {
      let best = 0, bd = 1e12;
      // The right of the crown belongs to the Cards: its samples go to the nearest Cards node, so they spread up into it.
      const pool = x > 800 ? list.map((n, i) => n.section === "cards" ? i : -1).filter(i => i >= 0) : list.map((n, i) => i);
      for (const i of pool) { const d = (list[i].x - x) ** 2 + (list[i].y - y) ** 2; if (d < bd) { bd = d; best = i; } }
      sx[best] += x; sy[best] += y; sc[best]++;
    }
    list.forEach((n, i) => {
      if (!sc[i]) return;
      let mx = (sx[i] / sc[i] - n.x) * .6, my = (sy[i] / sc[i] - n.y) * .6;
      const p = anchor(n); if (Math.hypot(p.x - n.x - mx, p.y - n.y - my) > R * (n.twig ? .9 : n.parent ? (n.section === "cards" ? 2.4 : 1.6) : (n.section === "cards" ? 1.1 : .75))) { mx *= .2; my *= .2; }
      if (n.twig && n.x + mx > TWIG_MAX_X) mx = Math.min(mx, 0);
      mx = clamp(mx, -8, 8); my = clamp(my, -8, 8);
      if (inMask(n.x + mx, n.y + my, 26)) { n.x += mx; n.y += my; }
    });
  }
  // A last nudge: close neighbours push apart, far-flung children pull back toward their parent.
  for (let it = 0; it < 40; it++) {
    const mv = list.map(() => [0, 0]);
    for (let i = 0; i < list.length; i++) for (let j = i + 1; j < list.length; j++) {
      const a = list[i], b = list[j], dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy) || .01, f = (R * .7 - d) / R * 2.4;
      if (f <= 0) continue;
      mv[i][0] -= dx / d * f; mv[i][1] -= dy / d * f; mv[j][0] += dx / d * f; mv[j][1] += dy / d * f;
    }
    list.forEach((n, i) => {
      const p = anchor(n), dx = p.x - n.x, dy = p.y - n.y, d = Math.hypot(dx, dy);
      const lim = R * (n.twig ? .8 : n.parent ? 1.3 : .6);  // a line's first node stays close to its limb
      if (d > lim) { mv[i][0] += dx / d * (d - lim) * .25; mv[i][1] += dy / d * (d - lim) * .25; }
    });
    list.forEach((n, i) => {
      const mx = clamp(mv[i][0], -4, n.twig && n.x > TWIG_MAX_X - 4 ? 0 : 4), my = clamp(mv[i][1], -4, 4);
      if (inMask(n.x + mx, n.y + my, 26)) { n.x += mx; n.y += my; } else if (inMask(n.x + mx, n.y, 26)) n.x += mx; else if (inMask(n.x, n.y + my, 26)) n.y += my;
    });
  }
  list.forEach(n => { n.x = Math.round(n.x); n.y = Math.round(n.y); });
  // Untangle: two nodes of the same limb swap places whenever that means fewer crossing branches
  // (then shorter ones), so no branch reaches over its neighbours to get to its node. A swap only
  // re-scores the branches it touches (the two nodes' own and their children's).
  const cross = (a, b, c, d) => {
    if ([c, d].some(p => Math.hypot(p.x - a.x, p.y - a.y) < 2 || Math.hypot(p.x - b.x, p.y - b.y) < 2)) return false;
    const o = (p, q, r) => Math.sign((q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x));
    return o(a, b, c) * o(a, b, d) < 0 && o(c, d, a) * o(c, d, b) < 0;
  };
  const idx = new Map(list.map((n, i) => [n, i])), kids = list.map(() => []);
  list.forEach((n, i) => { if (n.parent) kids[idx.get(byId[n.parent])].push(i); });
  const seg = list.map(n => [anchor(n), n]);
  const refresh = i => { seg[i] = [anchor(list[i]), list[i]]; };
  // The score of one branch: its length, its crossings, whether it grows outward, and (for a line's
  // first branch) whether it leaves the limb right next to another line.
  const limbSegs = [];
  for (const pts of Object.values(limbPts)) for (let k = 8; k < pts.length; k += 8) limbSegs.push([{ x: pts[k - 8][0], y: pts[k - 8][1] }, { x: pts[k][0], y: pts[k][1] }]);
  const branchCost = i => {
    const [a, n] = seg[i];
    let c = Math.hypot(a.x - n.x, a.y - n.y);
    for (let j = 0; j < seg.length; j++) if (j !== i && cross(a, n, seg[j][0], seg[j][1])) c += 1000;
    for (const [p, q] of limbSegs) if (cross(a, n, p, q)) c += 800;  // reaching across a great limb
    if (!n.parent) c += Math.max(0, Math.hypot(a.x - n.x, a.y - n.y) - R * .7) * 6;  // first branches stay short
    if (n.parent) {
      const p = byId[n.parent], q = seg[idx.get(p)][0];
      if ((p.x - q.x) * (n.x - p.x) + (p.y - q.y) * (n.y - p.y) < 0) c += 600;
      if (Math.hypot(n.x - 640, n.y - 640) < Math.hypot(p.x - 640, p.y - 640) - 10) c += 400;
    } else for (let j = 0; j < seg.length; j++)
      if (j !== i && !list[j].parent && list[j].section === n.section && Math.hypot(seg[j][0].x - a.x, seg[j][0].y - a.y) < 36) c += 250;
    return c;
  };
  for (let pass = 0; pass < 8; pass++) {
    let improved = false;
    for (let i = 0; i < list.length; i++) for (let j = i + 1; j < list.length; j++) {
      const a = list[i], b = list[j];
      if (a.section !== b.section || !!a.twig !== !!b.twig) continue;
      const touched = [...new Set([i, j, ...kids[i], ...kids[j]])], score = () => touched.reduce((s, k) => s + branchCost(k), 0);
      const before = score();
      [a.x, b.x] = [b.x, a.x]; [a.y, b.y] = [b.y, a.y]; touched.forEach(refresh);
      if (score() < before - .5) improved = true;
      else { [a.x, b.x] = [b.x, a.x]; [a.y, b.y] = [b.y, a.y]; touched.forEach(refresh); }
    }
    if (!improved) break;
  }
  for (const n of list) if (n.from) n.from = nearestLimb(n).map(Math.round);
}
// The lowest leafy pixel in a column (where dream-fruit hang from).
function maskBottom(x) { let y = 780; while (y > 0 && !CROWN_MASK.alpha(x, y)) y--; return y; }

// ---- branch segments: [bare twig, growing 25/50/75%, grown] ----
// Every branch is its own jagged zig-zag of 1-5 straight pieces with sharp joints, with its own
// wander, thickness and 0-3 side twigs; about half also carry node-less "false" branches that grow
// with them and stay inside the leaves.
function bez(a, c, b, t) { const u = 1 - t; return [u * u * a[0] + 2 * u * t * c[0] + t * t * b[0], u * u * a[1] + 2 * u * t * c[1] + t * t * b[1]]; }
function geomAB(a, b, depth) {
  const mx = (a[0] + b[0]) / 2, my = (a[1] + b[1]) / 2, dx = b[0] - a[0], dy = b[1] - a[1], len = Math.hypot(dx, dy);
  let px = -dy / len, py = dx / len; if (py > 0) { px = -px; py = -py; }
  const bend = len * (hash(b[0], b[1], 70) - .4) * .4;
  // A line's first branch (off a limb) is clearly the thickest; deeper ones get thinner, each a little different.
  const h = hash(b[0], b[1], 72), w0 = depth === 1 ? 11 + h * 2 : [0, 0, 6, 5, 4.2][Math.min(4, depth)] * (.75 + h * .4);
  return { a, b, c: [mx + px * bend, my + py * bend], len, w0, w1: depth === 1 ? w0 * .55 : Math.max(2.5, w0 * .62) };
}
function segGeom(n) { return geomAB(n.parent ? [byId[n.parent].x, byId[n.parent].y] : n.from, [n.x, n.y], n.depth); }
const JCACHE = new Map();
function joints(g) {
  const key = g.a.join() + "|" + g.b.join();
  if (JCACHE.has(key)) return JCACHE.get(key);
  const sd = hash(Math.round(g.b[0]), Math.round(g.b[1]), 77) * 1e4 | 0, H = i => hash(sd, i, 79);
  const n = 1 + Math.floor(H(0) * 4.5), mag = .04 + H(1) * .12, zig = H(2) < .45;
  const dx = g.b[0] - g.a[0], dy = g.b[1] - g.a[1], d = Math.hypot(dx, dy) || 1, px = -dy / d, py = dx / d;
  const pts = [g.a];
  for (let i = 1; i <= n; i++) {
    const t = clamp(i / (n + 1) + (H(10 + i) - .5) * .6 / (n + 1), .08, .92), base = bez(g.a, g.c, g.b, t);
    const sign = zig ? (i % 2 ? 1 : -1) * (H(3) < .5 ? 1 : -1) : (H(20 + i) < .5 ? 1 : -1);
    const off = sign * (.4 + H(30 + i) * .6) * g.len * mag;
    pts.push([Math.round(base[0] + px * off), Math.round(base[1] + py * off)]);
  }
  pts.push(g.b);
  const cum = [0]; for (let i = 1; i < pts.length; i++) cum.push(cum[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  const J = { pts, cum, total: cum[cum.length - 1], sd, twigs: Math.floor(H(4) * 3.6) };
  JCACHE.set(key, J); return J;
}
// A point along the branch's zig-zag (t = 0 at its start, 1 at its node).
function along(g, t) {
  const J = joints(g), L = clamp(t, 0, 1) * J.total;
  let i = 1; while (i < J.pts.length - 1 && J.cum[i] < L) i++;
  const f = (L - J.cum[i - 1]) / ((J.cum[i] - J.cum[i - 1]) || 1), p = J.pts[i - 1], q = J.pts[i];
  return [p[0] + (q[0] - p[0]) * f, p[1] + (q[1] - p[1]) * f];
}
// Node-less branches off this one: tip and middle inside the leaves, clear of every node.
function falseBranches(n, g) {
  const out = [], hs = i => hash(n.x, n.y, 990 + i), count = hs(1) < .55 ? 1 : hs(2) < .35 ? 2 : 0;
  for (let k = 0; k < count; k++) {
    const t = .2 + hs(10 + k) * .55, [x, y] = along(g, t), [x2, y2] = along(g, Math.min(1, t + .02));
    const ang = Math.atan2(y2 - y, x2 - x) + (hs(20 + k) < .5 ? -1 : 1) * (.55 + hs(30 + k) * .7);
    let len = 22 + hs(40 + k) * 34, ex, ey, ok = false;
    for (let tries = 0; tries < 4 && !ok; tries++, len *= .72) {
      ex = Math.round(x + Math.cos(ang) * len); ey = Math.round(y + Math.sin(ang) * len - len * .15);
      ok = inMask(ex, ey, 12) && inMask((x + ex) / 2, (y + ey) / 2, 6);
    }
    if (!ok || !inMask(x, y, 4) || NODES.some(m => Math.hypot(m.x - ex, m.y - ey) < 26)) continue;
    out.push({ t, g: geomAB([Math.round(x), Math.round(y)], [ex, ey], Math.min(4, n.depth + 1) + 1) });
  }
  return out;
}
function segBox(gs) {
  let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
  for (const g of gs) {
    const m = Math.ceil(g.w0) + 30;
    for (let t = 0; t <= 1; t += .02) { const [x, y] = along(g, t); x0 = Math.min(x0, x - m); y0 = Math.min(y0, y - m); x1 = Math.max(x1, x + m); y1 = Math.max(y1, y + m); }
  }
  return [Math.floor(x0), Math.floor(y0), Math.ceil(x1), Math.ceil(y1)];
}
function drawTwig(L, g, ox, oy, seed) {
  const steps = Math.ceil(g.len * 2);
  for (let i = 0; i <= steps; i++) { const [x, y] = along(g, i / steps); L.set(x - ox, y - oy, "#3a2616"); L.set(x - ox, y - oy + 1, "#24160c"); if (g.w0 >= 9) { L.set(x - ox, y - oy - 1, "#4a3220"); L.set(x - ox, y - oy + 2, "#24160c"); } }  // a first branch is a thicker twig
  for (const t of [.35, .7]) {
    const [x, y] = along(g, t), s = hash(Math.floor(t * 10), 1, seed) < .5 ? -1 : 1;
    for (let i = 1; i < 5; i++) L.set(x - ox + s * i, y - oy - i, "#3a2616");
  }
}
function drawLiving(L, g, ox, oy, upto, seed) {
  const steps = Math.ceil(g.len * 2 * upto), fn = barkBig(seed);
  let last = g.a;
  for (let i = 1; i <= steps; i++) {
    const t = i / Math.ceil(g.len * 2), [x, y] = along(g, t), w = g.w0 + (g.w1 - g.w0) * t;
    stroke(L, last[0] - ox, last[1] - oy, x - ox, y - oy, w, w, fn); last = [x, y];
  }
  return last;
}
// Short side twigs off the grown part, each tipped with a leaf pair.
function sideTwigs(L, g, ox, oy, upto, seed) {
  const J = joints(g), fn = barkBig(seed);
  for (let k = 0; k < J.twigs; k++) {
    const t = .25 + hash(J.sd, 40 + k, 80) * .55; if (t > upto) continue;
    const [x, y] = along(g, t), [x2, y2] = along(g, Math.min(1, t + .02));
    const ang = Math.atan2(y2 - y, x2 - x) + (hash(J.sd, 50 + k, 80) < .5 ? -1 : 1) * (.6 + hash(J.sd, 60 + k, 80) * .6);
    const len = 7 + hash(J.sd, 70 + k, 80) * 11, ex = x + Math.cos(ang) * len, ey = y + Math.sin(ang) * len - len * .25;
    stroke(L, x - ox, y - oy, ex - ox, ey - oy, Math.max(2, g.w0 * .5), 1.4, fn);
    L.set(ex - ox, ey - oy - 1, LEAFG[3]); L.set(ex - ox + 1, ey - oy - 1, LEAFG[4]); L.set(ex - ox - 1, ey - oy, LEAFG[2]);
  }
}
// The living wood of one branch up to `upto`: bark, side twigs, and moss with leaf pairs along it.
function growWood(L, g, box, upto, seed) {
  const tip = drawLiving(L, g, box[0], box[1], upto, seed);
  sideTwigs(L, g, box[0], box[1], upto, seed);
  for (let k = 1; k < 12; k++) {
    const t = k / 12; if (t > upto) break;
    const [x, y] = along(g, t), s = k % 2 ? -1 : 1, lx = x - box[0], ly = y - box[1] - g.w0 * .4;
    L.set(lx + s * 2, ly - 2, LEAFG[3]); L.set(lx + s * 3, ly - 2, LEAFG[3]); L.set(lx + s * 3, ly - 3, LEAFG[4]); L.set(lx + s * 2, ly - 1, LEAFG[2]);
  }
  return tip;
}
function segment(n) {
  const g = segGeom(n), fbs = falseBranches(n, g), box = segBox([g, ...fbs.map(f => f.g)]), W = box[2] - box[0], H = box[3] - box[1];
  const seed = hash(n.x, n.y, 71) * 1000 | 0, frames = [];
  const fbGrowth = (f, upto) => clamp((upto - f.t) / (1 - f.t) * 1.6, 0, 1);  // starts once the branch reaches it
  for (const upto of [0, .25, .5, .75, 1]) {
    const out = new Img(W, H), T = new Img(W, H), L = new Img(W, H);
    drawTwig(T, g, box[0], box[1], seed);
    fbs.forEach(f => {
      drawTwig(T, f.g, box[0], box[1], seed + 5);
      const [ex, ey] = f.g.b; [[1, -1], [2, -2], [-1, -1]].forEach(([dx, dy]) => T.set(ex - box[0] + dx, ey - box[1] + dy, "#3a2616"));  // bare split tip
    });
    out.put(T);
    if (upto > 0) {
      // False branches first, so the real branch lies over them.
      const growing = fbs.filter(f => fbGrowth(f, upto) > 0);
      growing.forEach(f => growWood(L, f.g, box, fbGrowth(f, upto), seed + 5));
      const tip = growWood(L, g, box, upto, seed);
      out.stamp(L, HB6[0]);
      growing.forEach(f => {
        if (fbGrowth(f, upto) < 1) return;
        const [ex, ey] = f.g.b;  // a leaf tuft on the false branch's tip
        [[0, -1, 3], [1, -2, 4], [-1, -2, 3], [2, -1, 2], [-2, 0, 2], [0, -3, 4], [1, 0, 2]].forEach(([dx, dy, c]) => out.set(ex - box[0] + dx, ey - box[1] + dy, LEAFG[c]));
      });
      if (upto < 1) { out.set(tip[0] - box[0], tip[1] - box[1], LEAFG[4]); out.set(tip[0] - box[0] + 1, tip[1] - box[1] - 1, "#d8f0a0"); }
    }
    frames[frames.length] = integrateBranch(out, g, box, seed);
  }
  return { frames, box, W, H };
}
// Tucks a branch frame into the crown: its wood takes the shaded tones, a few leaf clusters (the same
// in every frame) cover parts of it so it dips behind the foliage, and the whole frame snaps to the
// crown's 2 px art-pixel grid (aligned to tree space), so it reads as part of the same picture.
function integrateBranch(img, g, box, seed) {
  const shade = new Map([[HW.Loam, HW.Bark], [HW.Oak, HW.Bark], [HW.Bark, HW.Root]].map(([a, b]) => [C(a).slice(0, 3).join(), b]));
  for (let y = 0; y < img.h; y++) for (let x = 0; x < img.w; x++) {
    if (!img.alpha(x, y)) continue;
    const was = img.get(x, y).slice(0, 3).join(), to = shade.get(was);
    // One pass (Loam -> Bark must not then become Root): only the lit edge keeps Bark.
    if (to) img.set(x, y, was === C(HW.Loam).slice(0, 3).join() || was === C(HW.Oak).slice(0, 3).join() ? (img.alpha(x - 1, y - 1) ? HW.Root : HW.Bark) : to);
  }
  const n = clamp(Math.round(g.len / 55), 1, 3);
  for (let k = 0; k < n; k++) {
    const t = .22 + (k + hash(seed, k, 150)) / n * .55, [cx, cy] = along(g, t);
    // An irregular clump: 2-3 overlapping lobes, lower ones first, each lit on its upper left.
    const lobes = [...Array(2 + (hash(seed, k, 152) < .5 ? 1 : 0)).keys()].map(i => [cx + (hash(seed, k * 7 + i, 153) - .5) * 12, cy + (hash(seed, k * 7 + i, 154) - .5) * 7, 3 + hash(seed, k * 7 + i, 155) * 3.5]).sort((p, q) => q[1] - p[1]);
    for (const [lx, ly, r] of lobes) for (let y = Math.floor(ly - r); y <= ly + r; y++) for (let x = Math.floor(lx - r); x <= lx + r; x++) {
      const dx = (x - lx) / r, dy = (y - ly) / r, q = Math.hypot(dx, dy) / (1 + .18 * Math.sin(Math.atan2(dy, dx) * 4 + k));
      if (q > 1) continue;
      const lit = -dx * .5 - dy * .8 + (1 - q) * .4;
      img.set(x - box[0], y - box[1], lit > .55 ? HW.Moss : lit > .1 ? HW.Pool : HW.Deepmoss);
    }
  }
  const out = new Img(img.w, img.h), ox = ((box[0] % 2) + 2) % 2, oy = ((box[1] % 2) + 2) % 2;
  for (let by = -oy; by < img.h; by += 2) for (let bx = -ox; bx < img.w; bx += 2) {
    const count = new Map();
    for (const [a, b] of [[0, 0], [1, 0], [0, 1], [1, 1]]) {
      const x = bx + a, y = by + b; if (x < 0 || y < 0 || x >= img.w || y >= img.h || !img.alpha(x, y)) continue;
      const key = img.get(x, y).join(); count.set(key, (count.get(key) || 0) + 1);
    }
    if (!count.size) continue;
    const c = [...count].sort((p, q) => q[1] - p[1])[0][0].split(",").map(Number);
    for (const [a, b] of [[0, 0], [1, 0], [0, 1], [1, 1]]) out.set(bx + a, by + b, c);
  }
  return out;
}

// ---- drifting mist strips (grove_layout.json "mists"; GroveTreeView tiles and scrolls them) ----
// Seamless horizontally over the 1280 px width (the noise wraps), soft top and bottom. Muted violet
// dream mist: Dusk, Shade in the thicker parts, Bruise only in the densest cores near the ground.
const GROVE_MISTS = [
  { file: "grove_mist_0.png", y: 610, h: 110, dens: .28, speed: 4, seed: 141 },
  { file: "grove_mist_1.png", y: 715, h: 110, dens: .42, speed: -6, seed: 142 },
  { file: "grove_mist_2.png", y: 820, h: 120, dens: .7, speed: 8, seed: 143 },
];
function groveMistStrip(m) {
  // Drawn in 2 px art pixels (like the crown), so it moves and scales without shimmering.
  const out = new Img(GW, m.h), deep = m.dens > .8;
  for (let y = 0; y < m.h; y += 2) for (let x = 0; x < GW; x += 2) {
    const wob = (pnoise(x, 0, 80, m.seed + 2, 16) - .5) * m.h * .5;
    const band = clamp(1 - Math.abs(y - m.h / 2 - wob) / (m.h * .42), 0, 1) ** 1.5;
    const n = pnoise(x, y, 40, m.seed, 32) * .75 + pnoise(x, y, 16, m.seed + 1, 80) * .25;
    const d = band * clamp((n - .36) * 2.6, 0, 1);
    if (d > 0 && bay(x >> 1, y >> 1) < d * m.dens) { const c = d > .75 ? (deep ? HW.Bruise : HW.Shade) : d > .45 ? HW.Shade : HW.Dusk; out.set(x, y, c); out.set(x + 1, y, c); out.set(x, y + 1, c); out.set(x + 1, y + 1, c); }
  }
  return out;
}
// The centre of the Hollow's light (GroveTreeView pulses a warm glow here).
const HOLLOW_LIGHT = [608, 792];

// ---- loadout waystones (drawn by the game, only for unlocked slots) ----
// One stone, 48x40, its centre at WAYSTONE_ANCHOR. Positions for 3, 4 and 5 stones, centred on the
// trunk along the roots' arc (slot order left to right); the secret sixth keeps SECRET_STONE.
const WAYSTONE_ANCHOR = [24, 18];
function waystoneSprite() {
  const out = new Img(48, 40), S = new Img(48, 40), [x, y] = WAYSTONE_ANCHOR;
  ellipse(out, x, y + 13, 20, 5, SHADOW(.4));
  blob(S, x, y, 16, 13, [ST.d1, ST.m, ST.l1, ST.l2, ST.hi], { tex: .1, rim: true, seed: 0 });
  blob(S, x - 6, y - 9, 7, 3, [LEAFG[1], LEAFG[2], LEAFG[3]], { tex: .2 });
  out.stamp(S, ST.out);
  for (let a = 0; a < Math.PI * 2; a += .3) out.set(x + Math.cos(a) * 6, y + 2 + Math.sin(a) * 4.5, "#8ad8c8");
  out.set(x, y + 2, "#c8fff0");
  return out;
}
const stoneArc = n => [...Array(n).keys()].map(i => { const x = 640 + (i - (n - 1) / 2) * 81; return [Math.round(x), Math.round(934 - ((x - 640) / 162) ** 2 * 28)]; });
const LOADOUT_STONE_SETS = { 3: stoneArc(3), 4: stoneArc(4), 5: stoneArc(5) };
