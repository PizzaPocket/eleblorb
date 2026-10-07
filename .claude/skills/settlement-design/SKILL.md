---
name: settlement-design
description: Plan or revise an Eleblorb village, town, civic district, or inhabited kingdom as a coherent community. Use for censuses, households, governance, economy, public space, districts, circulation, utilities, hazards, landscape systems, gameplay anchors, and authored settlement layout plans. Use before architecture, interior design, landscaping, or procedural placement begins.
---

# Settlement design for Eleblorb

Settlement design is the umbrella above individual buildings. It combines
civic planning and urban design with the game's worldbuilding and gameplay
needs. It fixes the community, site, districts, routes, infrastructure, and
public realm. The `architecture`, `interior-design`, and `landscaping` skills
then develop its buildings, rooms, and grounds without moving those fixed
systems to rescue a weak plan.

## Work at four scales, in order

1. **Community:** exact named population, households, relationships,
   governance, care, education, work, exchange, hospitality, ritual, and daily
   schedules.
2. **Settlement:** terrain, districts, arrival, public heart, routes, plots,
   utilities, hazards, landscape systems, access phases, and relationship to
   the wider kingdom.
3. **Building:** programs, adjacencies, access, massing, structure, envelope,
   and services. This is where the `architecture` skill takes over.
4. **Room and ground:** interiors, planting, work evidence, light, wear, and
   small props. Use the companion skills only after the higher scales are fixed.

Residents' appearance (dress, hair, skin tone, jewellery) follows the census
through the `character-design` skill: each community gets a dress charter
beside its architecture charter.

Never solve a higher-scale problem with lower-scale decoration. A lantern does
not repair a bad route. Furniture does not repair a bad floor plan. A facade
does not give an anonymous building a purpose.

## Stage gates

### 1. Existing-state and non-regression survey

Inventory story triggers, shops, portals, inns, rest points, traversal,
collision, liquid or hazard access, protected zones, canonical engine APIs,
successful landmarks, palettes, views, and cultural texture. Record these as
explicit non-regression requirements. Redesign is not permission to erase a
quality the user likes or break a functional route.

### 2. Community brief

Use an exact named census, not a range. Group residents into households or
durable social units. Give every shared need a responsible person and place:
governance, teaching, care, maintenance, safety, hospitality, production,
storage, and exchange. Record ordinary schedules and the movement of goods.
Test that no building lacks an owner and no person must perform incompatible
work simultaneously in distant places.

### 3. Environmental and civic systems

Survey the actual terrain, height field, liquid or hazard surface, entrance,
portal, sightlines, and bounds. Map safe, hazardous, public, private, work,
service, protected, and story-gated areas. Trace people, goods, waste, water,
heat, energy, and emergency movement from source to destination. Environment is
civic structure: water lanes and swim exits matter in a floating settlement;
dry routes, lava routes, thermal ducts, and evacuation matter in a caldera.

### 4. Dimensioned civic layout

Make an adjacency matrix and route ledger before assigning coordinates. Then
author one measured plan containing:

- coordinate frame, terrain envelope, districts, landmarks, and key views;
- arrival threshold, public heart, and visitor reveal sequence;
- route graph with widths, grades, junctions, origins, and destinations;
- service and emergency routes where they differ from public movement;
- plots and structure footprints including eaves, fronts, backs, doors,
  working sides, and clearances;
- surveyed plot elevations, slope vectors, finished-floor datums, foundation or
  retaining strategy, terrain exclusions, and level route landings;
- bridges, ramps, gangways, landings, shores, hazard edges, and gathering pads;
- utilities, landscape systems, schedule anchors, protected bounds, gameplay
  anchors, and access before and after story-gated traversal powers.

Do not start with radial symmetry or a grid merely because it is easy to
generate. Fit the civic diagram to the real terrain and culture.

### 5. Style and implementation handoff

After layout approval, use `architecture` to write the style charter and each
building program and brief. Encode the approved settlement in one authored plan
data source. Generators consume it but do not invent extra structures,
rotations, paths, or residents. The plan owns residents, households, schedules,
districts, structures, routes, trade, utilities, hazards, landscape, gameplay
anchors, access phases, and non-regression requirements.

Prototype unfamiliar terrain, shell, opening, bridge, liquid-edge, or glazing
systems in isolation before populating the plan. Never mask unresolved geometry
with trim, shore bands, skirts, or props.

## Validation and audit

The settlement validator should fail overlapping footprints, blocked or
unfinished routes, wrong-facing entrances and civic objects, missing owners or
destinations, unsupported trade, inaccessible utilities or escape routes,
hazards crossing dry public circulation, props blocking movement, and visible
geometry separated from collision or liquid surfaces.

Use targeted inspection scenes or subsystem-selective capture in a scratch copy
when the editor is open. Audit arrival, public heart, public and service routes,
interiors, upper levels, hazard or water level, and night conditions. Staging
the whole world is a final integration check, not the default inspection tool.

## Lessons from the fishing village build (2026-10-07)

- **One source, checked both ways.** The layout's diagram, its route table and
  the plan data must agree. The pavilion's spur was drawn in the diagram but
  missing from the table and the data, so the built pavilion had no way in.
  The validator should fail:
  - a structure with no route to it;
  - a route that ends at nothing built;
  - a structure kind that no builder handles (the barge's gangway led to
    nothing because the builder had no case for a barge).
- **A named resident exists exactly once.** A placeholder spawned the rest
  point and its keeper on every houseboat. Spawn people and rest points from
  the census and the plan, never per structure type.
- **Survey the real ground, not the intended ground.** Section tools that
  print the actual terrain or rock (`tools/fishing_rock_section.gd`) belong in
  stage 3. The cistern had been planned where the rock face actually stood.
- **Edges and drops.** Probe every route edge against the ground beside it.
  Ohio's rim walk ran out over a 4 to 6 m drop for 17 m.
- **Water obeys physics.** A fall must leave its lip at a believable speed and
  fall along a true arc. Ohio's aqueduct threw water out at about 9 m/s to
  clear a ledge, and it now runs out on a flume to a natural fall.
- **People stand on what is built.** Residents over water or on raised decks
  need a ground probe that finds the deck beneath them. The world probe checks
  each resident is on a deck at spawn and again after walking their day.
- **Every walkthrough finding becomes a check.** Headroom, rock in a
  footprint, hull clearance and resident grounding were each found by eye, then
  added to the proof or world probe so they cannot return.
- **Look early.** Render the settlement from the air (`tools/village_aerial_capture`,
  a target per settlement) before detailing. The aerial renders showed the
  islets needed a full landscaping pass.

## Approval discipline

End every brief with:

- **Fixed:** accepted facts and non-regression requirements.
- **Proposed:** the current coherent answer, ready for revision.
- **Open:** decisions that materially alter layout, progression, population, or
  implementation.

Do not leave an accepted census labelled as vague concept work. Do not block a
layout on final shop inventory when it cannot change the required shop program.
Do not assign coordinates while the public heart, major hazard, or access
sequence remains genuinely open.
