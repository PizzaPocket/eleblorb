# Package P6: Downtown's podiums and three tower exteriors

2026-10-19. **Next: scope and design direction recorded; not ready for build.**
Read `moy_build_roadmap.md` first. Complete the checked parts/joins schedule
and package model before changing this brief to ready.

- **Area:** downtown's generated `midrise` lots and the sites of numbered
  buildings 12 (Windspire), 14 (north tower) and 15 (south tower).
- **Target:** L2, recognizable architecture with usable public routes.
- **Binding layout:** existing lots, streets, heights, `TOWER_SITE`, Deck
  levels and `COURT_WAYS`. No changes to the locked city layout.
- **Build order:** after the earlier district work; shared builder changes
  must be integrated sequentially with P3/P4 fixes and P5.
- **Exclude:** BLOCK's tower and story (P17); the Grand Hotel; new office
  and flat interiors; new NPCs, dialogue or resident schedules.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, the roadmap and architecture skill.
2. `city.md`: Downtown in section 7; section 7c's Windspire, north and south
   tower descriptions; section 6's Deck and vertical circulation.
3. `tools/city_layout.py`: `lots`, `STOREY`, `HEIGHTS`, `CROWNS`, `FORMS`,
   `TOWER_SITE`, `DECK`, `COURT_WAYS` and BLOCK's neighbouring approach lot.
4. `scripts/moy_city_bake_builder.gd`, existing shared SuperEgg builders,
   collision policy, streaming and lift implementations.
5. P3/P4 first-build reviews, especially P4's winding item 0. Their proxy
   geometry is not an accepted example of a completed architectural kit.

## 2. Design direction

Preserve the three established silhouettes. Give the surrounding fabric a
coherent shaded street frontage and a readable base, shaft and roof, rather
than window grids pasted onto generic boxes. This is the city's workplace:
shops and public circulation below, offices or private flats above.

### Mid-rise podium kit

Use the existing 18–34-storey lots and 3.6 m storey rhythm. Fit a repeated
structural bay to each frontage, with recessed openings, pale ceramic piers,
deep shading and a clear podium cornice. The public Deck remains at +6.5 m.
Do not force every lot to connect to it; connect only where the plan does.
Vary bay grouping, setbacks within the original envelope and pictorial
entrance identities. Colours should support the tower hierarchy and street
wayfinding. No letters, words or numerals appear on buildings or paving.

### Windspire — building 12

Keep the 28 m shaft in its recorded garden site, the rounded triangular
quarter-turn, three genuine west–east wind gaps, continuous core and three
mega-columns with transfer bands. Pale glass and terracotta fins belong to
this tower. Main shaft top +262 m; crown top +280 m. The wind garden,
hotel-side lobby hall and +6.5 m connection retain their recorded bounds.
The gaps must read as openings supported by structure, not sliced masses
balanced on thin poles. The observation-deck route needs an explicit scope
and lift-stop decision in the completed brief; do not infer it from a facade.

### North tower — building 14

Keep the +175 m capsule silhouette, open ground beneath capsules beginning
at the third floor, and the two-storey middle sky garden. Rounded ceramic
office capsules attach visibly to a continuous core; ledge tops are physical.
Use controlled colour families and capsule sizes, not arbitrary scattered
boxes. Preserve the makers' yard and workshop/cafe shell boundaries. Theo's
office furnishing and daily behaviour are outside P6.

### South tower — building 15

Keep the +150 m dune silhouette, two-storey open colonnade, shaded recessed
windows and smoothly varying balcony edges inside the shaft envelope.
Pale sand ceramic, planted recesses and screens distinguish it from the
north tower. Preserve the residents' garden and pergola site. Private flats,
the nursery and Tanglewire remain closed shells unless separately briefed.

## 3. Required planning deliverables before build

- Exact owner list for every generated mid-rise lot, including the BLOCK
  approach neighbour; public routes and passage cuts indexed to those owners.
- Checked plan-data parts and joins schedule covering podiums, facade bays,
  roofs, all three tower systems and substantial site elements. Record each
  part's shape, half-sizes, exponents, collision and repetition rules; each
  join's cutting or bearing planes. Use shared SuperEgg conventions, structural
  exponent 5.5, planar caps and coordinated opening cutters. No pointed
  stretched approximations, unsupported seams or facade overlay substitutes.
- Explicit height tables for wind gaps, garden levels, capsules, balconies,
  public landings and any realised lift stops. Resolve approximate prose
  against checked dimensions rather than inventing floors during the build.
- A P6 model drawn from those numbers: three towers among neighbouring mass,
  street and Deck views, podium section, isolated members/joins beside the
  exported game hero, day and dusk views. Add model index and publication
  status honestly; a local model is not a published phone-accessible preview.
- Final collision, route, viewpoint and diagnostic acceptance sections.

## 4. Acceptance requirements to retain in the final brief

Substantial visible structure has collision. Public openings cut both render
and collision meshes; private volumes stay sealed. Do not fill passages with
plinths, railings or whole-building colliders. Ground, slabs and roof landings
have one surface owner and meet at the scheduled planes.

Check clockwise and counterclockwise input rings, including concave cases.
Verify upward-facing roof/floor triangles and outward wall faces with default
back-face culling, and prove top support with the actual controller. Flipped
normals and double-sided materials do not repair reversed winding.

The build diagnostic must account for every scheduled part and join, show
usable entrances and street-to-Deck routes for the hero and Xiao Hou Zi,
compare identical P0 audit bounds/settings before and after, and report
unload settlement and performance on matched routes. Whole-city optimization
remains deferred to P16; correctness and unexplained new regressions do not.

## Decisions log

- 2026-10-19: user moved planning on to P6 after P5's colour/model pass.
  Retain existing tower concepts; complete the schedule and visual design
  before giving Luna a build prompt. No runtime implementation in this pass.
