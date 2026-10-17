# China garden correction — 16 October 2026

The preceding finish screenshot failed owner review. It did not establish visual
acceptance. This correction resolves the pavilion/podium interference and the
mangled, repeating paving surfaces; the garden still needs further art work.

## Reference intent

The Three.js authoring labels the pond pieces “the zigzag bridge”; the settlement
brief also calls for a zigzag bridge, rather than stepping stones. Such bridges
are appropriate to Chinese gardens: the Metropolitan Museum's *A Chinese Garden
Court* describes the low zigzag marble bridge at the Master of the Nets garden,
which slows the walk and provides changing views:
https://resources.metmuseum.org/resources/metpublications/pdf/A_Chinese_Garden_Court.pdf

That reference does not justify the game's previous proportions or clipping.

## Corrected

- Moved the royal pavilion 1.8 m east and turned its entrance toward the pond.
  Tested actual baked mesh vertices against the tower's sloping podium.
- Removed the projecting threshold. Pavilion floor, sloping approach and pond
  crossing meet continuously; piers reach the basin bed. Pavilion collision
  matches its hexagonal floor, rather than an oversized hidden square.
- Reduced repeated sawteeth to three spans. Generated one closed, bevelled
  crossing/approach mesh, shared by the runtime and Three.js reference.
- Removed repeating paving shaders. Constructed ways and aprons are united per
  island and clipped around courts, buildings and island edges; ordinary lanes
  use the shared worn-earth treatment. Corrected the paving triangle winding.
- Regenerated the static bake. The actual water, basin and swimming remain.

## Verification

The generator reports zero layout problems. Both pond-walk meshes have no
unpaired edges. Runtime validation passes podium clearance, physical footing
through crossing bends and approach, and capsule clearance into the pavilion,
plus existing water, bridge, door, instancing, streaming and state checks.
Bake signatures and runtime/model plan data agree. Design-language and JavaScript
syntax checks pass; git diff has no whitespace errors. Windowed Godot renders
were inspected overhead and at walking height. No new performance benchmark was
run for this geometry correction; previous timings are not new measurements.

Screenshots: `wip/diagnostics/2026-10-16-china-garden-correction/`.

## Still below the intended finish

The crossing is still visually heavy relative to the remaining open water.
The covered corridor roof is an unfinished flat box with square posts. The
rockery still reads as rounded stacked masses despite its real apertures;
pavilion roof and wall coping need more coherent detailing. These are remaining
art issues, not resolved by passing functional checks. The village is not given
visual sign-off by this correction.
