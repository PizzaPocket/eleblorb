# Ocean Kingdom: The Two Pirate Ships

Status: concept brief, first planning pass, in review (2026-10-06). Read with
`ocean_kingdom.md` and the world bible's Ocean Kingdom entry.

## 1. What exists now

- The world bible describes **two** large three-masted pirate ships sailing the
  ocean continuously, with roaming crews, exterior stairs rising from swimming
  level so their decks and masts form moving parkour landmarks, oil lanterns
  lit from dusk to sunrise, and two captains: one black-bearded, one
  orange-bearded, each with a hook and a skull-marked hat.
- The code (`ocean_kingdom_denizens.gd`) builds **one** ship: an
  `AnimatableBody3D` hull 11 × 29 m with a raised helm deck aft, three masts,
  side stairs, a wheel, lanterns, and eight crew. Its captain, **Captain
  Brine**, is black-bearded and wears the bicorne (hat variant 0). The ship
  follows an elliptical route (350 × 285 m) around the kingdom's centre.
- The orange-bearded captain and the tricorn (hat variant 1) exist in the rig
  but not on a ship. The second ship is missing.

### Non-regression requirements

- Two ships, three-masted, sails set forward of their yards.
- Exterior stairs from swimming level; decks and masts as moving parkour.
- Dusk-to-sunrise lanterns; captains at their wheels with hooks and their two
  hats; cropped trousers, peg legs and stubble among the crews.
- Captain Brine's existing crew of eight: **Mara Reef**, **Old Kelp**, **Nell
  Crow**, **Tobias Wake**, **Pip Salt**, **Rook Gale** and **Ada Shoal**.

## 2. Two origins

The ships are two populations with two pasts, and they despise each other.

Both ships belong to the European tradition of piracy. Historically, most
Caribbean pirates were English, with many French buccaneers and Dutch sailors,
and their crews were thoroughly mixed: escaped enslaved Africans, Irish,
Scandinavian and Mediterranean sailors served alongside them. Spain was mainly
the target, its treasure fleets the prize. The two ships take the two biggest
strands of that history: a **British** naval privateer and a **French**
buccaneer crew. Where they sail from is not a story question; they are pirates.

### The *Harbinger*: British privateers without a navy

- **Captain Brine** (black beard, bicorne) and his crew were once British
  privateers, licensed to raid under a letter of marque. The war, and the
  licence, are long over. They kept the ship, the discipline and the uniforms,
  faded but mended.
- **Culture:** ranks, ship's bells, watches, a logbook kept daily, drills
  nobody orders any more. They call themselves privateers. Everyone else calls
  them pirates.
- **The ship:** a frigate, built for a navy. Long, low and fast; one gun deck
  with a painted band along the gunports; a raised quarterdeck and forecastle;
  a stern gallery of glazed windows lighting the captain's great cabin; a
  carved figurehead; a coppered hull. Neat, painted, coiled.
- **Hat:** the bicorne fits the later naval era the ship comes from.

### The *Belle Fortune*: French buccaneers

- **Capitaine Lucien Souci** (orange beard, tricorn; *souci* is French for
  marigold) leads a crew in the tradition of the French buccaneers of the
  Caribbean, who took a merchant ship and made it theirs. As real buccaneer
  crews were, they are mixed: French, Dutch, West African, Irish, Spanish and
  Levantine sailors.
- **Culture:** the democracy of the historical pirate "articles": the crew
  voted Souci captain and can vote him out; a quartermaster elected
  separately holds real power; shares are equal and written down. Loud,
  generous, quarrelsome, superstitious.
- **The ship:** a captured merchant galleon: broad and round-bellied, with a
  tall stepped sterncastle of several cabins, gun ports cut in later and
  unevenly, mismatched patched sails, colourful repairs, cargo lashed
  everywhere.
- **Hat:** the tricorn, of the older golden age of piracy.
- **Crew of eight:** Capitaine **Lucien Souci**; quartermaster **Bastien
  Roux**; boatswain **Yaw Mensah**; navigator **Anneke Vos**, who is Dutch;
  cook **Teo Abad**, a Spanish deserter; gunner **Bridget Nolan**, who is
  Irish; sailmaker **Sami Haddad**; and cabin hand **Moineau** ("sparrow"), the
  youngest aboard.

### Captain Brine's crew roles (proposed)

**Mara Reef**, first mate; **Old Kelp**, sailing master; **Nell Crow**,
lookout; **Tobias Wake**, carpenter; **Pip Salt**, ship's boy; **Rook Gale**,
gunner; **Ada Shoal**, surgeon.

### Between the ships, and everyone else

When the hero arrives, the Demon King's discord has set every community in
the kingdom against the others (how is still open). Restoring harmony is the
kingdom's story.

- The two ships are at open war: Brine's crew think Souci's are rabble;
  Souci's crew think Brine's are servants without a master.
- Both are barred from Kai Mālie's beach, where they once traded for water and
  food.
- The sea folk hate both and believe the ships are fouling the reef.
- Both avoid the Kraken.

## 3. Ships as architecture

Each ship is a building that moves. Their interiors should be enterable so the
crews have somewhere to live:

| Space | *Harbinger* (frigate) | *Belle Fortune* (galleon) |
|---|---|---|
| Upper deck | flush, clear, orderly | cluttered with lashed cargo |
| Aft | quarterdeck and wheel | stepped sterncastle, wheel on the top tier |
| Captain's cabin | great cabin behind the stern gallery: chart table, logbook | a cabin shared by vote for meetings and dice |
| Crew | hammocks slung in rows on the gun deck | hammocks wherever there is room |
| Galley | a proper stove forward | Teo's galley, the warmest place aboard |
| Hold | stores in order | plunder in heaps |

Movement constraints: both hulls stay `AnimatableBody3D` moving platforms;
stairs, ladders and hatches must carry a standing body; interiors need 2.0 m
headroom on decks the hero walks; the captain's cabin and galley are the
priority interiors.

## Known issue in the current crew

`ocean_kingdom_denizens.gd` never sets `is_female`, so **Mara Reef**, **Nell
Crow** and **Ada Shoal** are built with male bodies and male hair, and the
stubble rule (crew indices 2, 5 and 7) gives Ada stubble. Fix when the ships
are rebuilt: set each crew member's gender explicitly and gate beards on it
(see the `character-design` skill).

## Fixed, proposed and open

**Fixed:** two three-masted ships, their lanterns, exterior stairs and parkour,
the two captains' beards, hooks and hats; Captain Brine and his named crew.

**Proposed:** the two origins (a lost navy's privateer frigate and a captured
merchant galleon run by elected articles); ship names; Souci and his crew;
crew roles; enterable interiors.

**Settled:** the *Harbinger* is British and the *Belle Fortune* French; where
they came from is not a story question.

**Open:** whether the ships can be boarded and fought, or are only parkour and
conversation; whether either ship becomes rideable once boat riding exists;
the pirates' part in the kingdom's story.
