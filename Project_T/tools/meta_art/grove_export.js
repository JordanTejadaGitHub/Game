
// The icon sheets' orders (used by the per-node blooms before the icon sheets are written).
const PERK_ORDER = ["morning_stores", "rich_dew", "rested_roots", "seed_pouch", "clear_sight", "sprout_bed", "kindling", "early_bloom", "early_light", "first_care", "deep_taproot", "second_thoughts", "let_go", "omen_reader", "wider_dreams", "wider_roots", "golden_leaf", "blossoms", "gilded_pages", "starlit_backs", "heartwoods_crown", "restless_omens", "remembered_seed", "chosen_hunt", "leaf_or_dew", "kin_foretold"];
const FAMILY_ORDER = ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"];
const CARD_ORDER = ["storm", "spores_and_reactions", "keen_edges", "tending", "overgrowth", "lone_lantern", "the_long_way", "bittersweet", "woven", "deep_poison", "kinship", "seeds", "quiet_ones", "swift", "wide_reach", "daring", "hedgerows", "reclaiming", "strange_dreams", "restless_omens"];  // Storm, Spores and Kinship icons stay for stable indices (their nodes are gone)

// ---------- export (assets/meta/...) ----------
function strip(imgs) { const w = imgs.reduce((s, i) => s + i.w, 0), h = Math.max(...imgs.map(i => i.h)), S = new Img(w, h); let x = 0; for (const i of imgs) { S.put(i, x, 0); x += i.w; } return S; }
function stack(rows) { const w = Math.max(...rows.map(r => r.w)), h = rows.reduce((s, r) => s + r.h, 0), S = new Img(w, h); let y = 0; for (const r of rows) { S.put(r, 0, y); y += r.h; } return S; }
// Every sheet is snapped to Heartwood 32 on the way out: each pixel takes the nearest palette colour
// by OKLab distance and keeps its alpha (glows stay palette colours at partial alpha).
const OKLAB = (r, g, b) => {
  const lin = c => (c /= 255) <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4, R = lin(r), G = lin(g), B = lin(b);
  const l = Math.cbrt(.4122214708 * R + .5363325363 * G + .0514459929 * B), m = Math.cbrt(.2119034982 * R + .6806995451 * G + .1073969566 * B), s = Math.cbrt(.0883024619 * R + .2817188376 * G + .6299787005 * B);
  return [.2104542553 * l + .793617785 * m - .0040720468 * s, 1.9779984951 * l - 2.428592205 * m + .4505937099 * s, .0259040371 * l + .7827717662 * m - .808675766 * s];
};
const HW_RGB = HW32.ramps.flatMap(r => r.colors.map(c => [1, 3, 5].map(i => parseInt(c.hex.slice(i, i + 2), 16)))), HW_LAB = HW_RGB.map(c => OKLAB(...c)), SNAP = new Map();
function snapToPalette(img) {
  const d = img.d;
  for (let i = 0; i < d.length; i += 4) {
    if (!d[i + 3]) continue;
    const key = d[i] << 16 | d[i + 1] << 8 | d[i + 2];
    let k = SNAP.get(key);
    if (k === undefined) {
      const q = OKLAB(d[i], d[i + 1], d[i + 2]); let bd = 1e9; k = 0;
      HW_LAB.forEach((p, j) => { const e = (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2; if (e < bd) { bd = e; k = j; } });
      SNAP.set(key, k);
    }
    [d[i], d[i + 1], d[i + 2]] = HW_RGB[k];
  }
  return img;
}
// PNGs are written here, not by canvas.toDataURL: a canvas stores colour premultiplied by alpha, which
// shifts the colour of faint glow pixels off the palette. This keeps RGBA exact (zlib via the browser).
const CRC = new Uint32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
function pngChunk(type, data) {
  const out = new Uint8Array(12 + data.length), dv = new DataView(out.buffer);
  dv.setUint32(0, data.length); for (let i = 0; i < 4; i++) out[4 + i] = type.charCodeAt(i); out.set(data, 8);
  let c = 0xffffffff; for (let i = 4; i < 8 + data.length; i++) c = CRC[(c ^ out[i]) & 255] ^ (c >>> 8);
  dv.setUint32(8 + data.length, (c ^ 0xffffffff) >>> 0); return out;
}
async function encodePng(img) {
  const raw = new Uint8Array((img.w * 4 + 1) * img.h);
  for (let y = 0; y < img.h; y++) raw.set(img.d.subarray(y * img.w * 4, (y + 1) * img.w * 4), y * (img.w * 4 + 1) + 1);
  const z = new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new CompressionStream("deflate"))).arrayBuffer());
  const ihdr = new Uint8Array(13), dv = new DataView(ihdr.buffer); dv.setUint32(0, img.w); dv.setUint32(4, img.h); ihdr.set([8, 6, 0, 0, 0], 8);
  const parts = [new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]), pngChunk("IHDR", ihdr), pngChunk("IDAT", z), pngChunk("IEND", new Uint8Array(0))];
  let s = ""; for (const p of parts) for (let i = 0; i < p.length; i += 32768) s += String.fromCharCode(...p.subarray(i, i + 32768));
  return btoa(s);
}
const PENDING = [];
function emitImg(name, img) {  // previews are composites of snapped sheets, so they are not snapped again
  if (!name.startsWith("_preview/")) snapToPalette(img);
  const p = document.createElement("pre"); p.dataset.name = name; document.body.appendChild(p);
  PENDING.push(encodePng(img).then(b64 => { p.textContent = b64; }));
}
function emitText(name, text) { const p = document.createElement("pre"); p.dataset.name = name; p.textContent = btoa(unescape(encodeURIComponent(text))); document.body.appendChild(p); }
const nodeRow = (sec, big) => strip([nodeSprite(sec, "locked", 0, big), ...[0, 1, 2, 3].map(f => nodeSprite(sec, "afford", f, big)), ...[0, 1, 2, 3].map(f => nodeSprite(sec, "open", f, big)), nodeSprite(sec, "bloom", 0, big), nodeSprite(sec, "bloom", 1, big)]);

