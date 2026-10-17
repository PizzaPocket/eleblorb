# China Village visual audit — 2026-10-16

## Verdict and scope

The settlement does not yet meet the game's visual standard. It is an intermediate architectural implementation with useful functional repairs, not a finished environment. Passing collision, layout and performance checks does not constitute visual approval.

This audit reviews the saved `wip/diagnostics/2026-10-16-china-fidelity/` captures against the current builders, the architecture skill's section 1a, the village brief and the Three.js reference source. The older `china_kitchen_descent.png` in the remediation folder supplements the service-level assessment; it is not a fresh capture. No new live walkthrough or implementation changes were made for this audit. This is a targeted visual assessment, not an exhaustive room-by-room certification.

## Findings

| Priority | Finding | Required improvement |
| --- | --- | --- |
| High | Exposed construction still reads as boxes and slabs. The gatehouse has huge blank masonry piers, sharp outer corners and an unarticulated plaster side. Court edges, raised earth banks and retaining faces retain raw rectangular silhouettes. | Keep necessary planar infill, but resolve visible corners, wall ends, copings, plinths and transitions with deliberate SuperEgg profiles, caps and shared joins. Do not merely add a tiny bevel everywhere. |
| High | Roof silhouettes remain crude: broad straight planes with little eave sweep or convincing layered construction. Adding a ridge and a few brackets has not supplied the architectural character in the brief. | Establish a reusable roof section with controlled sweep, a finished fascia/soffit, coherent corner transitions and readable bracket support. Preserve roof rank and local distinctions. |
| High | Paving is visually noisy and insufficiently differentiated. The pond court's tiny repeated pattern resembles a stamped grid. The shader's palace pattern uses square cells, although the brief specifies herringbone. | Implement the actual specified bond/mosaic, use appropriate world scale, restrained joint contrast and borders at gates and walls. Evaluate at player eye level and in motion for shimmer. |
| High | The garden has the right inventory but poor composition and object quality. Pond stones repeat around a perfect oval; the crossing is visibly overlapping paddles; the rockery is stacked cushions; lotus pads read as small rectangles. The giant blank palace retaining face overwhelms it. | Compose shore, rockery, crossing, pavilion and planting together. Give the bridge one joined structure, rocks distinct silhouettes and cavities, and the shore an authored shelving profile. Treat the palace retaining section as part of the garden's architecture. |
| High | Real water exists, but the pond still reads as a flat blue patch in the saved overview. | Tune the existing water for pond scale: visible depth/shallow margins, restrained ripples and believable contact with the shoreline. Preserve the actual basin and shared swimming behavior. |
| Medium | Bridge supports now exist, but the covered bridge uses overlapping rounded beam ends with weak joinery. The chain bridge reads more like a suspended walkway with thin handrails than a substantial chain structure. | Resolve bearings, beam seats, end caps and chain-to-anchorage connections. Make the load path readable from above and below while keeping the correct sag/camber for each bridge type. |
| Medium | The service descent works as circulation but reads as an assembly of ramps, walls and rails. The change in level has not been convincingly integrated with the palace podium. | Reconcile the complete section—palace floor, kitchen threshold, landing widths, retaining wall and drainage—before refining its appearance. A traversable slope alone does not validate the architectural decision. |
| Medium | Pine seeds vary, and the silhouette direction is promising, but foliage pads remain regularly staged and similarly swollen. Trunk segments and branch joints are conspicuous. | Improve taper, continuous branch junctions, uneven canopy spacing, negative space and distinct specimen habits. Preserve deterministic variation and the game's soft forms. |
| Medium | Interiors remain generic and sparse. The inn beds are contained now, but the room shown is a bare room with generic furniture and little settlement-specific character. | Design one complete representative room, including lighting, joinery, bedding, storage and purposeful daily-life objects, then reuse that quality level. |

## What is worth keeping

The island-and-bridge composition, palace hierarchy, court sequence and relationship of public and service routes provide a useful planning foundation. Gold roofs against quieter village roofs communicate rank. The open hexagonal pavilion, lattice openings, red columns, terrace balustrades and asymmetric pine concept are appropriate directions.

The genuine wall apertures and gate passage, physically supported furniture, actual pond basins and shared liquid behavior are valuable repairs. Their presence does not settle their proportions, finish or visual fidelity.

## Why the reference translates poorly

The implementation shares placement data but does not faithfully reproduce all of the reference's geometry, materials and detailing. A footprint match cannot guarantee a roof profile, a mosaic, a garden composition or a well-resolved architectural joint. The current builders substitute general-purpose primitives for several of those decisions. Applying a rounded primitive independently also leaves visibly overlapping or poorly joined members.

There is contradictory guidance in `docs/architecture/chinese_village.md`: the earlier runtime-correction notes endorse square-edged platforms, and the section 5 assessment explicitly discourages rounding tiers and slabs. The architecture skill instead requires resolved exposed edges and joins. The owner's latest instruction governs: necessary flat infill is acceptable, but exposed raw slab edges require an intentional architectural treatment. These notes should be reconciled during implementation.

## Recommended next pass and acceptance

1. Complete one representative gate/bridge/wall junction and one garden corner to the required finish before propagating changes across the village. Compare identical viewpoints with the reference and inspect both at player scale.
2. Repair shared construction details: roof profiles, aperture reveals, corner posts, wall-end caps, coping, plinths and joined bridge sections. Use genuine Boolean cuts where a hole or clipped junction requires them; inspect both faces and the underside. Do not substitute decorative frames for real openings.
3. Correct paving scale and specified patterns, then resolve earth-to-paving transitions and raised bank edges.
4. Finish the garden and service-level section, followed by interior character and vegetation refinement.

Acceptance requires clear silhouettes, no unexplained cut slab ends, no visible gaps/double thickness at joined members, coherent supports and foundations, quiet patterns at gameplay distance, and faithful reference composition. Visual review must accompany collision and performance validation. Adding more ornament or objects before these repairs will compound the inconsistency.
