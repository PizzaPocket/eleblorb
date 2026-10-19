> Historical revision-1 evidence. Superseded by `2026-10-19-moy-P6-planning-r2.md`;
> do not use the 23-independent-tower schedule for a new build.

# P6 planning verification — 2026-10-19

**Ready brief and planning model; runtime P6 implementation has not started.**
This is planning evidence, not the implementation diagnostic required by P6.

- `CityPlan.DOWNTOWN`: 23 mid-rise owners (110–132), towers 12/14/15,
  42 part templates and 14 joins. Existing court-8 passage belongs to lot119.
- Plan generator passes. Existing exported plan JSON compared with the
  committed pre-P6 city-model data: identical after removing only `downtown`.
  Streets, footprints, heights, routes, P5 and P17 data are unchanged.
- Sampled geometry checks pass: capsule bounds and vertical levels, south
  profile validity/containment, stepped terraces and clearance after guards.
  Minimum south clearance is 1.5201 m. Rotor/core separation and public stop
  list checks pass. Capsule faces alternate by level to avoid corner overlap;
  sockets seat at tangential ±2.5 m inside the continuous core.
- P6 browser model: Chromium/software WebGL, zero page errors; overview,
  three tower views, street, sky garden, wind gap, member/hero section and
  dusk captured. Structural members use capped constant-section profiles;
  free shells use the game's exponent convention with exact-axis handling.
  Production must use shared game builders, not preview mesh tessellation.
- Existing city, plan, hotel, BLOCK and P5 pages re-embedded and load-checked
  in Chromium: zero page errors. Data only; their established camera/render
  code was preserved. Local browser verification served CDN script copies
  fetched over verified HTTPS using their declared Three.js versions.
- Quick checks: body-pose ownership, 11-power/3-character parity and design
  language pass. City validator: 22 streets, 47 buildings, 133 lots, 0 FAIL.
- Headless authoring bake exits 0; freshness checker passes for 246 packs.
  Existing dummy-renderer RID/dependency warnings remain at bake shutdown.
  The runtime builder does not consume DOWNTOWN yet. Preserved canonical
  runtime scene packs after regeneration (node/resource ID churn), keeping
  the generated source hashes in the manifest. No P6 runtime geometry shipped.

Reference images:

- [District overview](../drawings/references/moy_downtown_overview.png)
- [Windspire](../drawings/references/moy_downtown_wind.png)
- [North tower](../drawings/references/moy_downtown_north.png)
- [South tower](../drawings/references/moy_downtown_south.png)
- [Members and exported hero](../drawings/references/moy_downtown_parts.png)

Not verified here: game collision for the new kit, live lift operation,
actual two-rig routes, runtime P6 winding, matched P0 before/after audits,
P6 performance or unload/re-entry. Those remain binding implementation
acceptance requirements. Existing P3/P4 winding and completeness findings
are unchanged by this planning work.

External artifact publication is pending: no artifact publisher is available
in this chat. The checked-in model and images are available to the build chat.
