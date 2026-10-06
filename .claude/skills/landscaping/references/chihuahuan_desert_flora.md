# Chihuahuan Desert flora for the Rock and Ground Kingdom

A sparse palette for a dirt-and-rock biome with a movie-Western feel, after the
Chihuahuan Desert of West Texas. Used by `docs/architecture/rock_ground_town.md`.
The kingdom stays almost bare: plants are rare punctuation, never cover.

## Status

- **Native:** grows wild in the Chihuahuan Desert.
- **Introduced, kept on purpose:** the tumbleweed (Russian thistle, *Salsola*)
  came from Eurasia and is an invasive weed in the real Southwest. It is kept
  only because the user asked for the classic Western image. It is the one
  recorded exception to the rule against invasive species.
- **Excluded:** saguaro (it grows only in the Sonoran Desert of Arizona, so it
  would be the wrong desert); Joshua trees (Mojave); palms; lawns; flower beds.

## Zones

| Zone | Conditions | Plants |
|---|---|---|
| Dirt flats (Ground half) | open, dry, hard-packed | creosote bushes spaced far apart, a few prickly pear clumps, tumbleweeds |
| Rocky slopes and ledges (Rock half) | thin soil in cracks | lechuguilla and sotol rosettes, prickly pear, an occasional cholla |
| Washes and canyon floors | brief water after storms | a few mesquite, desert willow, scattered grasses |
| Town | trampled and swept | almost nothing: a prickly pear by a step, a barrel cactus in a half-barrel, one shade mesquite at the corral |

## Palette

| Common / botanical | Status | Form for SuperEgg builds | Job |
|---|---|---|---|
| Prickly pear, *Opuntia* | native | low clumps of flat oval pads (squashed SuperEggs), yellow flowers or red fruit on the rims | the classic cactus; low accents on flats and slopes |
| Cholla, *Cylindropuntia* | native | a branching shrub of jointed cylindrical stems, pale spines catching the light | rare silhouettes on slopes |
| Barrel cactus, *Ferocactus* | native | a ribbed squat globe with a crown of flowers | town planter; rocky ground |
| Lechuguilla, *Agave lechuguilla* | native | a low rosette of stiff upright blades | rocky slopes |
| Sotol, *Dasylirion* | native | a spherical rosette of thin blades with one tall flower stalk | ledges, skyline accents |
| Creosote bush, *Larrea tridentata* | native | an open, airy shrub of slender stems and small dark leaves, about 1 to 1.5 m | the dominant shrub of the flats, evenly and widely spaced, as it grows in life |
| Honey mesquite, *Prosopis glandulosa* | native | a low, spreading, thorny tree with feathery leaves | washes; the one shade tree at the corral |
| Desert willow, *Chilopsis linearis* | native | a slender small tree with willowy leaves and pink trumpet flowers | canyon floors after rain |
| Tumbleweed, Russian thistle, *Salsola* | introduced (kept on purpose) | a loose round ball of thin stems; loose ones roll and bounce with the wind | blowing down the main street and across the flats |

## Rules

- Plants are rare: well under one per 100 m² on the flats, fewer in town.
- Creosote spaces itself evenly, with bare ground between bushes. Never cluster
  it.
- Cacti and rosettes are solid and hurt to stand in; collide as blocking.
  Creosote and mesquite foliage is decorative, with solid trunks.
- Tumbleweeds are light, moving props: wind-driven, decorative to collision,
  respawning upwind.
