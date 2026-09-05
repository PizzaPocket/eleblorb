# Eleblorb

Eleblorb is a Godot 4.7 game about exploring the world with a party of Blorbs.

## Run locally

Open `project.godot` in Godot 4.7 and run the project.

## Web export

Run:

```sh
python3 tools/export_web.py
```

This creates the deployable static game in `build/web` and applies Eleblorb's
single continuous loading screen across download, engine startup, and world
construction.

For Vercel, use `build/web` as the Output Directory. No framework build command
is required when the committed web export is current. The repository's
`vercel.json` supplies that setting automatically.

Before pushing, verify that the committed deployment matches the game source:

```sh
python3 tools/check_web_build.py
```

The versioned pre-push hook and GitHub Actions run the same check. Enable the
hook in a fresh clone with:

```sh
git config core.hooksPath .githooks
```
