
// ---------- export (assets/meta/...) ----------
function strip(imgs) { const w = imgs.reduce((s, i) => s + i.w, 0), h = Math.max(...imgs.map(i => i.h)), S = new Img(w, h); let x = 0; for (const i of imgs) { S.put(i, x, 0); x += i.w; } return S; }
function stack(rows) { const w = Math.max(...rows.map(r => r.w)), h = rows.reduce((s, r) => s + r.h, 0), S = new Img(w, h); let y = 0; for (const r of rows) { S.put(r, 0, y); y += r.h; } return S; }
function emitImg(name, img) { const p = document.createElement("pre"); p.dataset.name = name; p.textContent = toCanvas(img).toDataURL("image/png").split(",")[1]; document.body.appendChild(p); }
function emitText(name, text) { const p = document.createElement("pre"); p.dataset.name = name; p.textContent = btoa(unescape(encodeURIComponent(text))); document.body.appendChild(p); }
const nodeRow = (sec, big) => strip([nodeSprite(sec, "locked", 0, big), ...[0, 1, 2, 3].map(f => nodeSprite(sec, "afford", f, big)), ...[0, 1, 2, 3].map(f => nodeSprite(sec, "open", f, big)), nodeSprite(sec, "bloom", 0, big), nodeSprite(sec, "bloom", 1, big)]);

const tree = groveTree(), sky = grovesky();
emitImg("grove/grove_sky.png", sky);
emitImg("grove/grove_tree.png", tree);
const canopies = [0, 1, 2, 3].map(groveCanopy);
canopies.forEach((c, i) => emitImg("grove/grove_canopy_" + i + ".png", c));
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
const CARD_ORDER = ["storm", "spores_and_reactions", "keen_edges", "tending", "overgrowth", "lone_lantern", "the_long_way", "bittersweet"];
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
document.body.appendChild(Object.assign(document.createElement("p"), { id: "done", textContent: "done" }));
