# Moy plan, iteration 3: the Crossing, the Deck's garden, the park's trees

2026-10-17. Plan-side revision made with the owner after iteration 2
(`2026-10-17-moy-plan-iteration-2.md`), plus the launch site and the
Timekeeper's arrows made the same day. It changes the **plan data**
(`tools/city_layout.py` → `scripts/city_plan.gd`), the drawings and the brief
(`city.md` 6, 6c, 6d, 6f, 7a, 7b, 8a, 12). It does not change the game: the
second prototype pass builds it (`docs/architecture/moy_prototype_pass_2.md`).

## What the owner found, and what changed

| Finding (owner) | Change |
|---|---|
| The Crossing's upper ring (the halo at +18 m) had no purpose: nothing at that level, no one waiting under it | **Removed.** The Crossing is redesigned from what people do there (`city.md` 7a). |
| The spirals ate holes through both rings; the holes were out of proportion to the 6 m ring; the spirals clipped through the lower ring | **Replaced** by four **garden towers**, one per quarter, each in the corner where a Spine platform and a high-line platform pass each other: a double helix round a steel trunk, galleries at 0 / +6.5 / +14.2 / +37, a lift on its inner corner opening onto both platforms. The ring (now 8 m wide, 24.7–32.7 m out) passes outside the towers and touches them. |
| "Column city": slender columns round the spirals, two rows of 24 round the ring, piers through the ring, all different sizes | **One structural idea:** the four towers carry both lines on head beams, the cross-bridges and the roof. The ring stands on the towers and four pairs of ordinary Deck columns. The high line's two piers at ±18 m are gone; its nearest piers stand 54 m out. Inside the ring, nothing stands under either line. |
| Glass canopies over the spirals were not integrated with the platform canopies | **One roof** at +41 m on the four towers over the high line's platforms and the towers' tops; the Spine's platforms have louvred canopies of the same material over their bridges to the towers. |
| No landings from the escalators onto the rings | Every tower has a gallery at each level it serves, with bridges to the ring, the cross-bridge, its Spine platform and its high-line platform. |
| Railings ran across junctions, on the Crossing and on the Deck | The Deck's parapets now stop wherever anything walkable meets the edge; their exact ends are in `DECK.parapets`. |
| The Deck has no columns at its corners | It had none at all: the layout tool skipped every ring-shaped run, so the whole Park Deck was unsupported. Fixed: 164 columns in `DECK.columns`. |
| Integrate green, like Singapore; make the Deck a garden walk like New York's High Line | The towers are living columns under climbers (`CROSSING.climbers`); the Deck and the ring are garden walks with alternating beds and small ghafs (`DECK.beds`, `DECK.trees`); rain gardens round the towers' feet (`CROSSING.rain_gardens`). |
| The park's "supertrees" should be real trees; landscape the park from the plant kit | The four steel wind trees are gone. 23 kit trees, each with a job (`PARK.trees`, proportions in `TREE_KIT`), plus shrubs, reeds, rocks and agave (`PARK.shrubs`, `reeds`, `rocks`, `agave`). |
| The clock's pink bands were imprecise | Each marker is now an arrow pointing at the dial; the minute ring moved outside the hour ring so its arrow touches the bezel's new minute ticks (`TIMEKEEPER`). |
| A way to the Space Kingdom | The ASAN launch complex north-east of Moy (`LAUNCH_SITE`, `city.md` 12), shown on both maps. |

The wind trees' jobs in the playground move (proposed, `city.md` 7b): the
Crossing's south-east tower and the high line's east pier become its high
swing anchors, the hoops hang between its own towers, and the cloud gap
becomes a cloud run to the south-east tower's +14.2 gallery.

## New and changed data

- `CROSSING`: `towers` (4: centre, levels, opens, lift), `tower` (trunk,
  band, gallery, drum, ribs, beam depth), `ring` (24.7, 32.7), `ring_depth`,
  `roof`, `_beams`, `_ring_supports`, `climbers`, `rain_gardens`. Gone:
  `halo`, `columns`, `spirals`.
- `ESCALATORS.helix.eye` 1.4 (was 2.0).
- `DECK.runs`: the Spine walk split into north and south; the Crossing Ring
  at r 28.7, 8 m wide; two Crossing bridges. New: `garden`, `parapets`,
  `beds`, `trees`; `columns` now include the Park Deck's.
- `CROSS` Meridian `piers` (8; −578 and −542 removed), `bearers`.
- `PARK.trees` (replaces `wind_trees`), `shrubs`, `reeds`, `rocks`, `agave`;
  `TREE_KIT`.
- `TIMEKEEPER.rings` (hour inside, minute outside), `markers` (arrows),
  `marks.minute`, `seconds`.
- `LAUNCH_SITE`.

All checked in `tools/city_layout.py`, with mutation tests run on the new
Crossing, roof, ring-span, tree and pier checks.
