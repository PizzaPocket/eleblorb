# Eleblorbs

Eleblorbs is a Godot 4.7 game about exploring the world with a party of Blorbs.

## Run locally

Open `project.godot` in Godot 4.7 and run the project.

## Web export (deprecated for now)

The web build is paused. Pushes do not regenerate `build/web` and do not deploy
to Vercel (`vercel.json` disables Git deployments, and the web-build workflow is
removed). `build/web` is a stale snapshot. To bring it back, see the "Publishing
contract" in `AGENTS.md`. The export and check scripts are still in `tools/`.

## Hooks

Enable the versioned pre-push hook in a fresh clone with:

```sh
git config core.hooksPath .githooks
```

It runs the pose-owner and power-parity checks and the Ohio and Snow village
validators (close the Godot editor first).

## Skills and documents

Project skills are in `.claude/skills` and the settlement, architecture and
handoff documents are in `docs/`, so work can continue from a clone.
