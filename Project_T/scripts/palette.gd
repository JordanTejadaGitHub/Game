class_name Palette
# The Heartwood 32 colours as constants for game code (art_direction.md, "the Heartwood 32 palette").
# Every colour the game draws in code (_draw shapes, lines, rings, tints, labels) is one of these,
# picked by name: `Palette.GOLD`, or `Color(Palette.WRAITHLIGHT, 0.4)` for a translucent one (alpha is
# free). Warden and dream visuals use the warm ramps; nightmare visuals only the cold ones (Ink,
# Nightmare, Stone & moon, Dew). Lighting / season tints are multipliers and may stay raw.
# The art tools use tools/art/heartwood_palette.gd (HeartwoodPalette); tests/test_palette.gd checks
# the two agree and that scripts/ and shaders/ use no colour outside the palette.

# Ink: outlines, shadows, the night sky
const VOID := Color("05050d")
const NIGHT := Color("24243c")
const DUSK := Color("3c3c5c")
const SLATE := Color("5c5a78")
# Nightmare: nightmare bodies, rims, cold glow
const DREAD := Color("140f26")
const SHADE := Color("2c2444")
const BRUISE := Color("4c3c74")
const WRAITHLIGHT := Color("9a84e8")
# Stone & moon: boulders, mist, cold highlights, eyes
const STONE := Color("8c8cac")
const MIST := Color("b4b0c8")
const MOONLIGHT := Color("dce8f4")
# Moss: ground, leaves, the canopy
const DEEPMOSS := Color("1c3c2c")
const MOSS := Color("34643c")
const LEAF := Color("5c944c")
const SPRIG := Color("9cc46c")
const NEWLEAF := Color("d4ec9c")
# Bark: trunks, roots, dead trees
const ROOT := Color("241c14")
const BARK := Color("5c3c24")
const OAK := Color("8c5c34")
const DEADWOOD := Color("bca48c")
# Path: the path; Moonpath is the palest ground
const LOAM := Color("6c5c5c")
const PATH := Color("b4a494")
const MOONPATH := Color("dccdb2")
# Warm light: attacks, the hollow, dream-fruit, fireflies
const EMBER := Color("b8662c")
const GOLD := Color("e9a83c")
const GLOW := Color("fcd47c")
const HEARTLIGHT := Color("fff4dc")
# Blossom: Sporeling and flower Wardens
const ORCHID := Color("bc44dc")
const BLOSSOM := Color("ec9cf4")
# Dew: water Wardens, jars, dew pools
const POOL := Color("2c4c5c")
const DEW := Color("4c8ca4")
const DEWLIGHT := Color("9cd4fc")
