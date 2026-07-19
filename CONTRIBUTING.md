# Contributing

Issues and pull requests are welcome. Please keep the addon independent of any particular game's simulation, presentation, or bot AI.

## Development

1. Install the pinned Godot 4.7 stable build and make `godot4`, `godot`, or the macOS app available; alternatively set `GODOT_BIN`.
2. Run `./tools/verify.sh` before opening a pull request.
3. Add behavior coverage through the public addon interface.
4. Keep distributable runtime files under `addons/couch_party/`.
5. Update `CHANGELOG.md` and `addons/couch_party/VERSION` for releases.
6. Run `./tools/package.sh` and inspect the release ZIP before publishing a tag.

Code should follow the official GDScript style guide and remain warning-free under the project settings in this repository.
