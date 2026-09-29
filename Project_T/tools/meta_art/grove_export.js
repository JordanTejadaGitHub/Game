
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
function emitImg(name, img) {
  snapToPalette(img);
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
emitImg("grove/grove_tree.png", tree);
spreadNodes(canopies[0]);
FRUIT_SPOTS.forEach(s => { s[1] = maskBottom(s[0]) - 8; });
const layout = { size: [GW, GH], nodes: [], fruit_spots: FRUIT_SPOTS, loadout_stones: LOADOUT_STONES, moon: MOON, node_cell: 32, legendary_cell: 48, fruit_cell: 48 };
const segs = {};
for (const n of NODES) {
  const s = segment(n); segs[n.id] = s;
  emitImg("grove/branches/" + n.id + ".png", strip(s.frames));
  layout.nodes.push({ id: n.id, section: n.section, name: n.name, pos: [n.x, n.y], parent: n.parent || null, from: n.from || null,
    levels: n.lv || 1, start: !!n.start, legendary: !!n.legendary, branch: { offset: [s.box[0], s.box[1]], frame_size: [s.W, s.H], frames: 5 } });
}
emitText("grove/grove_layout.json", JSON.stringify(layout, null, 1));
emitImg("grove/grove_nodes.png", stack(["perks", "families", "cards"].map(s => nodeRow(s, false))));
emitImg("grove/grove_legendary.png", nodeRow("cards", true));
emitImg("grove/dream_fruit.png", strip([0, 1, 2, 3, 4, 5, 6, 7, 8].map(fruitSprite)));
emitImg("ui/loadout_slots.png", strip([0, 1, 2, 3].map(slotSprite)));
const PERK_ORDER = ["morning_stores", "rich_dew", "rested_roots", "seed_pouch", "clear_sight", "sprout_bed", "kindling", "early_bloom", "early_light", "first_care", "deep_taproot", "second_thoughts", "let_go", "omen_reader", "wider_dreams"];
emitImg("icons/perk_icons.png", strip(PERK_ORDER.map(k => PERK_ICONS[k]())));
const FAMILY_ORDER = ["sporeling", "firefly_jar", "dewdrop", "pebbling", "rootling", "bellflower", "acorn", "nestling", "whirligig"];
emitImg("icons/family_icons.png", strip(FAMILY_ORDER.map(k => FAMILY_ICONS[k]())));
const CARD_ORDER = ["storm", "spores_and_reactions", "keen_edges", "tending", "overgrowth", "lone_lantern", "the_long_way", "bittersweet", "woven", "deep_poison", "kinship"];
emitImg("icons/card_bundle_icons.png", strip(CARD_ORDER.map(cardIcon)));
for (let i = 0; i < 10; i++) emitImg("memories/memory_" + String(i + 1).padStart(2, "0") + ".png", memory(i));

// Preview: the tree part-grown, with every node state on show.
const prev = new Img(GW, GH); prev.put(sky); prev.put(tree); prev.put(canopies[2]);
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
