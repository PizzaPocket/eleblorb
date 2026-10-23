# P11 architectural revision — 2026-10-23

**Design review, not build acceptance.** The user rejected the first model's
architecture and the claim that P11 was ready. Roadmap, package brief and
handoff now explicitly withdraw that claim; no P11 build prompt is active.

## Architectural work

The active `moy_p11_architectural_study.md` defines people/use, a proposed
railway-wall charter, coordinated base/vault/bearing/upper-field/cap elevation,
three bay uses, landscape/thresholds, complete bastion ramp/terrace and a proposed
supported shade canopy. The charter is draft, not silently approved.

Same model file, rebuilt as a focused27m three-bay study plus one20×10m
bastion. It straightens a representative detail; it does not move live arch
or post sites. Detailed masonry rings/jambs, plinths, flat-ended pier profiles,
recessed ceramic panels, coping, real vault depth, boarded seats, framed
maintenance closure and planted path now share one architectural vocabulary.
The bastion repeats its base/pier/panel/crown, with a notched ramp, guards,
outer planting, timber seat and actual canopy posts/bases/cantilever beams.

Ground and roof plans, city/desert elevations, wall/bastion sections and
approach/niche/promenade/terrace/night views coordinate the proposal. Viewer
annotations are not printed game text. The exported game hero supplies scale.
Plant geometry has curved tapered blades/rosettes and supported niche climbers;
it replaces uniform stick rows. Rendered shadows and proper colour handling
make recess/bearing/material differences legible rather than uniformly pale.
Static preview meshes merge by material; dynamic lamp and hero stay separate.

WALL.kit.study contains37 part families/9 joins, palette, explicit datums,
path/bed/apron polygons and187 seeded plants. Old39-part draft is withdrawn;
this is a representative design reference, not a complete rollout schedule.
New canopy top17.05/underside16.7 is proposed only, with2.7m terrace headroom.
The14m bastion structural terrace and existing footprint remain unchanged.

## Review findings and corrections

First rendering was overexposed and flattened the intended stone/masonry/
ceramic palette. Corrected material colour-space conversion/exposure. Tall
pier faces initially retained rounded end taper; changed to constant-section
profiles with flat bearing ends. Improved niche/terrace eye cameras so the
seating space and shelter can actually be read. Adjusted canopy beam to top16.9,
matching blade underside16.9/top17.05 instead of intersecting the blade field.
Adjusted the thin ramp walking tops to12/13/14 instead of treating the slab
centre as the route datum, and made ground path/aprons meet vault floors at0.

The High Line reference is expressed through the connected path/bed geometry
and occupation, not a claim that a narrow six-metre desert circuit duplicates
New York's dimensions/ecology. No new tree sites, people, businesses, in-game
messages, runtime mechanics or construction of the game wall.

## Verification and boundaries

- Canonical plan generation passes; representative schedule/parts validation
  passes. Compared JSON to81fa2ae: only WALL.kit study/status metadata added;
  all existing sites, services, previous kits and source dimensions retained.
- Ten drawing DATA blocks synchronized; existing P7 canonical scene parity
  verified unchanged. Existing figure block preserved unmodified.
- Browser syntax/load checks and desktop/390px phone layout pass. Captures
  cover approach, niche, city/desert elevations, ground/roof plans, upper
  promenade, bastion/terrace, section and night plus four coordinated diagrams.
  Inspected architectural/material/landscape and route views, not just files.
- Genuine headless Godot4.7.2 planning bake performed at248 packs. Study
  metadata is not consumed by current runtime geometry; canonical scenes
  retained after generated ID/name/float-only churn, real manifest retained.
  Bake freshness and city-plan validator pass; no actual local city build
  was replaced. Known dummy-renderer shutdown warnings remain.
- Required pre-push checks run at publication; no runtime P11 pass claimed.

Remaining design work: assess the tall upper field and its repetition at city
scale, the proposed open-bladed sunshade, and refine this architectural
language, then gate-specific architectural adaptation, actual circular
placement/terrain/rail/station coordination, continuous circuit and full
production schedule. Canopy is unapproved for repetition at seven posts.
Production collision/plant/support/weathering details remain build work after
design acceptance. Sections include explanatory diagrams; they are not proof
of a watertight production solid or complete gameplay route validation.

Current references: `docs/drawings/references/moy_wall_study_*.png`.
Older wall images without `study` are historical withdrawn proposals, not
alternative implementation instructions. External hosting remains pending.
