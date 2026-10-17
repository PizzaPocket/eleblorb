# Moy playable prototype: design findings and iterations

This note records what the prototype pass found in the authored Moy plan and
what changed while turning that plan into a playable city. The implementation
uses the source dimensions and placements in `tools/city_layout.py` and its
generated `CityPlan`; it does not replace the city layout.

## What the source plan established

- Moy is a full-scale city with the recorded streets, 48 numbered buildings,
  133 Old Moy lots and 60 irregular Old Moy houses. The prototype retains those
  placements and the hotel model's public Deck connections. Detailed hotel
  interiors, apartment floors and facade-window population remain later work.
- Estate blocks are intentionally raised on open ground-floor void decks. The
  columns leave room for future public circulation and shops; they are part of
  the housing design. Generic prototype buildings use primitive massing, while
  the 60 old-house footprints keep their authored irregular shapes.
- The Deck is +6.5 m, the Spine's main section is +12 m, the Wall Line rail is
  +13.2 m, and the Meridian high line is +36 m with +37 m platforms. The
  original gate detail had placed the Spine and Wall Line at one height and
  joined them. The owner clarified that the circle and north-south services
  must stay on separate tracks.
- The park plan includes a lawn and reed pond. The Deck, the elevated stations,
  the windward direction and the open-air station cores are authored city
  features rather than new story content.

## Changes made during implementation

- **Separated the rail services.** The Spine now climbs on long approaches to a
  +20 m flyover at the North and South Gates, above the Wall Line's +13.2 m
  rail. The services do not join or share track. Station platforms follow the
  authored level at each stop. Gate posts and ramps were moved beyond both
  train envelopes.
- **Opened real train tunnels.** The Spine crossed the All-night Store and
  several lots. The first narrow, ground-level openings did not clear a full
  train, especially where the route climbed. Lots crossed by the line now have
  a continuous opening centered on the Spine, sized for the train body and the
  +20 m approach. Their outside footprints and roofs remain. Runtime car-body
  sweeps now report clear passage through the tested buildings, lots, gates and
  platforms.
- **Filled missing support runs.** Some Spine and Meridian supports started
  4 m above the datum, and Deck columns were absent from the bake. Transit and
  Deck supports now reach the ground. Crossing, Arch and West Gate ramps use
  the stored station-flight levels instead of extending to an unsupported
  +97 m.
- **Made station circulation passable.** The source supplies ramp runs and
  levels in switchback flights. The first geometry centered every return on
  one axis, stacking the crossings and blocking access to upper levels. Flights
  now alternate between lateral lanes with connecting landings; the paired
  escalators carry both human and Xiao Hou Zi. Lifts remain alongside the open
  ramp cores. The six Deck ramps also retain their distinct source positions.
- **Made train motion more legible.** Each car has its own moving physics body
  and follows the route independently, so couplings articulate through turns.
  All eight consists run on their designated double tracks, stop for four
  seconds at authored stations, and resume service. A 40-second gate simulation
  and car-envelope sweeps pass. No timetable interlock is needed between the
  independent Spine and Wall services.
- **Slowed and aligned the windmills.** All four rotors face the authored west
  wind and turn at 2 rpm instead of the original 10 rpm prototype speed. Their
  three blades remain separate moving collision bodies.
- **Made the park read as a park.** The authored lawn now uses green turf lifted
  above the paving surface to prevent z-fighting. Building palettes are
  restrained, road and ground surfaces have a small vertical separation, and
  the reed pond uses animated water over a bed rather than a solid paving top.

## Verification and limits

The generated bake has 58 packs, 23 streets, 48 numbered building records,
133 lots and all 60 old houses. `validate_city_plan.tscn` reports 0 failures;
`check_moy_bake.py`, the body-pose owner check, power parity and design-language
check pass. The Moy runtime validator reports `failures=0`, eight train
controllers, twenty independent cars, four-second station dwell, six route
classes clear of sampled train envelopes, four turbines, and human/Xiao Hou Zi
vine-suit handover passing.

The headless activation diagnostic recorded 58 pack activations over 70 frames;
the largest frame delta was 149.3 ms, with five frames above 33.3 ms and one
above 50 ms. Pack instantiation itself stayed bounded, but actor registration
and first activation still produce spikes. This is not a rendered frame-rate
measurement. The rendered performance probe did not complete in this pass, so
FPS, GPU cost and current-revision screenshots remain unverified. The required
pre-push village suite also needs the Godot editor closed; it stopped at that
guard while the editor was open. See
`2026-10-17-moy-prototype-performance.md` for the run details and repeat
commands.