// The smallest crown (stage 0, shown from the first visit) decides where everything sits, so no
// branch pokes out of the leaves at any stage: the great limbs end inside it, the nodes are spread
// evenly over it, and the dream-fruit hang just under its belly. The tree and branches come after.
const canopies = [0, 1, 2, 3].map(groveCanopy);
trimLimbs(canopies[0]);
canopies.forEach(limbsInCrown);  // the limbs show through every stage's leaves
canopies.forEach((c, i) => emitImg("grove/grove_canopy_" + i + ".png", c));
const tree = groveTree(), sky = grovesky();
emitImg("grove/grove_sky.png", sky);
emitImg("grove/grove_backdrop.png", grovesky(640));  // 2560 wide: the sky continued 640 px past each side, for wide screens
emitImg("grove/grove_tree.png", tree);
emitImg("grove/waystone.png", waystoneSprite());
spreadNodes(canopies[0]);
FRUIT_SPOTS.forEach(s => { s[1] = maskBottom(s[0]) - 8; });
const layout = { size: [GW, GH], nodes: [], fruit_spots: FRUIT_SPOTS, loadout_stones: [...LOADOUT_STONES, SECRET_STONE], loadout_stone_sets: LOADOUT_STONE_SETS, waystone_anchor: WAYSTONE_ANCHOR, moon: MOON, hollow: HOLLOW_LIGHT, mists: GROVE_MISTS.map(({ file, y, speed }) => ({ file, y, speed })), node_cell: 32, legendary_cell: 48, fruit_cell: 48 };
const segs = {};
for (const n of NODES) {
  const s = segment(n); segs[n.id] = s;
  emitImg("grove/branches/" + n.id + ".png", strip(s.frames));
  layout.nodes.push({ id: n.id, section: n.section, name: n.name, pos: [n.x, n.y], parent: n.parent || null, from: n.from || null,
    levels: n.lv || 1, start: !!n.start, legendary: !!n.legendary, ...(MEMORY_WARDENS.includes(n.id) ? { memory_row: MEMORY_WARDENS.indexOf(n.id) } : {}), branch: { offset: [s.box[0], s.box[1]], frame_size: [s.W, s.H], frames: 5 } });
}
// Ascension blooms (fully grown): grove_ascended_blooms.png, a row per Ascension node; other grown nodes use the uniform flowers.
const bloomNodes = NODES.filter(n => NODE_ICON[n.id] && !n.id.endsWith("_ascension") && !n.id.startsWith("memory_"));
const ascNodes = NODES.filter(n => n.id.endsWith("_ascension") && ASCENDED_ART[n.id.replace(/_ascension$/, "")]);
layout.nodes.forEach(e => {
  const b = bloomNodes.findIndex(n => n.id === e.id), a = ascNodes.findIndex(n => n.id === e.id);
  if (a >= 0) e.ascended_bloom = a;
  // How deep a node sits on its branch (meta_design.md c2d98792, visual only): which grove_level_blooms
  // column set a grown Families / Cards node shows. Perks keep their real purchase levels (no field).
  // Families: family 1, hidden branch 2, Ascension 3. Cards: a branch's first bundle 1, later bundles 2,
  // Legendary tips 3. Legendary tips and Ascensions keep their own bigger blooms as their level 3.
  if (e.section === "families" && !e.id.startsWith("memory_")) e.display_level = e.id.endsWith("_ascension") ? 3 : e.id.endsWith("_hidden") ? 2 : 1;
  if (e.section === "cards") e.display_level = e.legendary ? 3 : e.parent && byId[e.parent] && byId[e.parent].section === "cards" ? 2 : 1;
});
layout.ascended_cell = 48;
emitImg("grove/grove_ascended_blooms.png", stack(ascNodes.map(() => strip([0, 1, 2, 3].map(ascendedBloomPlain)))));
GROVE_MISTS.forEach(m => emitImg("grove/" + m.file, groveMistStrip(m)));
emitText("grove/grove_layout.json", JSON.stringify(layout, null, 1));
emitImg("grove/grove_nodes.png", stack(["perks", "families", "cards"].map(s => nodeRow(s, false))));
emitImg("grove/grove_level_blooms.png", stack(["perks", "families", "cards"].map(s => strip([1, 2, 3].flatMap(lv => [0, 1].map(f => levelBloom(s, lv, f)))))));
emitImg("grove/grove_legendary.png", nodeRow("cards", true));
emitImg("grove/dream_fruit.png", strip([0, 1, 2, 3, 4, 5, 6, 7, 8].map(fruitSprite)));
emitImg("ui/loadout_slots.png", strip([0, 1, 2, 3].map(slotSprite)));
// The secret sixth waystone: its rise (24 frames), its idle loop (4), and its loadout slot (3 states).
const riseFrames = [...Array(SIXTH_RISE_FRAMES).keys()].map(sixthRiseFrame);
emitImg("grove/waystone_6_rise.png", strip(riseFrames));
emitImg("grove/waystone_6_idle.png", strip([...Array(SIXTH_IDLE_FRAMES).keys()].map(sixthIdleFrame)));
emitImg("ui/loadout_slot_6.png", strip([0, 1, 2].map(sixthSlot)));
// Preview: the rise on the tree (every 3rd frame, then the idle), cropped around the Hollow.
{
  const frames = [0, 3, 6, 9, 12, 15, 18, 23].map(i => riseFrames[i]), cw = 200, ch = 150, P = new Img(cw * 4, ch * 2);
  frames.forEach((fr, k) => {
    const T = new Img(GW, GH); T.put(sky); T.put(tree); T.put(fr, SECRET_STONE[0] - SIXTH_ANCHOR[0], SECRET_STONE[1] - SIXTH_ANCHOR[1]);
    const ox = SECRET_STONE[0] - cw / 2, oy = SECRET_STONE[1] - ch + 40;
    for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) if (T.alpha(ox + x, oy + y)) P.set((k % 4) * cw + x, (k / 4 | 0) * ch + y, T.get(ox + x, oy + y));
  });
  emitImg("_preview/waystone_6_preview.png", P);
}
// Memory Wardens: their bloom sheet (a row each, the 11 node columns) and the family-pick card border.
emitImg("grove/grove_memory_nodes.png", stack(MEMORY_WARDENS.map(memoryNodeRow)));
const memoryBorders = [...Array(MEMORY_CARD_FRAMES).keys()].map(memoryCardBorder);
emitImg("ui/memory_card_border.png", strip(memoryBorders));
{
  // Preview: the three blooms (bloomed, 4Ã—) and the border over a mock card, standard and tall.
  const P = new Img(640, 400); for (let y = 0; y < P.h; y++) for (let x = 0; x < P.w; x++) P.set(x, y, HW.Void);
  MEMORY_WARDENS.forEach((id, k) => { const s = memoryNodeSprite(id, "bloom", 0); for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) if (s.alpha(x, y)) for (let a = 0; a < 3; a++) for (let b = 0; b < 3; b++) P.set(8 + k * 100 + x * 3 + a, 8 + y * 3 + b, s.get(x, y)); });
  [[330, 0, 300], [20, 100, 290]].slice(0, 1).forEach(() => {});
  const mock = (h) => { const m = new Img(250, h); for (let y = 0; y < h; y++) for (let x = 0; x < 250; x++) m.set(x, y, CA(HW.Night, .9)); for (const [y, w] of [[60, 160], [80, 120], [180, 200], [200, 170]]) for (let x = 24; x < 24 + w; x++) for (let k = 0; k < 6; k++) m.set(x, y + k, HW.Mist); return m; };
  const card = mock(300); P.put(card, 350, 50); P.put(memoryBorders[2], 350 - MEMORY_BLEED, 50 - MEMORY_BLEED);
  emitImg("_preview/memory_wardens_preview.png", P);
  const T = new Img(300, 420); for (let y = 0; y < T.h; y++) for (let x = 0; x < T.w; x++) T.set(x, y, HW.Void);
  T.put(mock(370), 25, 25); T.put(nineTile(memoryBorders[2], 250 + 2 * MEMORY_BLEED, 370 + 2 * MEMORY_BLEED, MEMORY_MARGIN), 25 - MEMORY_BLEED, 25 - MEMORY_BLEED);
  emitImg("_preview/memory_card_tall_preview.png", T);
}
// Starlit card backs: 4 twinkle frames of 250Ã—220 side by side.
const starlit = [0, 1, 2, 3].map(starlitCard);
emitImg("ui/starlit_card.png", strip(starlit));
// Preview: a standard card and a tall one (tiled edges) under a mock of the card's own style
// (light fog, the rarity thread along the top, the gem, text lines).
{
  const P = new Img(560, 340); for (let y = 0; y < P.h; y++) for (let x = 0; x < P.w; x++) P.set(x, y, HW.Void);
  [[20, 20, 220, HW.Wraithlight], [290, 20, 310, LEAFG[3]]].forEach(([ox, oy, h, thread]) => {
    const card = nineTile(starlit[0], STARLIT_W, h, STARLIT_MARGIN);
    for (let y = 0; y < h; y++) for (let x = 0; x < STARLIT_W; x++) {
      card.set(x, y, CA(HW.Void, .2 + .25 * Math.max(0, 1 - Math.hypot((x - 125) / 125, (y - h / 2) / (h / 2)))));
    }
    for (let x = 0; x < STARLIT_W; x++) card.set(x, 0, CA(thread, .3 + .7 * (1 - Math.abs(x - 125) / 125)));
    ellipse(card, 36, 36, 7, 7, thread);
    for (const [y, w] of [[32, 120], [64, 170], [92, 190], [106, 150], [120, 175]]) for (let x = 56; x < 56 + w && x < 224; x++) for (let k = 0; k < 6; k++) card.set(x, y + k, y === 32 ? thread : HW.Mist);
    P.put(card, ox, oy);
  });
  emitImg("_preview/starlit_preview.png", P);
}
emitImg("icons/perk_icons.png", strip(PERK_ORDER.map(k => PERK_ICONS[k]())));
emitImg("ui/keepsake_shelf.png", keepsakeShelf());
emitImg("ui/keepsake_slots.png", strip([true, false].flatMap(e => KEEPSAKE_ORDER.map((k, i) => keepsakeSlot(i, e)))));
emitImg("icons/family_icons.png", strip(FAMILY_ORDER.map(k => FAMILY_ICONS[k]())));
emitImg("icons/card_bundle_icons.png", strip(CARD_ORDER.map(cardIcon)));
for (let i = 0; i < 10; i++) emitImg("memories/memory_" + String(i + 1).padStart(2, "0") + ".png", memory(i));

