# Upward vine swinging on Moy buildings — 18 October 2026

The camera input was wired into the shared mode for both playable characters.
The earlier feature was nevertheless incomplete for continuous building ascent:

- `_pull_for_climb()` cancelled the entire pull when its inward motion met a
  wall, even when movement upward along the wall was clear.
- Normal handovers excluded the entire held collider and required forward
  progress past the current anchor. That cannot provide a higher grip on the
  same skyscraper while the body is stopped against its facade.
- A fixed set of ray elevations could not find high anchors once the hand was
  close to the wall: those rays hit the face too low to satisfy minimum rise.

## Change

All behavior remains in `VineSwingMode` and `VineAnchorSearch`, shared by both
drivers. No character-specific climbing algorithm was added.

The pull now projects along blocking faces, retaining upward travel beside a
wall while allowing a ceiling to stop ascent. Rope shortening still follows
actual physics movement. Near the end of a climbing grip, the free hand may
catch a point at least 6 world metres higher on the same structure. Failed
searches retain the current grip and retry at most four times per second.
Ordinary level-aim handovers retain their original forward-progress rules.

Upward searches measure facade distance and add rays toward heights above its
actual face. Steeper camera pitch requests higher targets. These are raycasts
against real collision, not free-air anchors. Existing 12–52 m rope limits and
the 3 world m/s maximum reel speed remain; these lengths describe the shared
world's structures rather than an individual rig's limbs.

## Verification

`tools/validate_vine_climb.tscn` passed with zero failures in the isolated Godot
project copy. Its expanded coverage loads the saved Moy Windspire collider
without constructing all of Crossroads. Starting 35 m above the city datum,
with no pickup impulse, the human profile climbed 49.31 m and the Xiao profile
49.38 m over 1,000 physics frames, each obtaining a higher grip on that same
tower. Both remained outside its shell. The retained checks cover level aim,
the pitch dead zone, reeling speed, ceiling blocking, minimum rope length,
anchor range and retaining a grip when ordinary handover fails.

A focused targeting rerun also checks that 65-degree aim selects a higher
close-facade anchor than 20-degree aim. Power parity, pose ownership,
design-language checks and the current Moy bake check pass. These are headless
physics tests using actual saved city collision, not a rendered controller-feel
walkthrough. No commit, push or web export was performed.
