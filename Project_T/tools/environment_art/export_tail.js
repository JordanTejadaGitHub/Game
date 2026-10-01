
// ---------- export ----------
// Writes every environment asset as PNG data into <pre data-name> blocks for the host to save.
STYLE = STYLES[0];
SEED = 1207;
const FOLDERS = { edge: "forest_edge", deep: "deep_wood", misty: "misty_hollow", glade: "heartwood_glade" };
function strip(imgs) {
  const w = imgs.reduce((s, i) => s + i.w, 0), h = Math.max(...imgs.map(i => i.h)), S = new Img(w, h);
  let x = 0; for (const i of imgs) { S.put(i, x, 0); x += i.w; }
  return S;
}
function stack(rows) {
  const w = Math.max(...rows.map(r => r.w)), h = rows.reduce((s, r) => s + r.h, 0), S = new Img(w, h);
  let y = 0; for (const r of rows) { S.put(r, 0, y); y += r.h; }
  return S;
}
const frames = (key, n = 4) => strip(Array.from({ length: n }, (_, f) => getImg(key, f)));
function emit(name, img) {
  const pre = document.createElement("pre");
  pre.dataset.name = name;
  pre.textContent = toCanvas(img).toDataURL("image/png").split(",")[1];
  document.body.appendChild(pre);
}
for (const A of ACTS) {
  ACT = A;
  const d = FOLDERS[A.id] + "/";
  emit(d + "grass.png", strip([0, 1, 2, 3, 4, 5, 6, 7].map(v => getImg("grass:" + v))));
  emit(d + "path.png", strip(Array.from({ length: 16 }, (_, m) => getImg("path:" + m))));
  emit(d + "path_rim.png", strip(Array.from({ length: 16 }, (_, m) => getImg("pathrim:" + m))));
  emit(d + "border_wall.png", strip([getImg("wall:0"), getImg("wall:1")]));
  emit(d + "dew_pool.png", frames("pool:0"));
  emit(d + "blight_patch.png", frames("blight:0"));
  // Rows 0-2: the original Withered Tree; rows 3-8: split trunk, snag, willow, pine, birch, thorn.
  emit(d + "withered_tree.png", stack([...[0, 1, 2].map(v => frames("withered:" + v)), ...[0, 1, 2, 3, 4, 5].map(t => frames("dead:" + t))]));
  emit(d + "tended_stump.png", getImg("tended"));
  // Columns 0-1: the original boulder; 2-8: standing stone, cairn, cluster, split, lichen, ruin, crystal.
  emit(d + "mossy_boulder.png", strip([getImg("boulder:0"), getImg("boulder:1"), ...[0, 1, 2, 3, 4, 5, 6].map(t => getImg("rock:" + t))]));
  emit(d + "island_edge.png", strip(Array.from({ length: 16 }, (_, m) => getImg("isle:" + m))));
  emit(d + "cliff.png", stack([0, 1, 2, 3].map(v => strip([0, 1, 2, 3].map(cm => getImg("cliff:" + (cm + 4 * v)))))));
  if (A.id === "edge") {
    emit("dream/void_sky.png", getImg("voidsky"));
    emit("dream/void_stars.png", getImg("voidstars"));
    emit("dream/void_islets.png", strip([0, 1, 2, 3].map(v => getImg("islet:" + v))));
    emit("dream/rope_bridge.png", strip([getImg("bridge:0"), getImg("bridge:1")]));
    emit("dream/cloud_shadows.png", strip([0, 1, 2, 3, 4, 5].map(v => getImg("cloud:" + v))));
  }
  emit(d + "moved_hollow.png", getImg("dent"));
  emit(d + "waystone.png", frames("waystone"));
  emit(d + "edge_mist.png", frames("mist"));
  emit(d + "tree_round.png", getImg("tree:0"));
  emit(d + "tree_pine.png", getImg("tree:1"));
  emit(d + "tree_flowering.png", getImg("tree:2"));
  emit(d + "ground_details.png", strip([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(v => getImg("decor:" + v))));
  emit(d + "heartwood.png", stack(Array.from({ length: 21 }, (_, lost) => frames("heart:" + lost))));
}
document.body.appendChild(Object.assign(document.createElement("p"), { id: "done", textContent: "done" }));
