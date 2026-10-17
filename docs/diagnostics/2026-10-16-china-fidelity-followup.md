# China model fidelity follow-up

The previous pass corrected palace fundamentals but did not establish complete
model fidelity. The user's walkthrough identified untested inn furnishings,
arrival structures, bridge sections, garden objects and lamp positions.

Fixed inputs: the approved island/plot/route plan, the Shihu Yuan charter and
the Three.js model. No new population, story or settlement layout is proposed.

Construction brief:
- Arrival: the 12 × 10 m gatehouse is a brick lower storey with a 4 m arched
  through-passage; Lian Fu's plaster room occupies the upper storey, beneath
  a grey hard-gable roof. It is not a dwelling obstructing the public axis.
- Chain crossings: paired masonry anchorage portals stand behind the abutment
  faces. The deck and chains sag between supports, as in the model; timber
  gallery bridges instead have a shallow upward camber. All deck surfaces,
  rails, bearings and support profiles must share the same section.
- Inn: the 17 × 11 m hall faces its front court squarely. Beds and partitions
  use its finished dimensions, with a clear rear-door aisle; kitchen and
  latrine remain in their authored back-court buildings.
- Gardens: pond and pavilion positions follow their distinct model briefs.
  The pine occupies the opposite court corner, with clear space around its
  canopy. Pools have rounded stone margins, visible rippled water, lotus pads
  and a real crossing; waterfalls leave a rock lip and fall into the pool.
- Lamps: use explicit positions from the model's court, terrace and square
  arrangements, not bridge-centre extrapolation or generic path sampling.
- Ground: trodden earth uses Ohio's GroundPaint on opted-in island tops;
  constructed slab/brick/stone routes retain continuous joined ribbons and
  courts remain paved to their boundaries.

Additional user request: add a reusable, seed-driven Chinese garden pine to
NatureProps. Bent leaders, alternating lateral branches and unequal flattened
SuperEgg foliage pads provide asymmetry. Seeds must reproduce a specimen;
trunks, branches and broad foliage landing surfaces retain collision.

Open: a complete interactive story walkthrough remains outside the automated
proof. Visual and physical verification results are recorded below.

## Implementation and review

The reusable tree is documented in `docs/architecture/chinese_garden_pine.md`.
`tools/chinese_pine_gallery.tscn` provides an isolated four-specimen render.

The gatekeeper's west masonry pier now contains a real ramp into his upper
room, with a corresponding floor opening. The four-metre public arch is built
as a separate masonry barrel; generic dwelling door frames are omitted. The
palace gate pavilion also has an open four-metre bay rather than dwelling doors.

Chain bridge bearing tails are surveyed from the real island polygons, with
body clearance, rather than inferred from half the difference between bridge
length and clear span. Decks, rails and physics use the same profile. The
parapet generator now removes the full bridge corridor as well as the inland
apron; its earlier apron-only cut left a guard crossing the entry deck.

Four illustrative post positions conflicted with the surveyed paths. Their
original coordinates are retained as `reference_at`; the nearest clear positions
in the same courts are now the shared model/runtime `LANTERNS` data. All other
post positions remain at their model coordinates. Eave lanterns are a separate
placement type. No lamp is inferred by extending a bridge centreline.

The inn uses its 17 × 11 m finished hall dimensions for furniture and partitions,
and faces the court squarely. The authored rear kitchen/latrine replace the
unrelated generic lodge service-room fittings. GroundPaint handles earth ways
and slab-road shoulders; constructed route ribbons share vertices through bends.
The two pond courts have distinct layouts. Following the user's explicit
correction, they are real water basins: cut openings in both island collision
and court paving, a physical bed 2.2 m below the water at its deepest, and a
submerged west exit ramp. Position-aware water surface/bed queries feed the
existing LiquidEnvironment, swimming, diving and underwater-camera systems.
Human and monkey drivers and free/controlled blorbs use the same water queries.
The visible surface uses the shared village water shader. Shelving stone edges,
lotus planting clear of the crossing, a rockery waterfall and a physical
pavilion threshold ramp complete the construction.

## Verification results

- Generated plan: 54 items, 8 islands, 38 openings, 65 paths, 27 parapet runs,
  zero geometric problems. The guard-run count changed because bridge corridors
  are now cut completely rather than leaving obstructing fragments.
- China runtime proof: pass. Added checks cover bed extents/support, square inn
  orientation, the arrival arch, four chain anchorage portals, bridge surface
  profiles and aisle clearance, pond/pavilion/pine separation, explicit lamp
  coordinates, GroundPaint presence and seeded pine variation/collision.
- Real-water proof: both basins have the expected physical bed and no residual
  island/paving collider over their water. Shared liquid classification/depth,
  human swimming, controlled monkey swimming, controlled-blorb flotation,
  underwater-camera entry/exit and the west escape slopes pass.
- Previous door, ramp, mount wall-blocking, cache-release, recruited-companion,
  civic-state reload and threaded-region activation checks continue to pass.
- Ohio: 0 failures, 8 existing warnings. Snow: 0 failures, 5 existing warnings.
  Player support handoff: 0 failures. Pose ownership, power parity and design
  language checks pass; the existing FlightMode duplication notice remains.
- The Three.js inline script passes JavaScript syntax checking. The generated
  scene's source signature and model/runtime plan, bridge, guard, apron and lamp
  data agree. Web export was not run.

Fixed-camera Metal Forward+ QA measurement on the development machine: about
2.5 seconds to build, 60 FPS, 3,281 draw calls, 316 MiB static memory and 657 MiB
reported video memory. The compressed scene is about 53 MiB. Pine limbs use
8 × 12 and foliage lobes 8 × 16 samples; this retains their silhouettes without
adding the cost of full figure-mesh tessellation to every tree.

Final review images and logs are in
`wip/diagnostics/2026-10-16-china-fidelity/`, including a view from inside the
real pond basin, the entry arch, chain crossing, timber bridge bearings, inn
rear elevation and four pine variants. The headless macOS certificate-store
message and standalone-probe ObjectDB exit warnings remain in their logs.

A complete human walkthrough and the outstanding interior/story dressing
remain open. This pass does not assign a percentage of model fidelity or
certify every room and story sequence. The first-approach activation hitch
recorded in the previous diagnostic also remains a separate streaming task.
