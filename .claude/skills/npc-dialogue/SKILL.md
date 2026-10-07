---
name: npc-dialogue
description: Writing or reviewing what Eleblorb's NPCs say (talk_lines, vendor_lines, keeper lines, schedules' remarks). Use whenever a resident gets lines, a settlement is populated, or dialogue reads like a character sheet. People talk in the moment; who they are shows through what they say, never by announcing it.
---

# NPC dialogue: people in the middle of their day

A visitor walks up to someone in a village. That person is busy with
something, thinking about something, and has a way of talking. Their line is
what they would actually say right then. It is never a recital of their
character brief.

Companion skills: `character-design` (who they are and how they look),
`settlement-design` (their household, work and day). Read the resident's
brief first, then put it away: the brief tells you what they might talk
about, not what they say.

## The rule

**Never** have an NPC:

- introduce themselves ("I'm Mateo, the boatwright");
- state their job or role ("I keep the records", "Mornings are lessons,
  afternoons are the clinic");
- explain their relationships ("Rian seals the helmets and I build them",
  "my sister's patients");
- deliver their backstory ("I captained boats for forty years");
- explain a mechanic, a price, a requirement or the next step (CLAUDE.md, "In-game
  text and player guidance");
- end on an aphorism ("A net remembers every snag", "Stone tells you where the
  water has been").

All of that is still true, and it should be *inferable*: the boatwright
complains that a pile is creaking; the doctor tells you to keep a cut dry;
the old captain reads the clouds out loud.

## What people do say

Draw each line from one of these, and mix them across a resident's lines:

- **The thing in their hands**: "Hand me that... no, the other one."
- **What they notice right now**: the weather, a sound, a smell, a bird, the
  water, the visitor's wet clothes.
- **A small complaint or worry**: sawdust in the tea, a late ferry, a hole in
  the net.
- **A question for the visitor**: "Swimmer or ferry?" "Have you eaten?"
- **Gossip, lightly**: one neighbour mentioned in passing, the way people
  talk about the people they live with. Not a family tree.
- **An offer or a brush-off**: "Try this." "Not now, the fire's at the
  wrong point."
- **A quirk**: the heron one boy calls the inspector; the beetle a child
  named.

## Voice

- Each resident sounds like one person: a child talks in bursts and
  exaggerates, an elder is dry and unhurried, a busy adult is short.
- Short. One or two sentences; most under fifteen words. People passing on a
  jetty do not make speeches.
- Plain words, contractions, the occasional unfinished thought or ellipsis
  for an interruption.
- Mention a neighbour by name sometimes, and the visitor's situation often.
- Two or three lines per resident, each from a different kind above.
- Lines may change with the time of day or story state (settlement backlog,
  item 13), but each must still work on its own.

## Checks before committing lines

1. Cover the speaker's name. Could you still tell which of the village's
   residents said it? If not, it is generic.
2. Read it aloud to a stranger on a jetty. Would a real person say it?
3. Does it contain "I am", "my job", "I'm the", a relationship stated as a
   fact, or a number of years of service? Rewrite it.
4. Does it tell the player how something works or what to do? Rewrite it.
5. Run the `no-ai-slop` skill over the set: no binary contrasts, no
   fake-profound kicker, no em-dash rhythm.