// Preview: the tree part-grown, with every node state on show.
const prev = new Img(GW, GH); prev.put(sky); prev.put(tree); prev.put(canopies[2]); GROVE_MISTS.forEach(m => prev.put(snapToPalette(groveMistStrip(m)), 0, m.y));
const owned = new Set(); NODES.forEach((n, i) => { if (n.start || (i % 3 !== 2 && n.depth < 3)) owned.add(n.id); });
const sheetCell = (sec, big, col) => nodeSprite(sec, col === 0 ? "locked" : col < 5 ? "afford" : col < 9 ? "open" : "bloom", col === 0 ? 0 : col < 5 ? col - 1 : col < 9 ? col - 5 : col - 9, big);
for (const n of NODES) { const s = segs[n.id]; prev.put(s.frames[owned.has(n.id) ? 4 : 0], s.box[0], s.box[1]); }
for (const n of NODES) {
  const parentOwned = !n.parent || owned.has(n.parent), big = !!n.legendary, S = big ? 48 : 32;
  const col = owned.has(n.id) ? 9 : parentOwned ? 1 : 0;
  prev.put(sheetCell(n.section, big, col), n.x - S / 2, n.y - S / 2);
}
FRUIT_SPOTS.slice(0, 4).forEach(([x, y], i) => prev.put(fruitSprite(i === 3 ? 8 : 0), x - 24, y));
emitImg("_preview/grove_preview.png", prev);
Promise.all(PENDING).then(() => document.body.appendChild(Object.assign(document.createElement("p"), { id: "done", textContent: "done" })));
